import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../../domain/ports/output/routine_repository_port.dart';

/// Repositorio en memoria para pruebas sin Backend/Firebase
class InMemoryRoutineRepository implements RoutineRepositoryPort {
  final List<WorkoutRoutine> _routines = [];

  @override
  FutureVoidResult save(WorkoutRoutine routine) async {
    final index = _routines.indexWhere((r) => r.id == routine.id);
    if (index >= 0) {
      _routines[index] = routine;
    } else {
      _routines.add(routine);
    }
    return right(null);
  }

  @override
  FutureResult<List<WorkoutRoutine>> findAllActive() async {
    return right(_routines.where((r) => r.isActive).toList());
  }

  @override
  FutureResult<List<WorkoutRoutine>> findByDifficulty(DifficultyLevel difficulty) async {
    final filtered = _routines
        .where((r) => r.isActive && r.difficulty == difficulty)
        .toList();
    return right(filtered);
  }

  @override
  FutureResult<WorkoutRoutine> findById(RoutineId id) async {
    try {
      final routine = _routines.firstWhere((r) => r.id == id);
      return right(routine);
    } catch (e) {
      return left(const ValidationFailure(message: 'Rutina no encontrada'));
    }
  }

  @override
  FutureVoidResult delete(RoutineId id) async {
    _routines.removeWhere((r) => r.id == id);
    return right(null);
  }

  @override
  FutureResult<List<WorkoutRoutine>> findByCreator(UserId creatorId) async {
    return right(_routines.where((r) => r.createdBy == creatorId).toList());
  }
}
