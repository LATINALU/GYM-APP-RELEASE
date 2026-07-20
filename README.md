# 🏋️‍♂️ QUANTUM GYM — Plataforma de Gestión de Gimnasios

Plataforma **multi-tenant** de gestión de gimnasios construida en Flutter + Firebase. Cuatro roles (admin de plataforma, dueño, staff y cliente) más un **modo kiosko** para estaciones dentro del gym. Interfaz oscura premium (Quantum UX) optimizada para OLED.

📸 Capturas en [`docs/screenshots/`](docs/screenshots/).

---

## 🚀 Características por rol

### 🏢 Dueño (Owner)
- **Dashboard en tiempo real** y **Business Intelligence** con datos reales: ingresos del mes con tendencia, MRR, estado de membresías, gráfico de 6 meses y retención por cohortes.
- **Gestión de miembros** con flujo completo de cobro: selecciona plan (precio y duración autocompletados), método de pago, y la renovación extiende el vencimiento vigente (batch atómico: pago + renovación + auditoría).
- **Planes de membresía**, **Promociones** (descuento %, monto fijo, 2x1, pase gratis, referidos — con vigencia, código y estados derivados) y **staff profesional**.
- **Punto de venta** con inventario y **conciliación de caja** (POS + membresías + cierres diarios).
- **Solicitudes pendientes** con aprobación de registros.
- **Gym Engine**: constructor de ejercicios, rutinas y programas + **Training Forge** (compartir rutinas por QR).
- **Retención con IA**: predicción de abandono por inasistencia y tendencia (filtro multi-tenant obligatorio).

### 🖥️ Kiosko (estación en el gym)
- Catálogo de rutinas en pantalla completa con filtros, alto contraste y caché offline.
- Genera **QR de importación** (expira en 10 min) que el cliente escanea desde su teléfono. Requiere sesión de owner/staff.

### 👥 Staff
- Home con check-ins del día y conteo de clientes activos.
- **Escáner QR de acceso** (pase digital del cliente) con validación de membresía.

### 👤 Cliente (Atleta)
- Home con progreso real (entrenamientos del mes, racha) y rutina del día.
- **Importar rutina por QR** (del kiosko o del coach) con preview y auto-asignación.
- **Biblioteca de 1,324 ejercicios en español** con thumbnails empaquetados y GIFs descargables para uso **100% offline** en el gym (móvil/desktop; en web se sirven por red).
- Entrenamiento activo con registro de series → alimenta gamificación (XP, logros, racha), analytics, volumen por músculo y récords personales.
- Nutrición (catálogo local de ~85 alimentos), recuperación, medidas corporales, mapa muscular, pase QR digital.

### 🛡️ Admin de plataforma
- Métricas globales de todos los gimnasios, gestión de dueños, planes de plataforma y facturación (MRR), auditoría.

---

## 🛠️ Stack

| Capa | Tecnología |
|---|---|
| Frontend | Flutter (Android, Web, Windows/desktop) |
| Backend | Firebase: Firestore, Auth, Messaging, App Check |
| Estado | flutter_bloc |
| Navegación | GoRouter (guards por rol) |
| DI | GetIt |
| Offline | Hive (caché repos con patrón decorator `Cached*`) + media local de ejercicios |
| Gráficos / QR | fl_chart, qr_flutter, mobile_scanner |

### Arquitectura (Clean + Hexagonal)

```
lib/
├── core/                  # Auth state, errores, tipos
└── src/
    ├── domain/            # Entidades, value objects, puertos (input/output), datos semilla
    ├── application/       # Casos de uso y servicios de aplicación
    ├── infrastructure/    # Adaptadores Firebase/locales, mappers, DI (config/di.dart)
    └── presentation/      # Screens, BLoCs, router, tema Quantum UX, widgets
```

Regla de oro: el dominio no importa nada externo; Firestore siempre entra inyectado (testeable con fakes).

---

## 📦 Dataset de ejercicios

- 1,324 ejercicios en español de [exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset) (MIT; media © Gym visual — mantener la atribución de `DatasetExerciseCatalog.attribution`).
- Asset `assets/data/exercises_dataset.json` (regenerable con `tool/build_exercises_asset.py`) + 1,324 thumbnails en `assets/exercise_images/`.
- GIFs (~127 MB) NO van en el APK: se descargan on-demand a almacenamiento permanente (`ExerciseMediaPort` → `LocalExerciseMediaService`), con prefetch tras cada sync de rutinas y botón "descargar biblioteca completa".
- 11 rutinas predefinidas (`SeedRoutinesUseCase`, idempotente): 6 propias + 5 programas portados de [LogPress](https://github.com/hasaneyldrm/logpress-public) (MIT).

---

## ⚙️ Instalación y desarrollo

```bash
git clone https://github.com/LATINALU/GYM-APP-RELEASE.git
cd GYM-APP-RELEASE
flutter pub get
flutter run            # dispositivo/emulador
flutter run -d chrome  # web
```

Requisitos: Flutter ≥ 3.44, `android/app/google-services.json` del proyecto Firebase (`gain-wave`).

### Calidad

```bash
flutter analyze   # sin issues
flutter test      # 70 tests (unitarios + widget) — también corren en CI (GitHub Actions)
```

### Builds

```bash
flutter build apk --release      # Android
flutter build web --release      # Web (build/web)
```

---

## 🌐 Despliegue web en VPS

Ver **[`deploy/README.md`](deploy/README.md)**. Resumen: `deploy.ps1` compila, sube por scp y levanta Docker (nginx para la app + Caddy con HTTPS automático). Antes del primer deploy: agregar el dominio en Firebase Auth → Authorized domains.

### Reglas e índices de Firestore

```bash
npx firebase-tools login
npx firebase-tools deploy --only firestore   # proyecto por defecto: gain-wave (.firebaserc)
```

---

## 🔐 Seguridad

- **Multi-tenancy** por `gymId` en todas las consultas y reglas.
- **Roles jerárquicos**: admin > owner > employee > client; guards en GoRouter y validación en dominio + Firestore Rules.
- **Pre-aprobación**: los registros quedan en cola hasta que el gym los acepta.
- **App Check**: Play Integrity (Android) / Device Check (iOS); en web pendiente de registrar ReCaptcha.
- Secretos fuera del bundle y del repo; auditoría inmutable en `audit_logs`.

---

## 📄 Licencia

© 2026 QUANTUM GYM. Todos los derechos reservados.
Dataset de ejercicios y programas semilla bajo MIT (ver atribuciones arriba).

---

*Última actualización: julio 2026.*
