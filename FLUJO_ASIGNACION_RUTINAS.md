# 🎯 FLUJO COMPLETO DE ASIGNACIÓN DE RUTINAS

## 📋 RESUMEN EJECUTIVO

**Objetivo**: El dueño crea rutinas en TrainingForge y las asigna a sus clientes. Los clientes ven las rutinas asignadas en su dashboard y pueden ejecutarlas.

**Estado**: ✅ **IMPLEMENTADO Y FUNCIONAL**

---

## 🔄 FLUJO PASO A PASO

### PASO 1: Dueño crea rutina en TrainingForge

**Pantalla**: `/owner/forge` (TrainingForgeScreen)

**Acciones**:
1. Dueño navega a "Training Forge" desde el sidebar
2. Selecciona tab "Routine Lab"
3. Click en "Nueva Rutina"
4. Completa formulario:
   - Nombre: "Hipertrofia Avanzada"
   - Descripción: "Programa de 4 días enfocado en volumen"
   - Dificultad: Advanced
   - Enfoque: Hypertrophy
   - Duración estimada: 60 minutos
   - Ejercicios: Selecciona de la lista (ej: Press Banca, Sentadilla, etc.)
5. Click en "Guardar"

**Resultado**:
```javascript
// Se guarda en memoria (TrainingForgeStore)
ForgeRoutine {
  id: "rt_005",
  name: "Hipertrofia Avanzada",
  description: "Programa de 4 días...",
  exerciseIds: ["ex_001", "ex_002", "ex_004"],
  difficulty: "Avanzado",
  focus: "Hipertrofia",
  estimatedMinutes: 60,
  gymCreator: "Quantum Gym",
  createdAt: DateTime.now()
}

// Se persiste en Firestore: routines/rt_005
{
  "gymId": "quantum-gym-id",
  "createdBy": "owner-user-id",
  "name": "Hipertrofia Avanzada",
  "description": "Programa de 4 días enfocado en volumen",
  "difficulty": "advanced",
  "focus": "hypertrophy",
  "estimatedMinutes": 60,
  "exercises": [
    {
      "exerciseId": "ex_001",
      "order": 1,
      "sets": 3,
      "reps": "8-12",
      "restSeconds": 90
    },
    ...
  ],
  "isActive": true,
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

---

### PASO 2: Dueño asigna rutina a cliente

**Pantalla**: `/owner/members` (OwnerMembersScreen)

**Acciones**:
1. Dueño navega a "Miembros" desde el sidebar
2. Busca al cliente "Carlos Mendoza"
3. Click en menú contextual (⋮) del cliente
4. Selecciona "Asignar Rutina"
5. Se abre diálogo con lista de rutinas disponibles
6. Selecciona "Hipertrofia Avanzada"
7. Confirma con fechas:
   - Fecha inicio: 2026-02-24
   - Fecha fin: 2026-03-24
   - Notas: "Enfoque en volumen, aumentar peso progresivamente"
8. Click en "Asignar"

**Código ejecutado**:
```dart
// OwnerMembersScreen._assignRoutineToClient()
await FirebaseFirestore.instance
  .collection('assignments')
  .add({
    'gymId': 'quantum-gym-id',
    'routineId': 'rt_005',
    'clientId': 'carlos-mendoza-id',
    'assignedById': 'owner-user-id',
    'startDate': '2026-02-24',
    'endDate': '2026-03-24',
    'notes': 'Enfoque en volumen...',
    'status': 'active',
    'createdAt': FieldValue.serverTimestamp(),
  });
```

**Resultado en Firestore**: `assignments/{assignment-id}`
```json
{
  "gymId": "quantum-gym-id",
  "routineId": "rt_005",
  "clientId": "carlos-mendoza-id",
  "assignedById": "owner-user-id",
  "startDate": "2026-02-24",
  "endDate": "2026-03-24",
  "notes": "Enfoque en volumen, aumentar peso progresivamente",
  "status": "active",
  "createdAt": Timestamp
}
```

**Notificación**: ✓ Rutina "Hipertrofia Avanzada" asignada a Carlos Mendoza

---

### PASO 3: Cliente ve rutina asignada

**Pantalla**: `/client/home` (TrainingDashboardScreen)

**Proceso automático**:
1. Cliente inicia sesión como `carlos@quantum.com`
2. AppBloc se inicializa automáticamente
3. Se ejecuta `GetClientProfileUseCase`

**Código ejecutado**:
```dart
// GetClientProfileUseCase.execute()
// 1. Fetch assignments
final assignmentsSnapshot = await _firestore
  .collection('assignments')
  .where('gymId', isEqualTo: gymId)
  .where('clientId', isEqualTo: userId)
  .where('status', isEqualTo: 'active')
  .get();

// 2. Fetch routine details
for (assignment in assignments) {
  final routineDoc = await _firestore
    .collection('routines')
    .doc(assignment.routineId)
    .get();
  
  // Build WorkoutRoutine entity
  routines.add(WorkoutRoutine.fromFirestore(routineDoc));
}

// 3. Return ClientProfileData
return ClientProfileData(
  assignedRoutines: routines,
  activeAssignments: assignments,
  ...
);
```

**UI mostrada**:
```
┌─────────────────────────────────────────┐
│  CONTINUAR ENTRENAMIENTO                │
│  ┌───────────────────────────────────┐  │
│  │ 🏋️ HIPERTROFIA AVANZADA          │  │
│  │ 60 MIN • 3 EJERCICIOS             │  │
│  │                                   │  │
│  │ [COMENZAR] ──────────────────────>│  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

---

### PASO 4: Cliente ejecuta rutina

**Pantalla**: `/client/daily-workout` (ActiveWorkoutScreen)

**Acciones**:
1. Cliente click en "COMENZAR"
2. Se abre ActiveWorkoutScreen con la rutina
3. Cliente completa ejercicios:
   - Press Banca: 4x12 @ 80kg
   - Sentadilla: 4x10 @ 100kg
   - Dominadas: 3x8 @ Peso corporal
4. Click en "Finalizar Entrenamiento"

**Código ejecutado**:
```dart
// ActiveWorkoutScreen.finishWorkout()
await FirebaseFirestore.instance
  .collection('workout_sessions')
  .add({
    'userId': 'carlos-mendoza-id',
    'routineId': 'rt_005',
    'assignmentId': 'assignment-id',
    'date': DateTime.now().toIso8601String(),
    'duration': 3600, // segundos
    'isCompleted': true,
    'exercises': [
      {
        'exerciseId': 'ex_001',
        'sets': [
          {'setNumber': 1, 'reps': 12, 'weight': 80, 'rpe': 8, 'completed': true},
          {'setNumber': 2, 'reps': 12, 'weight': 80, 'rpe': 8, 'completed': true},
          ...
        ]
      },
      ...
    ],
    'totalVolume': 2400, // kg
    'caloriesBurned': 450,
    'notes': 'Buen entrenamiento',
    'createdAt': FieldValue.serverTimestamp(),
  });
```

**Resultado**: Sesión guardada en `workout_sessions/{session-id}`

---

### PASO 5: Estadísticas se actualizan

**Proceso automático**:
1. AppBloc detecta nueva sesión
2. Recalcula estadísticas:
   - Racha actual: +1 día
   - Volumen semanal: +2400 kg
   - Calorías quemadas: +450 kcal
   - Total entrenamientos: +1
3. UI se actualiza automáticamente

**Dashboard actualizado**:
```
┌─────────────────────────────────────────┐
│  ESTADÍSTICAS                           │
│  ┌─────────┬─────────┬─────────┐        │
│  │ RACHA   │ VOLUMEN │ SESIONES│        │
│  │ 5 DÍAS  │ 12.4 T  │ 23      │        │
│  └─────────┴─────────┴─────────┘        │
└─────────────────────────────────────────┘
```

---

## 🗂️ ESTRUCTURA DE DATOS EN FIRESTORE

### Colección: `routines/`
```json
{
  "rt_005": {
    "gymId": "quantum-gym-id",
    "createdBy": "owner-user-id",
    "name": "Hipertrofia Avanzada",
    "description": "Programa de 4 días enfocado en volumen",
    "difficulty": "advanced",
    "focus": "hypertrophy",
    "estimatedMinutes": 60,
    "exercises": [
      {
        "exerciseId": "ex_001",
        "order": 1,
        "sets": 3,
        "reps": "8-12",
        "restSeconds": 90
      }
    ],
    "isActive": true,
    "createdAt": "2026-02-24T10:00:00Z",
    "updatedAt": "2026-02-24T10:00:00Z"
  }
}
```

### Colección: `assignments/`
```json
{
  "assignment-001": {
    "gymId": "quantum-gym-id",
    "routineId": "rt_005",
    "clientId": "carlos-mendoza-id",
    "assignedById": "owner-user-id",
    "startDate": "2026-02-24",
    "endDate": "2026-03-24",
    "notes": "Enfoque en volumen",
    "status": "active",
    "createdAt": "2026-02-24T11:00:00Z"
  }
}
```

### Colección: `workout_sessions/`
```json
{
  "session-001": {
    "userId": "carlos-mendoza-id",
    "routineId": "rt_005",
    "assignmentId": "assignment-001",
    "date": "2026-02-24T14:30:00Z",
    "duration": 3600,
    "isCompleted": true,
    "exercises": [...],
    "totalVolume": 2400,
    "caloriesBurned": 450,
    "notes": "Buen entrenamiento",
    "createdAt": "2026-02-24T15:30:00Z"
  }
}
```

---

## 🔧 COMPONENTES IMPLEMENTADOS

### 1. TrainingForgeStore (Persistencia)
**Archivo**: `lib/src/presentation/screens/owner/training_forge_store.dart`

**Funcionalidad**:
- ✅ Guarda rutinas en memoria (ChangeNotifier)
- ✅ Persiste rutinas en Firestore automáticamente
- ✅ Métodos: `addRoutine()`, `updateRoutine()`, `deleteRoutine()`

### 2. OwnerMembersScreen (Asignación)
**Archivo**: `lib/src/presentation/screens/owner/owner_members_screen.dart`

**Funcionalidad**:
- ✅ Menú contextual con opción "Asignar Rutina"
- ✅ Diálogo de selección de rutinas (lee de Firestore)
- ✅ Diálogo de confirmación con fechas y notas
- ✅ Guarda asignación en Firestore

### 3. GetClientProfileUseCase (Lectura)
**Archivo**: `lib/src/application/use_cases/client/get_client_profile_usecase.dart`

**Funcionalidad**:
- ✅ Lee asignaciones activas del cliente
- ✅ Obtiene detalles de rutinas asignadas
- ✅ Retorna `ClientProfileData` con rutinas

### 4. AppBloc (Estado)
**Archivo**: `lib/src/presentation/bloc/app_bloc.dart`

**Funcionalidad**:
- ✅ Carga datos del cliente al iniciar
- ✅ Expone rutinas asignadas en `AppLoaded.assignedPlan`
- ✅ Actualiza estadísticas automáticamente

### 5. TrainingDashboardScreen (UI Cliente)
**Archivo**: `lib/src/presentation/screens/home/training_dashboard_screen.dart`

**Funcionalidad**:
- ✅ Muestra rutina asignada en card destacado
- ✅ Botón "COMENZAR" para ejecutar rutina
- ✅ Estadísticas actualizadas

---

## ✅ CHECKLIST DE VERIFICACIÓN

### Dueño
- [x] Puede crear rutinas en TrainingForge
- [x] Rutinas se guardan en Firestore automáticamente
- [x] Puede ver lista de miembros
- [x] Puede asignar rutinas a clientes desde menú contextual
- [x] Ve lista de rutinas disponibles de su gimnasio
- [x] Puede especificar fechas y notas al asignar
- [x] Recibe confirmación de asignación exitosa

### Cliente
- [x] Ve rutinas asignadas en dashboard
- [x] Puede ejecutar rutinas asignadas
- [x] Sesiones se guardan en Firestore
- [x] Estadísticas se actualizan automáticamente
- [x] Ve progreso y volumen acumulado

### Sistema
- [x] AssignRoutineUseCase registrado en DI
- [x] Firestore collections correctas
- [x] Queries optimizadas con índices
- [x] Manejo de errores robusto
- [x] Logs de auditoría

---

## 🚀 PRÓXIMOS PASOS SUGERIDOS

### 1. Notificaciones Push
- [ ] Notificar al cliente cuando se le asigna una rutina
- [ ] Recordatorios de entrenamientos pendientes

### 2. Vista de Asignaciones (Dueño)
- [ ] Pantalla para ver todas las asignaciones activas
- [ ] Filtrar por cliente, rutina, fecha
- [ ] Métricas de cumplimiento

### 3. Empleado - Gestión de Rutinas
- [ ] Pantalla para que empleado vea clientes
- [ ] Empleado puede asignar rutinas (mismo flujo que dueño)
- [ ] Permisos limitados (no puede crear rutinas)

### 4. Mejoras de UX
- [ ] Drag & drop para reordenar ejercicios en rutina
- [ ] Preview de rutina antes de asignar
- [ ] Historial de asignaciones por cliente
- [ ] Gráficas de progreso del cliente

### 5. Validaciones Adicionales
- [ ] Verificar que cliente no tenga rutinas conflictivas
- [ ] Sugerir rutinas según nivel del cliente
- [ ] Alertar si rutina es muy avanzada para el cliente

---

## 📊 MÉTRICAS DE ÉXITO

### KPIs a monitorear:
1. **Tasa de asignación**: % de clientes con rutinas asignadas
2. **Tasa de cumplimiento**: % de sesiones completadas vs asignadas
3. **Tiempo promedio de sesión**: Duración real vs estimada
4. **Volumen total**: Kg levantados por semana/mes
5. **Retención**: Clientes activos con rutinas asignadas

---

## 🎓 GUÍA RÁPIDA DE USO

### Para el Dueño:
```
1. Ir a Training Forge → Routine Lab
2. Crear nueva rutina con ejercicios
3. Ir a Miembros
4. Seleccionar cliente → Asignar Rutina
5. Elegir rutina y confirmar
```

### Para el Cliente:
```
1. Iniciar sesión
2. Ver rutina asignada en dashboard
3. Click en "COMENZAR"
4. Completar ejercicios
5. Finalizar entrenamiento
```

---

## 🔗 ARCHIVOS CLAVE

1. `ARQUITECTURA_3_NIVELES.md` - Jerarquía completa
2. `VERIFICACION_FIRESTORE.md` - Estructura de datos
3. `CONSOLIDATION_STATUS.md` - Estado de consolidación
4. `lib/src/presentation/screens/owner/training_forge_store.dart` - Persistencia
5. `lib/src/presentation/screens/owner/owner_members_screen.dart` - Asignación
6. `lib/src/application/use_cases/client/get_client_profile_usecase.dart` - Lectura

---

**✅ FLUJO COMPLETO IMPLEMENTADO Y FUNCIONAL**
