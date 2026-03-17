use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    response::{IntoResponse, Response},
    routing::{get, post},
    Json, Router,
};
use chrono::Utc;
use jsonwebtoken::{decode, decode_header, Algorithm, DecodingKey, Validation};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use sqlx::{sqlite::{SqliteConnectOptions, SqlitePoolOptions}, Row, SqlitePool};
use std::{collections::HashMap, env};
use tokio::net::TcpListener;

#[derive(Clone)]
struct AppState {
    db: SqlitePool,
    http_client: Client,
    firebase_project_id: String,
    firebase_issuer: String,
}

#[derive(Debug, Deserialize)]
struct AllocateMemberNumberRequest {
    user_id: String,
    gym_id: String,
    role: String,
    idempotency_key: Option<String>,
}

#[derive(Debug, Serialize)]
struct AllocateMemberNumberResponse {
    member_number: String,
    sequence: i64,
    gym_id: String,
    format: String,
    allocated_at: String,
    requested_by: String,
}

#[derive(Debug, Serialize)]
struct HealthResponse {
    status: &'static str,
    service: &'static str,
}

#[derive(Debug, Serialize)]
struct ErrorResponse {
    code: String,
    message: String,
}

#[derive(Debug)]
struct ApiError {
    status: StatusCode,
    code: String,
    message: String,
}

#[derive(Debug, Clone, Deserialize)]
struct FirebaseClaims {
    aud: String,
    iss: String,
    sub: String,
    user_id: Option<String>,
    exp: usize,
    iat: usize,
}

impl ApiError {
    fn unauthorized(message: impl Into<String>) -> Self {
        Self {
            status: StatusCode::UNAUTHORIZED,
            code: "UNAUTHORIZED".to_string(),
            message: message.into(),
        }
    }

    fn validation(message: impl Into<String>) -> Self {
        Self {
            status: StatusCode::BAD_REQUEST,
            code: "VALIDATION_ERROR".to_string(),
            message: message.into(),
        }
    }

    fn conflict(message: impl Into<String>) -> Self {
        Self {
            status: StatusCode::CONFLICT,
            code: "CONFLICT".to_string(),
            message: message.into(),
        }
    }

    fn server(message: impl Into<String>) -> Self {
        Self {
            status: StatusCode::INTERNAL_SERVER_ERROR,
            code: "INTERNAL_ERROR".to_string(),
            message: message.into(),
        }
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        (
            self.status,
            Json(ErrorResponse {
                code: self.code,
                message: self.message,
            }),
        )
            .into_response()
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let bind = env::var("MEMBER_NUMBER_SERVICE_BIND").unwrap_or_else(|_| "0.0.0.0:8088".to_string());
    let db_url = env::var("MEMBER_NUMBER_DATABASE_URL")
        .unwrap_or_else(|_| "sqlite://member_numbers.db".to_string());
    let firebase_project_id = env::var("FIREBASE_PROJECT_ID")?;
    let firebase_issuer = format!("https://securetoken.google.com/{firebase_project_id}");

    let db_options = db_url
        .parse::<SqliteConnectOptions>()?
        .create_if_missing(true);

    let db = SqlitePoolOptions::new()
        .max_connections(5)
        .connect_with(db_options)
        .await?;

    initialize_schema(&db).await?;

    let state = AppState {
        db,
        http_client: Client::new(),
        firebase_project_id,
        firebase_issuer,
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/internal/member-numbers/allocate", post(allocate_member_number))
        .with_state(state);

    let listener = TcpListener::bind(&bind).await?;
    axum::serve(listener, app).await?;
    Ok(())
}

async fn initialize_schema(db: &SqlitePool) -> Result<(), sqlx::Error> {
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS member_number_sequences (
            gym_id TEXT PRIMARY KEY,
            last_sequence INTEGER NOT NULL,
            updated_at TEXT NOT NULL
        )
        "#,
    )
    .execute(db)
    .await?;

    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS member_number_allocations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            gym_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            role TEXT NOT NULL,
            member_number TEXT NOT NULL,
            sequence INTEGER NOT NULL,
            idempotency_key TEXT NOT NULL,
            requested_by TEXT NOT NULL,
            allocated_at TEXT NOT NULL,
            UNIQUE(gym_id, user_id),
            UNIQUE(gym_id, member_number),
            UNIQUE(gym_id, idempotency_key)
        )
        "#,
    )
    .execute(db)
    .await?;

    Ok(())
}

async fn health() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "ok",
        service: "member-number-service",
    })
}

async fn allocate_member_number(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(request): Json<AllocateMemberNumberRequest>,
) -> Result<Json<AllocateMemberNumberResponse>, ApiError> {
    let claims = verify_firebase_token(&state, &headers).await?;

    if request.user_id.trim().is_empty() {
        return Err(ApiError::validation("user_id es requerido"));
    }

    if request.gym_id.trim().is_empty() {
        return Err(ApiError::validation("gym_id es requerido"));
    }

    if request.role.trim() != "client" {
        return Err(ApiError::validation("Solo se permite memberNumber para clientes."));
    }

    let requested_by = claims.sub;
    let idempotency_key = request
        .idempotency_key
        .clone()
        .unwrap_or_else(|| format!("{}:{}:{}", request.gym_id, request.user_id, request.role));

    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|e| ApiError::server(format!("No se pudo iniciar transacción: {e}")))?;

    if let Some(existing) = find_existing_allocation(&mut tx, &request.gym_id, &request.user_id, &idempotency_key).await? {
        tx.commit()
            .await
            .map_err(|e| ApiError::server(format!("No se pudo cerrar transacción: {e}")))?;
        return Ok(Json(existing));
    }

    let current_sequence = sqlx::query(
        "SELECT last_sequence FROM member_number_sequences WHERE gym_id = ?1",
    )
    .bind(&request.gym_id)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| ApiError::server(format!("No se pudo leer secuencia: {e}")))?
    .map(|row| row.get::<i64, _>("last_sequence"))
    .unwrap_or(0);

    let next_sequence = current_sequence + 1;
    let allocated_at = Utc::now().to_rfc3339();
    let prefix = build_gym_prefix(&request.gym_id);
    let member_number = format!("{prefix}-{:06}", next_sequence);

    sqlx::query(
        r#"
        INSERT INTO member_number_sequences (gym_id, last_sequence, updated_at)
        VALUES (?1, ?2, ?3)
        ON CONFLICT(gym_id)
        DO UPDATE SET last_sequence = excluded.last_sequence, updated_at = excluded.updated_at
        "#,
    )
    .bind(&request.gym_id)
    .bind(next_sequence)
    .bind(&allocated_at)
    .execute(&mut *tx)
    .await
    .map_err(|e| ApiError::server(format!("No se pudo actualizar secuencia: {e}")))?;

    let insert_result = sqlx::query(
        r#"
        INSERT INTO member_number_allocations (
            gym_id,
            user_id,
            role,
            member_number,
            sequence,
            idempotency_key,
            requested_by,
            allocated_at
        )
        VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
        "#,
    )
    .bind(&request.gym_id)
    .bind(&request.user_id)
    .bind(&request.role)
    .bind(&member_number)
    .bind(next_sequence)
    .bind(&idempotency_key)
    .bind(&requested_by)
    .bind(&allocated_at)
    .execute(&mut *tx)
    .await;

    if insert_result.is_err() {
        if let Some(existing) = find_existing_allocation(&mut tx, &request.gym_id, &request.user_id, &idempotency_key).await? {
            tx.commit()
                .await
                .map_err(|e| ApiError::server(format!("No se pudo cerrar transacción: {e}")))?;
            return Ok(Json(existing));
        }

        return Err(ApiError::conflict(
            "No se pudo asignar memberNumber por conflicto de secuencia.",
        ));
    }

    tx.commit()
        .await
        .map_err(|e| ApiError::server(format!("No se pudo confirmar transacción: {e}")))?;

    Ok(Json(AllocateMemberNumberResponse {
        member_number,
        sequence: next_sequence,
        gym_id: request.gym_id,
        format: "PREFIX-000000".to_string(),
        allocated_at,
        requested_by,
    }))
}

async fn find_existing_allocation(
    tx: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    gym_id: &str,
    user_id: &str,
    idempotency_key: &str,
) -> Result<Option<AllocateMemberNumberResponse>, ApiError> {
    let row = sqlx::query(
        r#"
        SELECT gym_id, member_number, sequence, allocated_at, requested_by
        FROM member_number_allocations
        WHERE gym_id = ?1 AND (user_id = ?2 OR idempotency_key = ?3)
        LIMIT 1
        "#,
    )
    .bind(gym_id)
    .bind(user_id)
    .bind(idempotency_key)
    .fetch_optional(&mut **tx)
    .await
    .map_err(|e| ApiError::server(format!("No se pudo consultar asignación previa: {e}")))?;

    Ok(row.map(|existing| AllocateMemberNumberResponse {
        member_number: existing.get::<String, _>("member_number"),
        sequence: existing.get::<i64, _>("sequence"),
        gym_id: existing.get::<String, _>("gym_id"),
        format: "PREFIX-000000".to_string(),
        allocated_at: existing.get::<String, _>("allocated_at"),
        requested_by: existing.get::<String, _>("requested_by"),
    }))
}

fn build_gym_prefix(gym_id: &str) -> String {
    let sanitized: String = gym_id
        .chars()
        .filter(|c| c.is_ascii_alphanumeric())
        .map(|c| c.to_ascii_uppercase())
        .take(8)
        .collect();

    if sanitized.is_empty() {
        "MEMBER".to_string()
    } else {
        sanitized
    }
}

async fn verify_firebase_token(
    state: &AppState,
    headers: &HeaderMap,
) -> Result<FirebaseClaims, ApiError> {
    let header = headers
        .get(axum::http::header::AUTHORIZATION)
        .ok_or_else(|| ApiError::unauthorized("Authorization header faltante"))?
        .to_str()
        .map_err(|_| ApiError::unauthorized("Authorization header inválido"))?;

    let token = header
        .strip_prefix("Bearer ")
        .ok_or_else(|| ApiError::unauthorized("Bearer token faltante"))?;

    let decoded_header = decode_header(token)
        .map_err(|_| ApiError::unauthorized("Token JWT inválido"))?;
    let kid = decoded_header
        .kid
        .ok_or_else(|| ApiError::unauthorized("Token sin key id"))?;

    let certs: HashMap<String, String> = state
        .http_client
        .get("https://www.googleapis.com/service_accounts/v1/metadata/x509/securetoken@system.gserviceaccount.com")
        .send()
        .await
        .map_err(|e| ApiError::server(format!("No se pudo consultar certificados Firebase: {e}")))?
        .error_for_status()
        .map_err(|e| ApiError::server(format!("Certificados Firebase no disponibles: {e}")))?
        .json()
        .await
        .map_err(|e| ApiError::server(format!("No se pudieron parsear certificados Firebase: {e}")))?;

    let cert = certs
        .get(&kid)
        .ok_or_else(|| ApiError::unauthorized("No se encontró certificado para el token"))?;

    let decoding_key = DecodingKey::from_rsa_pem(cert.as_bytes())
        .map_err(|_| ApiError::unauthorized("No se pudo construir la clave pública Firebase"))?;

    let mut validation = Validation::new(Algorithm::RS256);
    validation.set_audience(&[state.firebase_project_id.as_str()]);
    validation.set_issuer(&[state.firebase_issuer.as_str()]);

    let decoded = decode::<FirebaseClaims>(token, &decoding_key, &validation)
        .map_err(|_| ApiError::unauthorized("Token Firebase inválido o expirado"))?;

    if decoded.claims.sub.trim().is_empty() {
        return Err(ApiError::unauthorized("Token Firebase sin subject válido"));
    }

    Ok(decoded.claims)
}
