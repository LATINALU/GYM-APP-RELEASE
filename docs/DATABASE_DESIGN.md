# 🗄️ DISEÑO DE BASE DE DATOS VPS - GainWave

## Arquitectura: PostgreSQL en VPS + API REST (Supabase/Custom Backend)

### ¿Por qué migrar de Firebase a VPS?
1. **Control total** de datos y seguridad
2. **Costos predecibles** (sin pago por lectura/escritura)
3. **SQL nativo** para reportes complejos
4. **Backups automáticos** y recuperación
5. **Cumplimiento regulatorio** (datos en tu jurisdicción)

---

## 📊 ESQUEMA DE BASE DE DATOS (PostgreSQL)

### Tabla: `gyms` (Negocios/Gimnasios)
```sql
CREATE TABLE gyms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(10) UNIQUE NOT NULL,        -- Código único (ej: IRON42)
  name VARCHAR(200) NOT NULL,
  address TEXT,
  phone VARCHAR(20),
  logo_url TEXT,
  owner_id UUID NOT NULL,                  -- FK → users.id (dueño principal)
  
  -- Configuración financiera
  monthly_price DECIMAL(10,2) DEFAULT 0,
  annual_discount_pct DECIMAL(5,2) DEFAULT 0,
  special_promo_pct DECIMAL(5,2),
  auto_notify_expiration BOOLEAN DEFAULT true,
  
  -- Estado
  is_active BOOLEAN DEFAULT true,
  max_capacity INTEGER DEFAULT 100,
  timezone VARCHAR(50) DEFAULT 'America/Mexico_City',
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Opciones de seguridad
  require_2fa_for_owners BOOLEAN DEFAULT false,
  access_code_expiry_minutes INTEGER DEFAULT 30,
  max_failed_login_attempts INTEGER DEFAULT 5,
  
  CONSTRAINT fk_owner FOREIGN KEY (owner_id) REFERENCES users(id)
);

CREATE INDEX idx_gyms_code ON gyms(code);
CREATE INDEX idx_gyms_owner ON gyms(owner_id);
```

### Tabla: `users` (Todos los usuarios del sistema)
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  
  -- Datos personales
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  photo_url TEXT,
  
  -- Asignación multitenancy
  gym_id UUID,                             -- FK → gyms.id (gym actual)
  role VARCHAR(20) NOT NULL DEFAULT 'client',  -- admin | owner | employee | client
  
  -- Estado de membresía
  membership_status VARCHAR(20) DEFAULT 'pending',  -- pending | approved | rejected
  membership_expires_at TIMESTAMPTZ,
  
  -- Datos fitness
  weight DECIMAL(5,2),
  height DECIMAL(5,2),
  fitness_goal VARCHAR(200),
  
  -- Estado
  is_active BOOLEAN DEFAULT true,
  
  -- Seguridad
  last_login_at TIMESTAMPTZ,
  failed_login_attempts INTEGER DEFAULT 0,
  locked_until TIMESTAMPTZ,
  two_factor_secret TEXT,                  -- TOTP secret para 2FA
  two_factor_enabled BOOLEAN DEFAULT false,
  
  -- Tokens
  refresh_token TEXT,
  device_token TEXT,                       -- Para push notifications
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT fk_gym FOREIGN KEY (gym_id) REFERENCES gyms(id)
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_gym ON users(gym_id);
CREATE INDEX idx_users_role ON users(gym_id, role);
CREATE INDEX idx_users_status ON users(gym_id, membership_status);
```

### Tabla: `pending_registrations` (Pre-aprobación)
```sql
CREATE TABLE pending_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,                   -- FK → users.id
  target_gym_id UUID,                      -- FK → gyms.id (puede ser NULL si no eligió gym)
  
  -- Estado
  status VARCHAR(20) DEFAULT 'pending_review', -- pending_review | approved | rejected | expired | cancelled
  source VARCHAR(20) NOT NULL,             -- qr_scan | manual_code | invitation | app_search | transfer
  
  -- Info adicional del solicitante
  message TEXT,
  access_code_used VARCHAR(50),
  
  -- Revisión
  reviewed_by UUID,                        -- FK → users.id
  reviewed_at TIMESTAMPTZ,
  rejection_reason TEXT,
  
  -- Auto-expiración
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_gym FOREIGN KEY (target_gym_id) REFERENCES gyms(id),
  CONSTRAINT fk_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id)
);

CREATE INDEX idx_pending_gym ON pending_registrations(target_gym_id, status);
CREATE INDEX idx_pending_user ON pending_registrations(user_id);
CREATE INDEX idx_pending_expires ON pending_registrations(expires_at) WHERE status = 'pending_review';
```

### Tabla: `access_codes` (Códigos seguros)
```sql
CREATE TABLE access_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(50) UNIQUE NOT NULL,        -- El código generado (ej: MO-ABCD1234)
  type VARCHAR(30) NOT NULL,               -- gym_entry | owner_verification | employee_invitation | member_onboarding | password_reset | two_factor_auth
  gym_id UUID NOT NULL,                    -- FK → gyms.id
  generated_by UUID NOT NULL,              -- FK → users.id
  
  -- Estado
  is_used BOOLEAN DEFAULT false,
  used_by UUID,                            -- FK → users.id
  used_at TIMESTAMPTZ,
  is_revoked BOOLEAN DEFAULT false,
  
  -- Seguridad
  expires_at TIMESTAMPTZ NOT NULL,
  max_uses INTEGER DEFAULT 1,             -- Cuántas veces puede usarse
  current_uses INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT fk_gym FOREIGN KEY (gym_id) REFERENCES gyms(id),
  CONSTRAINT fk_generated_by FOREIGN KEY (generated_by) REFERENCES users(id),
  CONSTRAINT fk_used_by FOREIGN KEY (used_by) REFERENCES users(id)
);

CREATE INDEX idx_codes_code ON access_codes(code);
CREATE INDEX idx_codes_gym ON access_codes(gym_id, is_used, expires_at);
CREATE INDEX idx_codes_type ON access_codes(type, gym_id);
```

### Tabla: `gym_memberships` (Relación usuario-gym con historial)
```sql
CREATE TABLE gym_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  gym_id UUID NOT NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'client',
  
  -- Estado
  status VARCHAR(20) DEFAULT 'active',    -- active | suspended | cancelled | expired
  
  -- Plan
  plan_type VARCHAR(50),                   -- mensual | trimestral | anual
  price_paid DECIMAL(10,2),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  
  -- Quien lo aprobó/invitó
  approved_by UUID,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_gym FOREIGN KEY (gym_id) REFERENCES gyms(id),
  CONSTRAINT fk_approved_by FOREIGN KEY (approved_by) REFERENCES users(id),
  UNIQUE(user_id, gym_id)                 -- Un usuario solo puede tener una membresía por gym
);

CREATE INDEX idx_memberships_user ON gym_memberships(user_id);
CREATE INDEX idx_memberships_gym ON gym_memberships(gym_id, status);
CREATE INDEX idx_memberships_expires ON gym_memberships(expires_at) WHERE status = 'active';
```

### Tabla: `audit_log` (Registro de auditoría)
```sql
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID,
  user_id UUID,                            -- Quien hizo la acción
  target_user_id UUID,                     -- Sobre quién se hizo
  action VARCHAR(100) NOT NULL,            -- approve_member | reject_member | generate_code | revoke_code | etc.
  details JSONB,                           -- Detalles adicionales
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_gym ON audit_log(gym_id, created_at DESC);
CREATE INDEX idx_audit_user ON audit_log(user_id, created_at DESC);
```

---

## 🔐 SEGURIDAD

### 1. Generación de Códigos (CSPRNG)
```
Implementado en: lib/src/domain/value_objects/access_code.dart
- Usa Random.secure() (CSPRNG del SO)
- Caracteres ambiguos eliminados (0/O, 1/I/L)
- Prefijo por tipo: GE-, OV-, EI-, MO-, PR-, 2F-
- Expiración configurable
- Single-use con tracking
```

### 2. Autenticación JWT
```
- Access Token: 15 min expiración
- Refresh Token: 30 días, rotación automática
- Stored securely con flutter_secure_storage
```

### 3. Rate Limiting
```
- Login: 5 intentos, bloqueo 15 min
- Code generation: 10 por hora por gym
- API requests: 100/min por usuario
```

### 4. Row Level Security (RLS)
```sql
-- Los dueños solo ven datos de su gym
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY gym_isolation ON users
  USING (gym_id = current_setting('app.current_gym_id')::UUID);
```

---

## 🏗️ VPS SETUP RECOMENDADO

### Opción A: Supabase Self-Hosted (Recomendado)
```
- PostgreSQL incluido + Auth + Storage + REST API automático
- Docker Compose en tu VPS
- Panel admin incluido
- Costo: ~$20-40/mes VPS
```

### Opción B: Custom Backend (Node.js/TypeScript)
```
- PostgreSQL + Express/Fastify
- Prisma como ORM
- JWT para auth
- Costo: ~$10-20/mes VPS
```

### Especificaciones mínimas del VPS:
```
- 2 vCPU
- 4 GB RAM
- 80 GB SSD
- Ubuntu 22.04 LTS
- Proveedores: DigitalOcean, Hetzner, Contabo
```

---

## 📱 FLUJO DE REGISTRO (Actualizado)

```
1. Usuario descarga app (Play Store / App Store)
   └─→ Pantalla de bienvenida

2. Usuario crea cuenta (email + password)
   └─→ Se crea en tabla `users` (sin gym_id, status: pending)
   └─→ Se crea registro en `pending_registrations`

3. Usuario elige gym:
   a) Escanea QR del gym → `source: qr_scan`
   b) Ingresa código manualmente → `source: manual_code`
   c) Busca en la app → `source: app_search`
   d) Recibe invitación → `source: invitation`

4. Solicitud llega al dueño del gym
   └─→ Notificación push
   └─→ Aparece en "Solicitudes Pendientes"

5. Dueño revisa y decide:
   ├─→ APROBAR: Usuario se agrega a `gym_memberships`, status: active
   └─→ RECHAZAR: Se notifica al usuario, puede intentar otro gym

6. Usuario aprobado:
   └─→ Acceso completo al gym
   └─→ Check-in por QR/NFC
   └─→ Rutinas, nutrición, etc.
```

---

## 🔄 MIGRACIÓN FIREBASE → VPS

### Fase 1: Preparación (Semana 1-2)
- [ ] Configurar VPS con PostgreSQL
- [ ] Crear esquema de base de datos
- [ ] Implementar API REST backend
- [ ] Configurar SSL/TLS

### Fase 2: Capa de Abstracción (Semana 3)
- [ ] Crear nuevos adapters (PostgresUserRepository, etc.)
- [ ] Implementar los mismos Output Ports con PostgreSQL
- [ ] La app NO cambia (solo el adapter)

### Fase 3: Migración de Datos (Semana 4)
- [ ] Script de migración Firestore → PostgreSQL
- [ ] Validación de integridad
- [ ] Testing con datos reales

### Fase 4: Cutover (Semana 5)
- [ ] Cambiar DI container para usar adapters PostgreSQL
- [ ] Monitoreo intensivo
- [ ] Rollback plan si hay problemas

---

*Documento generado: 2026-02-11*
*Última actualización: v1.0*
