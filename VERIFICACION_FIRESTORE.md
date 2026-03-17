# 🔍 VERIFICACIÓN DE DATOS EN FIRESTORE

## � SCHEMA CANÓNICO (ÚNICO)

Colecciones y paths oficiales para app Firebase actual:

- `gyms/{gymId}`
- `gyms/{gymId}/owners/{uid}`
- `gyms/{gymId}/employees/{uid}`
- `gyms/{gymId}/clients/{uid}`
- `users/{uid}` (índice global de perfil)
- `routines/{routineId}` (con `gymId`)
- `assignments/{assignmentId}` (con `gymId`)
- `check_ins/{checkInId}` (con `gymId`)
- `pending_registrations/{registrationId}`
- `gyms/{gymId}/pending_requests/{requestId}` (índice por gym)
- `access_codes/{code}` (índice global)
- `gyms/{gymId}/access_codes/{code}` (copia por gym)

## � CHECKLIST DE COLECCIONES Y DATOS

### ✅ 1. GIMNASIOS (gyms/)
**Creados por**: Admin
**Estructura**:
```json
{
  "gymId": "auto-generated",
  "name": "Quantum Gym",
  "address": "Calle Principal 123",
  "ownerId": "userId-del-dueño",
  "phone": "+52 55 1234 5678",
  "email": "info@quantumgym.com",
  "amenities": ["Pesas", "Cardio", "Clases"],
  "hours": {
    "monday": "06:00-22:00",
    "tuesday": "06:00-22:00",
    ...
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Verificar**:
- [ ] Admin puede crear gimnasios
- [ ] Gimnasios tienen ownerId válido
- [ ] Datos completos (nombre, dirección, etc.)

---

### ✅ 2. USUARIOS (users/)
**Creados por**: Admin (owners), Dueño (employees, clients)
**Estructura**:
```json
{
  "userId": "auto-generated",
  "email": "usuario@gym.com",
  "displayName": "Juan Pérez",
  "role": {
    "type": "client|employee|owner|admin",
    "permissions": [...]
  },
  "gymId": "referencia-al-gimnasio",
  "membershipStatus": "active|pending|expired",
  "createdAt": "timestamp"
}
```

**Verificar**:
- [ ] Roles correctos (admin, owner, employee, client)
- [ ] GymId asignado correctamente
- [ ] Permisos según rol

---

### ✅ 3. EJERCICIOS (exercises/)
**Creados por**: Admin (global), Dueño (gym)
**Estructura**:
```json
{
  "exerciseId": "auto-generated",
  "name": "Press de Banca",
  "description": "Ejercicio compuesto para pectorales",
  "scope": "global|gym",
  "gymId": "null-si-global|gymId-si-custom",
  "createdBy": "userId",
  "movementPattern": "horizontalPush",
  "exerciseType": "compound",
  "equipment": ["barbell", "bench"],
  "difficulty": "intermediate",
  "muscleHeatmap": {
    "chest": 0.9,
    "triceps": 0.6,
    "shoulders": 0.4
  },
  "imageUrl": "url-de-imagen",
  "createdAt": "timestamp"
}
```

**Verificar**:
- [ ] Admin crea ejercicios con scope=global, gymId=null
- [ ] Dueño crea ejercicios con scope=gym, gymId=su-gimnasio
- [ ] Dueño ve ejercicios globales + sus custom
- [ ] Cliente ve ejercicios globales + custom de su gimnasio

---

### ✅ 4. RUTINAS (routines/)
**Creados por**: Dueño/Empleado
**Estructura**:
```json
{
  "routineId": "auto-generated",
  "gymId": "gimnasio-del-dueño",
  "createdBy": "userId-del-dueño",
  "name": "Hipertrofia Avanzada",
  "description": "Programa de 4 días enfocado en volumen",
  "difficulty": "advanced|intermediate|beginner",
  "focus": "hypertrophy|strength|endurance",
  "durationWeeks": 8,
  "isActive": true,
  "exercises": [
    {
      "exerciseId": "ref-a-exercise",
      "order": 1,
      "sets": 4,
      "reps": "8-12",
      "restSeconds": 90,
      "notes": "Controla el descenso"
    },
    ...
  ],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Verificar**:
- [ ] TrainingForge guarda rutinas en routines/
- [ ] Rutinas tienen gymId del dueño
- [ ] Rutinas tienen exercises array con ejercicios válidos
- [ ] isActive = true para rutinas activas
- [ ] Dueño solo ve rutinas de su gimnasio

---

### ✅ 5. ASIGNACIONES (assignments/)
**Creados por**: Dueño/Empleado al asignar rutina a cliente
**Estructura**:
```json
{
  "assignmentId": "auto-generated",
  "routineId": "ref-a-routine",
  "gymId": "gimnasio-del-cliente",
  "clientId": "userId-del-cliente",
  "assignedById": "userId-del-dueño-o-empleado",
  "startDate": "2026-02-24",
  "endDate": "2026-03-24",
  "notes": "Enfoque en volumen, aumentar peso progresivamente",
  "status": "active|completed|cancelled",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Verificar**:
- [ ] OwnerMembersScreen crea asignaciones correctamente
- [ ] Asignaciones tienen routineId válido
- [ ] Asignaciones tienen clientId válido
- [ ] Status = "active" al crear
- [ ] GetClientProfileUseCase lee asignaciones del cliente

---

### ✅ 6. SESIONES DE ENTRENAMIENTO (workout_sessions/)
**Creados por**: Cliente al ejecutar rutina
**Estructura**:
```json
{
  "sessionId": "auto-generated",
  "userId": "cliente-que-entrena",
  "routineId": "rutina-ejecutada",
  "assignmentId": "asignación-relacionada",
  "date": "2026-02-24T10:30:00Z",
  "duration": 3600,
  "isCompleted": true,
  "exercises": [
    {
      "exerciseId": "ref-a-exercise",
      "sets": [
        {
          "setNumber": 1,
          "reps": 12,
          "weight": 80,
          "rpe": 8,
          "completed": true
        },
        ...
      ]
    },
    ...
  ],
  "totalVolume": 2400,
  "caloriesBurned": 450,
  "notes": "Buen entrenamiento, aumentar peso próxima vez",
  "createdAt": "timestamp"
}
```

**Verificar**:
- [ ] ActiveWorkoutScreen crea sesiones
- [ ] Sesiones tienen userId del cliente
- [ ] Sesiones tienen routineId y assignmentId
- [ ] Ejercicios con sets/reps/peso registrados
- [ ] GetClientProfileUseCase lee sesiones para estadísticas

---

### ✅ 7. PLANES DE MEMBRESÍA (membership_plans/)
**Creados por**: Dueño en MembershipPlansScreen
**Estructura**:
```json
{
  "planId": "auto-generated",
  "gymId": "gimnasio-del-dueño",
  "name": "Premium Mensual",
  "description": "Acceso completo + clases",
  "price": 599,
  "currency": "MXN",
  "duration": "monthly|quarterly|annual",
  "durationDays": 30,
  "features": [
    "Acceso ilimitado",
    "Clases grupales",
    "Nutrición personalizada"
  ],
  "isActive": true,
  "createdAt": "timestamp"
}
```

**Verificar**:
- [ ] MembershipPlansScreen CRUD funcional
- [ ] Planes tienen gymId del dueño
- [ ] Dueño solo ve planes de su gimnasio

---

## 🔄 FLUJOS DE DATOS A VERIFICAR

### Flujo 1: Admin → Dueño → Cliente
```
1. Admin crea gimnasio en gyms/
2. Admin crea dueño en gyms/{gymId}/owners/{uid} + users/{uid}
3. Dueño crea cliente en gyms/{gymId}/clients/{uid} + users/{uid}
4. Cliente ve su gimnasio en perfil
```

### Flujo 2: Dueño crea y asigna rutina
```
1. Dueño crea ejercicios custom en exercises/ (scope=gym)
2. Dueño crea rutina en TrainingForge → routines/
3. Dueño asigna rutina a cliente → assignments/
4. Cliente ve rutina asignada en AppBloc (GetClientProfileUseCase)
5. Cliente ejecuta rutina → workout_sessions/
6. Cliente ve estadísticas actualizadas
```

### Flujo 3: Empleado asigna rutina
```
1. Empleado ve lista de clientes del gimnasio
2. Empleado ve rutinas creadas por dueño
3. Empleado asigna rutina a cliente → assignments/
4. Cliente recibe notificación (futuro)
```

---

## 🧪 PRUEBAS A REALIZAR

### Test 1: Crear Gimnasio (Admin)
- [ ] Login como admin@gym-app.com
- [ ] Ir a /admin/dashboard
- [ ] Crear nuevo gimnasio "Test Gym"
- [ ] Verificar en Firestore: gyms/{gymId}

### Test 2: Crear Dueño (Admin)
- [ ] Crear dueño vinculado a "Test Gym"
- [ ] Verificar en Firestore: users/{userId} con role=owner, gymId=test-gym

### Test 3: Crear Ejercicio Custom (Dueño)
- [ ] Login con un usuario owner real del gimnasio
- [ ] Ir a /owner/exercises
- [ ] Crear ejercicio "Press Inclinado Custom"
- [ ] Verificar en Firestore: exercises/{exerciseId} con scope=gym, gymId=owner-gym

### Test 4: Crear Rutina (Dueño)
- [ ] Ir a /owner/forge
- [ ] Crear rutina "Hipertrofia Test" con 3 ejercicios
- [ ] Verificar en Firestore: routines/{routineId}
- [ ] Verificar que tiene gymId del dueño
- [ ] Verificar que exercises[] tiene 3 items

### Test 5: Asignar Rutina a Cliente (Dueño)
- [ ] Ir a /owner/members
- [ ] Seleccionar cliente "Carlos Mendoza"
- [ ] Click en "Asignar Rutina"
- [ ] Seleccionar "Hipertrofia Test"
- [ ] Confirmar con fechas y notas
- [ ] Verificar en Firestore: assignments/{assignmentId}
- [ ] Verificar que tiene routineId, clientId, assignedById y gymId

### Test 6: Cliente ve Rutina Asignada
- [ ] Login como el usuario `client` definido en `test-users.local.json`
- [ ] Ir a /client/home
- [ ] Verificar que AppBloc carga rutina asignada
- [ ] Verificar que se muestra en TrainingDashboardScreen
- [ ] Ir a /client/routine
- [ ] Verificar que se muestra en RoutineSelectionScreen

### Test 7: Cliente Ejecuta Rutina
- [ ] Click en "Comenzar Entrenamiento"
- [ ] Completar ejercicios con sets/reps/peso
- [ ] Finalizar sesión
- [ ] Verificar en Firestore: workout_sessions/{sessionId}
- [ ] Verificar que estadísticas se actualizan

---

## 🚨 PROBLEMAS COMUNES

### Problema 1: Rutinas no aparecen en diálogo de asignación
**Causa**: No hay rutinas con isActive=true en el gimnasio
**Solución**: Crear rutinas en TrainingForge primero

### Problema 2: Cliente no ve rutina asignada
**Causa**: GetClientProfileUseCase no lee assignments correctamente
**Solución**: Verificar query en AssignmentRepository

### Problema 3: Ejercicios custom no aparecen
**Causa**: Scope o gymId incorrecto
**Solución**: Verificar que scope=gym y gymId=gimnasio-del-dueño

### Problema 4: Asignación falla
**Causa**: member.id es null (no se guardó en Firestore)
**Solución**: Asegurar que _saveMemberToFirestore se ejecuta correctamente

---

## 📝 QUERIES DE FIRESTORE A VERIFICAR

### Query 1: Rutinas del gimnasio
```dart
FirebaseFirestore.instance
  .collection('routines')
  .where('gymId', isEqualTo: gymId)
  .where('isActive', isEqualTo: true)
  .get()
```

### Query 2: Asignaciones del cliente
```dart
FirebaseFirestore.instance
  .collection('assignments')
  .where('gymId', isEqualTo: gymId)
  .where('clientId', isEqualTo: userId)
  .where('status', isEqualTo: 'active')
  .get()
```

### Query 3: Ejercicios disponibles (global + gym)
```dart
// Global exercises
FirebaseFirestore.instance
  .collection('exercises')
  .where('scope', isEqualTo: 'global')
  .get()

// Gym custom exercises
FirebaseFirestore.instance
  .collection('exercises')
  .where('scope', isEqualTo: 'gym')
  .where('gymId', isEqualTo: gymId)
  .get()
```

### Query 4: Sesiones del cliente
```dart
FirebaseFirestore.instance
  .collection('workout_sessions')
  .where('userId', isEqualTo: userId)
  .orderBy('date', descending: true)
  .limit(30)
  .get()
```

---

## ✅ CHECKLIST FINAL

- [ ] Admin puede crear gimnasios
- [ ] Admin puede crear dueños vinculados a gimnasios
- [ ] Dueño puede crear ejercicios custom (scope=gym)
- [ ] Dueño puede crear rutinas en TrainingForge
- [ ] Rutinas se guardan en routines/ con gymId correcto
- [ ] Dueño puede asignar rutinas a clientes
- [ ] Asignaciones se guardan en assignments/
- [ ] Cliente ve rutinas asignadas en AppBloc
- [ ] Cliente puede ejecutar rutinas
- [ ] Sesiones se guardan en workout_sessions/
- [ ] Estadísticas se calculan correctamente
- [ ] Empleado puede asignar rutinas (mismo flujo que dueño)
- [ ] Permisos correctos en cada nivel

---

## 🎯 PRÓXIMOS PASOS

1. ✅ Implementar UI de asignación en OwnerMembersScreen
2. ⏳ Verificar que TrainingForge guarda rutinas correctamente
3. ⏳ Crear pantalla de gestión de rutinas para empleado
4. ⏳ Probar flujo completo end-to-end
5. ⏳ Agregar notificaciones cuando se asigna rutina
6. ⏳ Agregar vista de asignaciones activas para dueño
7. ⏳ Agregar métricas de cumplimiento de rutinas
