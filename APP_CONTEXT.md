# 🧠 CONTEXTO TÉCNICO Y FUNCIONAL: QUANTUM GYM

Referencia para entender la estructura, navegación y lógica de negocio de la aplicación. (Actualizado: julio 2026.)

---

## 🏛️ ARQUITECTURA: Clean + Hexagonal

### Capas (rutas reales):
1. **Dominio (`lib/src/domain`)**
   - Entidades (`entities/`), value objects (`value_objects/`).
   - Puertos de salida (`ports/output`) y de entrada (`ports/input`).
   - Datos semilla: `data/` (dataset de ejercicios, rutinas predefinidas) y `services/` (lógica pura, p. ej. `MembershipRenewal`).
   - **Sin dependencias externas.**

2. **Aplicación (`lib/src/application`)**
   - Casos de uso (`use_cases/`) y servicios (`services/`: finanzas, churn, gamificación, análisis de entrenamiento…).
   - Firestore siempre inyectado por constructor (testeable con fakes).

3. **Infraestructura (`lib/src/infrastructure`)**
   - Adaptadores Firebase (`adapters/firebase/`) y locales (`adapters/local/`: media de ejercicios con factory condicional io/web).
   - Caché offline: repos decorados `Cached*` sobre Hive + `ConnectivityService`.
   - DI en `config/di.dart` (GetIt); mappers en `mappers/`.

4. **Presentación (`lib/src/presentation`)**
   - BLoC (`AuthBloc`, `AppBloc`, `RoutineBloc`), GoRouter (`router/app_router.dart`) con guards por rol, tema Quantum UX.

`lib/core/`: AuthStateNotifier (sesión + perfil con uid/gymId/rol), errores, tipos.

---

## 🧭 MAPA DE RUTAS (real, generado del router)

### Autenticación / comunes
`/login` · `/register` · `/forgot-password` · `/profile` (+`edit`) · `/settings` (+`notifications`) · `/help-support` · `/onboarding`

### Admin de plataforma
`/admin/dashboard` · `/admin/gyms` · `/admin/owners` · `/admin/reports` · `/admin/billing` · `/admin/audit` · `/admin/settings` · `/admin/exercises` · `/admin/forge`

### Dueño (Owner) — shell con sidebar (AdminLayout)
| Ruta | Función |
|------|---------|
| `/owner/dashboard` | Dashboard tiempo real (KPIs del gym) |
| `/owner/gym-info` | Información del gimnasio |
| `/owner/members` | Gestión de miembros + **cobro/renovación de membresías** |
| `/owner/staff` | Staff profesional |
| `/owner/pending-registrations` | Solicitudes pendientes (aprobación) |
| `/owner/plans` | Planes de membresía (precio + duración) |
| `/owner/promotions` | Promociones (descuentos, 2x1, referidos) |
| `/owner/exercise-builder` / `/owner/routine-builder` / `/owner/program-builder` | Constructores (Gym Engine) |
| `/owner/exercises` · `/owner/atlas` | Biblioteca/atlas de ejercicios |
| `/owner/forge` | Training Forge (rutinas/programas + compartir QR) |
| `/owner/retention` | Retención con IA (riesgo de abandono) |
| `/owner/dashboard-bi` | Business Intelligence (ingresos, MRR, cohortes) |
| `/owner/pos-sales` · `/owner/pos-inventory` | Punto de venta e inventario |
| `/owner/cash-close` | Conciliación de caja |
| `/owner/finance` | Finanzas/suscripciones |
| `/owner/global-settings` | Configuración del gym |
| `/owner/add-member` | Wizard de alta de miembro |

### Kiosko (requiere sesión owner/staff)
`/kiosk/routines` — catálogo fullscreen + genera QR `routine_import` (expira 10 min)

### Staff
`/staff/home` · `/staff/qr-scanner` (check-in por pase QR) · `/staff/routine-management`

### Cliente — shell con bottom nav
`/client/home` · `/client/routine` · `/client/qr-checkin` · `/client/analytics`

Standalone: `/client/import-routine` (**escáner QR de rutinas** con preview y auto-asignación) · `/client/qr` · `/client/digital-pass` · `/client/daily-workout` · `/client/manual-log` · `/client/workout-analytics` · `/client/volume` · `/client/muscle-heatmap` · `/client/nutrition` · `/client/measurements` · `/client/recovery` · `/client/achievements` · `/client/notifications` · `/client/timer` · `/client/community` · `/client/leaderboard` · `/classes/gym-classes`

---

## 📊 ESQUEMA FIRESTORE PRINCIPAL

- `users/{uid}`: perfil global (rol, gymId, membershipStatus…).
- `gyms/{id}` (+ subcolección `members`: status 'Activos'/'Vencidos', plan, expiry dd/MM/yyyy, isFrozen, registeredAt).
- `membership_plans`: gymId, name, price, duration, durationDays.
- `payments`: gymId, type ('subscription' | 'pos'), amount, date, memberId, method, registeredBy → alimenta BI/finanzas.
- `promotions`: gymId, name, type (percentDiscount/fixedDiscount/twoForOne/freePass/referral), value, code, startDate/endDate, isActive.
- `routines` / `assignments` (auto-asignación permitida: clientId == assignedById al importar por QR) / `workout_sessions` / `personal_records`.
- `subscriptions` (MRR), `daily_closings`, `pos_products`, `pos_sales`, `check_ins`, `access_logs`.
- `gamification/{userId}` (XP, racha, logros), `notifications`, `staff`, `pending_registrations`, `audit_logs`.
- Plataforma: `platform_plans`, `platform_invoices`.

Flujo de cobro de membresía: diálogo en `/owner/members` → batch atómico (pago `type: subscription` + member update status/expiry) → visible en BI/conciliación. Si el miembro está vigente, los días se suman a su vencimiento (`MembershipRenewal`).

---

## 💎 SISTEMA DE DISEÑO: QUANTUM
- **Fondo:** `#0F0F12` (Cosmic Black) · **Superficies:** `#1A1A21` (Void Gray)
- **Acentos:** `#00E0FF` (Quantum Blue) · `#00FFE0` (Matrix Cyan) · `#8B5CF6` (Holo Purple)
- Kiosko con modo alto contraste para accesibilidad.

---

## 🔐 SEGURIDAD
- **Multi-tenancy** por `gymId` en consultas y Firestore Rules.
- **Roles:** admin > owner > employee > client (guards en router + validación en dominio + rules).
- **Pre-aprobación** de registros; **App Check** (Play Integrity/Device Check; web pendiente ReCaptcha).
- Auditoría inmutable (`audit_logs`); secretos fuera del bundle/repo.

---

## 🌐 PLATAFORMAS Y DESPLIEGUE
- Android (APK), Web (con shims io/web para media offline), Windows desktop.
- Web en VPS: ver `deploy/README.md` (Docker nginx + Caddy HTTPS; `deploy.ps1`).
- Reglas: `npx firebase-tools deploy --only firestore` (proyecto `gain-wave`).

---
*Este documento se actualiza al cerrar cada bloque de trabajo importante.*
