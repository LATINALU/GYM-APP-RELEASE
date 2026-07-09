# 🔧 PLAN DE REPARACIÓN INMEDIATA - QUANTUM GYM APP

## 🎯 OBJETIVO
Completar las 4 funcionalidades críticas que están rotas y preparar la app para producción.

---

## 🚨 REPARACIONES CRÍTICAS (HACER AHORA)

### 1️⃣ CONECTAR MinimalWorkoutScreen A DATOS REALES
**Prioridad**: 🔴 CRÍTICA
**Tiempo estimado**: 2 horas
**Archivo**: `lib/src/presentation/screens/workout/minimal_workout_screen.dart`

**Problema actual**:
```dart
// TODO: Wire this screen to load exercises from AppBloc assigned routine
final List<_ExerciseData> _exercises = [];
```

**Solución**:
```dart
// 1. Agregar BlocBuilder para AppBloc
BlocBuilder<AppBloc, AppState>(
  builder: (context, state) {
    if (state is AppLoaded && state.assignedPlan != null) {
      final routine = state.assignedPlan!;
      final exercises = routine.exercises.map((ex) => _ExerciseData(
        name: ex.name,
        sets: '${ex.sets}x${ex.reps}',
        prescribedSets: '${ex.sets}x${ex.reps} (RPE ${ex.targetRPE ?? 8})',
        weight: '${ex.recommendedWeight ?? 0}kg',
        isCompleted: false,
        trainerNotes: ex.notes,
      )).toList();
      
      return _buildExerciseList(exercises);
    }
    return Center(child: Text('No hay rutina asignada'));
  },
)
```

**Pasos**:
1. Importar AppBloc
2. Envolver UI en BlocBuilder
3. Mapear ejercicios de rutina a _ExerciseData
4. Mostrar mensaje si no hay rutina asignada

---

### 2️⃣ GUARDAR SESIONES EN FIRESTORE
**Prioridad**: 🔴 CRÍTICA
**Tiempo estimado**: 3 horas
**Archivo**: `lib/src/presentation/screens/workout/active_workout_screen.dart`

**Problema actual**:
```dart
// TODO: Save to storage
Navigator.of(context).pop(completedSession);
```

**Solución**:
```dart
Future<void> _finishWorkout() async {
  if (_exercises.isEmpty) return;
  
  setState(() => _isLoading = true);
  
  try {
    final auth = AuthStateNotifier.instance;
    final userId = auth.profile?.uid;
    
    if (userId == null) throw Exception('Usuario no autenticado');
    
    // Calcular estadísticas
    final totalVolume = _exercises.fold<double>(0, (sum, ex) {
      return sum + ex.sets.fold<double>(0, (s, set) {
        return s + (set.weight * set.reps);
      });
    });
    
    final duration = DateTime.now().difference(_startTime).inSeconds;
    
    // Guardar en Firestore
    await FirebaseFirestore.instance.collection('workout_sessions').add({
      'userId': userId,
      'routineId': widget.routineId,
      'assignmentId': widget.assignmentId,
      'date': DateTime.now().toIso8601String(),
      'duration': duration,
      'isCompleted': true,
      'exercises': _exercises.map((ex) => {
        'exerciseId': ex.id,
        'name': ex.name,
        'sets': ex.sets.map((set) => {
          'setNumber': set.setNumber,
          'reps': set.reps,
          'weight': set.weight,
          'rpe': set.rpe,
          'completed': set.completed,
        }).toList(),
      }).toList(),
      'totalVolume': totalVolume,
      'caloriesBurned': (totalVolume * 0.18).round(), // Estimación
      'notes': _notesController.text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Actualizar AppBloc
    context.read<AppBloc>().add(WorkoutCompleted(completedSession));
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Entrenamiento guardado exitosamente'),
          backgroundColor: QuantumColors.matrixCyan,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

**Pasos**:
1. Agregar imports de Firestore y AuthStateNotifier
2. Calcular totalVolume y calorías
3. Guardar en collection `workout_sessions/`
4. Disparar evento WorkoutCompleted en AppBloc
5. Mostrar feedback al usuario

---

### 3️⃣ VALIDACIÓN DE QR EN STAFF SCANNER
**Prioridad**: 🔴 CRÍTICA
**Tiempo estimado**: 2 horas
**Archivo**: `lib/src/presentation/screens/staff/staff_qr_scanner_screen.dart`

**Problema actual**:
```dart
// TODO: Call validateQRCheckIn Cloud Function
await Future.delayed(const Duration(seconds: 1));
```

**Solución**:
```dart
Future<void> _handleQRCode(String code) async {
  if (_lastScannedCode == code) return;
  
  setState(() {
    _isProcessing = true;
    _lastScannedCode = code;
  });
  
  try {
    // Validar formato del QR
    if (!code.startsWith('QUANTUM_')) {
      throw Exception('QR inválido');
    }
    
    final userId = code.replaceFirst('QUANTUM_', '');
    
    // Verificar que el usuario existe
    final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();
    
    if (!userDoc.exists) {
      throw Exception('Usuario no encontrado');
    }
    
    final userData = userDoc.data()!;
    final userName = userData['displayName'] ?? 'Usuario';
    final membershipStatus = userData['membershipStatus'] ?? 'pending';
    
    // Verificar membresía activa
    if (membershipStatus != 'active') {
      throw Exception('Membresía no activa');
    }
    
    // Registrar check-in
    final auth = AuthStateNotifier.instance;
    final gymId = auth.profile?.gymId?.value;
    
    await FirebaseFirestore.instance.collection('check_ins').add({
      'userId': userId,
      'gymId': gymId,
      'checkedInBy': auth.profile?.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'method': 'qr_scan',
    });
    
    if (mounted) {
      setState(() {
        _scanResult = 'success';
        _userName = userName;
      });
      
      // Auto-reset después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _scanResult = null;
            _userName = null;
            _lastScannedCode = null;
          });
        }
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _scanResult = 'error';
        _errorMessage = e.toString();
      });
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _scanResult = null;
            _errorMessage = null;
            _lastScannedCode = null;
          });
        }
      });
    }
  } finally {
    if (mounted) setState(() => _isProcessing = false);
  }
}
```

**Pasos**:
1. Validar formato del QR
2. Verificar usuario en Firestore
3. Verificar membresía activa
4. Guardar check-in en collection `check_ins/`
5. Mostrar feedback visual (success/error)

---

### 4️⃣ ASIGNACIÓN DE RUTINAS PARA EMPLEADO
**Prioridad**: 🔴 CRÍTICA
**Tiempo estimado**: 1 hora
**Archivo**: `lib/src/presentation/screens/staff/routine_management_screen.dart`

**Problema actual**:
```dart
void _handleAssign() {
  // TODO: Implement actual assignment logic
  showDialog(...);
}
```

**Solución**:
```dart
// Reutilizar código de OwnerMembersScreen
void _handleAssign() async {
  final auth = AuthStateNotifier.instance;
  final gymId = auth.profile?.gymId?.value;
  
  if (gymId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: No se pudo obtener el ID del gimnasio')),
    );
    return;
  }
  
  // Fetch available routines
  final routinesSnapshot = await FirebaseFirestore.instance
    .collection('workout_routines')
    .where('gymId', isEqualTo: gymId)
    .where('isActive', isEqualTo: true)
    .get();
  
  if (routinesSnapshot.docs.isEmpty) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sin rutinas disponibles'),
        content: const Text('No hay rutinas activas en el gimnasio.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
    return;
  }
  
  // Mostrar diálogo de selección (copiar de OwnerMembersScreen)
  _showRoutineSelectionDialog(routinesSnapshot.docs);
}
```

**Pasos**:
1. Copiar método `_showAssignRoutineDialog` de OwnerMembersScreen
2. Adaptar para usar cliente seleccionado
3. Verificar permisos de empleado
4. Guardar asignación en Firestore

---

## ⚠️ REPARACIONES MODERADAS (HACER DESPUÉS)

### 5️⃣ SEPARAR DATOS MOCK DE REALES
**Tiempo estimado**: 4 horas

**Archivos afectados**:
- `community_feed_screen.dart`
- `leaderboard_screen.dart`
- `achievements_screen.dart`
- `training_forge_store.dart`

**Solución**:
```dart
// Agregar flag de desarrollo
class AppConfig {
  static const bool isDevelopment = bool.fromEnvironment('DEVELOPMENT', defaultValue: false);
}

// Usar en pantallas
final posts = AppConfig.isDevelopment 
  ? _getMockPosts() 
  : await _fetchPostsFromFirestore();
```

---

### 6️⃣ MEJORAR MANEJO DE ERRORES
**Tiempo estimado**: 3 horas

**Implementar**:
```dart
// Error boundary global
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  
  @override
  Widget build(BuildContext context) {
    return ErrorWidget.builder = (FlutterErrorDetails details) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Algo salió mal'),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Volver'),
              ),
            ],
          ),
        ),
      );
    };
    return child;
  }
}
```

---

### 7️⃣ AGREGAR VALIDACIONES
**Tiempo estimado**: 2 horas

**Validaciones necesarias**:
```dart
// Antes de asignar rutina
bool _validateAssignment(Client client, Routine routine) {
  // 1. Verificar membresía activa
  if (client.membershipStatus != MembershipStatus.active) {
    throw ValidationException('Cliente no tiene membresía activa');
  }
  
  // 2. Verificar nivel vs dificultad
  if (client.level == ExperienceLevel.beginner && 
      routine.difficulty == Difficulty.advanced) {
    throw ValidationException('Rutina muy avanzada para el nivel del cliente');
  }
  
  // 3. Verificar fechas
  if (startDate.isAfter(endDate)) {
    throw ValidationException('Fecha de inicio debe ser anterior a fecha de fin');
  }
  
  // 4. Verificar que rutina tenga ejercicios
  if (routine.exercises.isEmpty) {
    throw ValidationException('La rutina no tiene ejercicios');
  }
  
  return true;
}
```

---

### 8️⃣ IMPLEMENTAR PAGINACIÓN
**Tiempo estimado**: 3 horas

**Ejemplo**:
```dart
class PaginatedMembersList extends StatefulWidget {
  @override
  State<PaginatedMembersList> createState() => _PaginatedMembersListState();
}

class _PaginatedMembersListState extends State<PaginatedMembersList> {
  final _members = <Member>[];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadMore();
  }
  
  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() => _isLoading = true);
    
    Query query = FirebaseFirestore.instance
      .collection('gyms')
      .doc(gymId)
      .collection('members')
      .limit(20);
    
    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }
    
    final snapshot = await query.get();
    
    if (snapshot.docs.isEmpty) {
      setState(() {
        _hasMore = false;
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _members.addAll(snapshot.docs.map((doc) => Member.fromFirestore(doc)));
      _lastDocument = snapshot.docs.last;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _members.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _members.length) {
          _loadMore();
          return Center(child: CircularProgressIndicator());
        }
        return MemberTile(member: _members[index]);
      },
    );
  }
}
```

---

## 🔒 SEGURIDAD (CRÍTICO)

### FIRESTORE RULES
**Crear archivo**: `firestore.rules`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    function isAdmin() {
      return isAuthenticated() && getUserData().role.type == 'admin';
    }
    
    function isOwner() {
      return isAuthenticated() && getUserData().role.type == 'owner';
    }
    
    function isEmployee() {
      return isAuthenticated() && getUserData().role.type == 'employee';
    }
    
    function isClient() {
      return isAuthenticated() && getUserData().role.type == 'client';
    }
    
    function belongsToSameGym(gymId) {
      return getUserData().gymId == gymId;
    }
    
    // Gyms - Solo admin puede crear
    match /gyms/{gymId} {
      allow read: if isAuthenticated();
      allow create: if isAdmin();
      allow update, delete: if isAdmin() || (isOwner() && belongsToSameGym(gymId));
      
      // Members sub-collection
      match /members/{memberId} {
        allow read: if isAuthenticated() && belongsToSameGym(gymId);
        allow write: if isOwner() && belongsToSameGym(gymId);
      }
    }
    
    // Users
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAdmin() || isOwner();
      allow update: if isAdmin() || userId == request.auth.uid;
      allow delete: if isAdmin();
    }
    
    // Exercises
    match /exercises/{exerciseId} {
      allow read: if isAuthenticated();
      allow create: if isAdmin() || isOwner();
      allow update, delete: if isAdmin() || 
        (isOwner() && resource.data.createdBy == request.auth.uid);
    }
    
    // Workout Routines - Solo dueño de su gym
    match /workout_routines/{routineId} {
      allow read: if isAuthenticated();
      allow create: if isOwner() && 
        request.resource.data.gymId == getUserData().gymId;
      allow update, delete: if isOwner() && 
        resource.data.gymId == getUserData().gymId;
    }
    
    // Routine Assignments - Dueño/Empleado asigna, Cliente lee las suyas
    match /routine_assignments/{assignmentId} {
      allow read: if isAuthenticated() && (
        resource.data.clientId == request.auth.uid ||
        isOwner() ||
        isEmployee()
      );
      allow create: if (isOwner() || isEmployee()) &&
        belongsToSameGym(get(/databases/$(database)/documents/users/$(request.resource.data.clientId)).data.gymId);
      allow update, delete: if isOwner() || isEmployee();
    }
    
    // Workout Sessions - Solo el cliente puede crear/leer las suyas
    match /workout_sessions/{sessionId} {
      allow read: if isAuthenticated() && (
        resource.data.userId == request.auth.uid ||
        isOwner() ||
        isEmployee()
      );
      allow create: if isClient() && 
        request.resource.data.userId == request.auth.uid;
      allow update: if resource.data.userId == request.auth.uid;
      allow delete: if isAdmin();
    }
    
    // Check-ins
    match /check_ins/{checkinId} {
      allow read: if isAuthenticated();
      allow create: if isEmployee() || isOwner();
      allow delete: if isAdmin();
    }
    
    // Membership Plans
    match /membership_plans/{planId} {
      allow read: if isAuthenticated();
      allow write: if isOwner() && 
        resource.data.gymId == getUserData().gymId;
    }
  }
}
```

**Desplegar**:
```bash
firebase deploy --only firestore:rules
```

---

## 📊 CHECKLIST DE VERIFICACIÓN

### Antes de desplegar:
- [ ] Reparación 1: MinimalWorkoutScreen conectado ✅
- [ ] Reparación 2: Sesiones se guardan en Firestore ✅
- [ ] Reparación 3: QR Scanner valida correctamente ✅
- [ ] Reparación 4: Empleado puede asignar rutinas ✅
- [ ] Firestore Rules desplegadas ✅
- [ ] Datos mock separados de reales ✅
- [ ] Manejo de errores mejorado ✅
- [ ] Validaciones implementadas ✅
- [ ] Paginación en listas grandes ✅
- [ ] Tests básicos pasando ✅

---

## 🚀 ORDEN DE EJECUCIÓN

1. **DÍA 1** (6-8 horas)
   - Reparación 1: MinimalWorkoutScreen
   - Reparación 2: Guardar sesiones
   - Reparación 3: QR Scanner

2. **DÍA 2** (4-6 horas)
   - Reparación 4: Asignación empleado
   - Firestore Rules
   - Separar datos mock

3. **DÍA 3** (4-6 horas)
   - Manejo de errores
   - Validaciones
   - Paginación

4. **DÍA 4** (Testing y ajustes)
   - Pruebas end-to-end
   - Corrección de bugs
   - Documentación

---

## ✅ CRITERIOS DE ÉXITO

- ✅ Cliente puede ver y ejecutar rutinas asignadas
- ✅ Sesiones se guardan correctamente en Firestore
- ✅ Empleado puede escanear QR y registrar check-ins
- ✅ Empleado puede asignar rutinas a clientes
- ✅ Firestore Rules protegen los datos
- ✅ No hay datos mock en producción
- ✅ Errores se muestran al usuario
- ✅ Validaciones previenen datos incorrectos

---

**LISTO PARA COMENZAR** 🚀
