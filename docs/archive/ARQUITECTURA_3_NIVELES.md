# 🏗️ ARQUITECTURA DE 3 NIVELES - QUANTUM GYM APP

## 📊 JERARQUÍA DE ROLES

```
┌─────────────────────────────────────────────────────────────┐
│                         ADMIN                                │
│  - Crea y gestiona GIMNASIOS                                │
│  - Crea DUEÑOS y los asigna a gimnasios                     │
│  - Biblioteca GLOBAL de ejercicios (scope=global)           │
│  - Reportes, Billing, Audit                                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                         DUEÑO                                │
│  - Gestiona SU gimnasio                                     │
│  - Crea EMPLEADOS (tentáculos con permisos limitados)       │
│  - Crea CLIENTES/USUARIOS                                   │
│  - Biblioteca de ejercicios: global + custom (scope=gym)    │
│  - TrainingForge: crea RUTINAS personalizadas               │
│  - ASIGNA rutinas a CLIENTES                                │
│  - Planes de membresía, POS, BI, Finanzas                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                       EMPLEADO                               │
│  - Tentáculo del DUEÑO con permisos limitados               │
│  - Escanea QR de clientes (check-in)                        │
│  - Gestiona rutinas (asignar/ver)                           │
│  - NO puede crear ejercicios                                │
│  - NO puede gestionar finanzas                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    CLIENTE/USUARIO                           │
│  - Ve rutinas ASIGNADAS por dueño/empleado                  │
│  - Ejecuta entrenamientos                                   │
│  - Ve estadísticas y progreso                               │
│  - QR digital para check-in                                 │
│  - Perfil y configuraciones                                 │
└─────────────────────────────────────────────────────────────┘
```

## 🗄️ ESTRUCTURA DE FIRESTORE

### Colecciones Principales

```
firestore/
├── gyms/                           # Gimnasios (creados por ADMIN)
│   ├── {gymId}/
│   │   ├── name, address, owner, etc.
│   │   └── members/                # Sub-colección de miembros
│   │       └── {userId}/
│   │           └── plan, expiry, status, etc.
│
├── users/                          # Usuarios globales
│   └── {userId}/
│       ├── role: admin|owner|employee|client
│       ├── gymId: referencia al gimnasio
│       └── displayName, email, etc.
│
├── exercises/                      # Biblioteca de ejercicios
│   └── {exerciseId}/
│       ├── scope: global|gym       # global=Admin, gym=Dueño
│       ├── gymId: null|{gymId}     # null si es global
│       ├── createdBy: userId
│       └── name, description, equipment, etc.
│
├── routines/                       # Rutinas creadas por DUEÑO
│   └── {routineId}/
│       ├── gymId: {gymId}          # Pertenece a un gimnasio
│       ├── createdBy: userId       # Dueño que la creó
│       ├── name, difficulty, focus
│       ├── exercises: [...]        # Lista de ejercicios
│       └── isActive: true|false
│
├── assignments/                    # ASIGNACIONES de rutinas a clientes
│   └── {assignmentId}/
│       ├── gymId: {gymId}          # Aislamiento multi-tenant
│       ├── routineId: {routineId}  # Rutina asignada
│       ├── clientId: {userId}      # Cliente que la recibe
│       ├── assignedById: userId    # Dueño/Empleado que asignó
│       ├── startDate, endDate
│       ├── status: active|completed|cancelled
│       └── notes: string
│
├── workout_sessions/               # Sesiones de entrenamiento
│   └── {sessionId}/
│       ├── userId: {userId}        # Cliente que entrena
│       ├── routineId: {routineId}  # Rutina ejecutada
│       ├── date, duration
│       ├── exercises: [...]        # Ejercicios con sets/reps/peso
│       └── isCompleted: true|false
│
└── membership_plans/               # Planes de membresía (por gimnasio)
    └── {planId}/
        ├── gymId: {gymId}
        ├── name, price, duration
        └── features: [...]
```

## 🔄 FLUJO DE ASIGNACIÓN DE RUTINAS

### 1. DUEÑO crea rutina en TrainingForge

```dart
// TrainingForgeScreen → Crea WorkoutRoutine
WorkoutRoutine.create(
  name: "Hipertrofia Avanzada",
  gymId: dueñoGymId,
  createdBy: dueñoUserId,
  exercises: [...],
  difficulty: Difficulty.advanced,
  isActive: true,
)

// Se guarda en: routines/{routineId}
```

### 2. DUEÑO asigna rutina a CLIENTE

```dart
// OwnerMembersScreen → Asignar Rutina
AssignRoutineUseCase.execute(
  AssignRoutineCommand(
    routineId: routineId,
    clientId: clientUserId,
    assignerId: dueñoUserId,
    startDate: DateTime.now(),
    endDate: DateTime.now().add(Duration(days: 30)),
    notes: "Enfoque en volumen",
  )
)

// Se guarda en: assignments/{assignmentId}
```

### 3. CLIENTE ve rutina asignada

```dart
// AppBloc → GetClientProfileUseCase
// Lee: assignments/ donde clientId == userId
// Obtiene: WorkoutRoutine desde routines/
// Muestra en: TrainingDashboardScreen, RoutineSelectionScreen
```

### 4. CLIENTE ejecuta rutina

```dart
// ActiveWorkoutScreen → Ejecuta rutina
// Crea: workout_sessions/{sessionId}
// Actualiza: estadísticas, volumen, PRs
```

## ✅ VERIFICACIÓN DE PERMISOS

### Admin
- ✅ Crear gimnasios
- ✅ Crear dueños
- ✅ Biblioteca global de ejercicios (scope=global)
- ✅ Acceso a todos los gimnasios
- ✅ Reportes y auditoría

### Dueño
- ✅ Gestionar SU gimnasio
- ✅ Crear empleados
- ✅ Crear clientes
- ✅ Biblioteca de ejercicios (global + custom scope=gym)
- ✅ TrainingForge (crear rutinas)
- ⚠️ **FALTA**: UI para asignar rutinas a clientes
- ✅ Planes de membresía
- ✅ POS, BI, Finanzas

### Empleado
- ✅ QR Scanner (check-in)
- ⚠️ **FALTA**: Gestión de rutinas (ver/asignar)
- ❌ NO puede crear ejercicios
- ❌ NO puede gestionar finanzas

### Cliente
- ✅ Ver rutinas asignadas (AppBloc)
- ✅ Ejecutar entrenamientos
- ✅ Estadísticas y progreso
- ✅ QR digital
- ✅ Perfil y configuraciones

## 🚨 FUNCIONALIDADES FALTANTES

### 1. UI de Asignación de Rutinas (DUEÑO)
**Ubicación**: `OwnerMembersScreen` → Menú contextual del miembro

**Acción necesaria**:
- Agregar opción "Asignar Rutina" en el menú del miembro
- Mostrar diálogo con lista de rutinas disponibles del gimnasio
- Llamar a `AssignRoutineUseCase` al confirmar
- Actualizar lista de asignaciones

### 2. Pantalla de Gestión de Rutinas (EMPLEADO)
**Ubicación**: Nueva pantalla `StaffRoutineManagementScreen`

**Acción necesaria**:
- Ver lista de clientes del gimnasio
- Ver rutinas asignadas a cada cliente
- Asignar rutinas (permiso limitado)
- NO puede crear rutinas nuevas

### 3. Verificación de Datos en Firestore
**Acción necesaria**:
- Verificar que `routines` se guarden correctamente
- Verificar que `assignments` se guarden correctamente
- Verificar que `GetClientProfileUseCase` lea correctamente las asignaciones

## 📝 PRÓXIMOS PASOS

1. ✅ Crear UI de asignación de rutinas en `OwnerMembersScreen`
2. ✅ Crear pantalla de gestión de rutinas para empleado
3. ✅ Verificar flujo completo de asignación
4. ✅ Probar con datos reales en Firestore
5. ✅ Documentar permisos y restricciones
