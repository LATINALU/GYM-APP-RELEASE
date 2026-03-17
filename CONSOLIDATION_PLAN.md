# Quantum App - Plan de Consolidación

## 4 Funciones Principales

### 1. AUTENTICACIÓN
- Login
- Register
- Recuperación de contraseña

### 2. DASHBOARD DEL CLIENTE
- Vista principal con estadísticas
- Racha de entrenamientos
- Volumen semanal
- Próxima sesión

### 3. RUTINAS
- Ver rutina asignada por el coach
- Iniciar sesión de entrenamiento
- Historial de sesiones

### 4. PERFIL & CONFIGURACIÓN
- Datos personales
- Métricas corporales
- Configuraciones de la app
- Cerrar sesión

## BLoCs a Mantener

1. **AuthBloc** - Autenticación y sesión
2. **AppBloc** (fusión de HomeBloc + ClientBloc) - Estado global de la app
3. **RoutineBloc** - Gestión de rutinas
4. **SettingsBloc** - Configuraciones

## Eliminar

### Funcionalidades
- ❌ Chat/Chatbot (IA)
- ❌ Coach IA
- ❌ Análisis con IA
- ❌ Recomendaciones automáticas
- ❌ Community/Social
- ❌ Leaderboard
- ❌ Achievements/Gamification
- ❌ Nutrition tracking (simplificar)
- ❌ Recovery tracking (simplificar)
- ❌ Volume tracking separado (integrar en dashboard)

### Datos Legacy
- ❌ Ejercicios pre-creados de GainWave (en inglés)
- ❌ Vistas legacy de GainWave
- ❌ PageControlNav legacy

## Mantener Solo

### Para el Cliente
- Dashboard principal
- Rutinas asignadas por el coach
- Perfil y configuración
- QR para check-in

### Para el Coach/Owner
- Builder de rutinas
- Asignación de rutinas a clientes
- Gestión de ejercicios (crear propios)
- Dashboard de clientes

## Rutas Simplificadas

```
/login
/register
/client/home (dashboard)
/client/routine (rutina asignada)
/client/qr-checkin
/profile
/settings
```

## Fase 4 (P2) - Pruebas E2E mínimas

### Cobertura mínima requerida
- Auth: render del login sin credenciales de ejemplo
- Navegación principal: redirect por rol owner hacia dashboard
- Rutina: apertura de `clientDailyWorkout` desde selección de rutina
- Pago: estado controlado de Finanzas/Cobros sin datos backend

### Implementación actual
- Archivo de pruebas: `test/e2e_minimal_flows_test.dart`
- Tipo: smoke E2E mínimo basado en widget tests (rápido y estable para CI local)

### Ejecución
```bash
flutter test test/e2e_minimal_flows_test.dart
```

> Nota: en este entorno local la ejecución automática puede bloquearse hasta alinear
> tooling (`Dart 3.7.2` vs `flutter_lints ^6.0.0`).

### Verificación manual recomendada
1. Ejecutar login real (owner/client) en emulador
2. Recorrer navegación principal por rol
3. Entrar a rutina y abrir sesión diaria
4. Abrir Finanzas y validar estados de cobro/error/reintento
