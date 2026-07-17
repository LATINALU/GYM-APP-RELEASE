import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/data/routine_seeds.dart';
import '../../domain/ports/input/manage_routine_usecase_port.dart';
import '../../domain/value_objects/value_objects.dart';

/// Resultado de una operación de mantenimiento de rutinas
class RoutineMaintenanceResult {
  final int affected;
  final String message;

  const RoutineMaintenanceResult({
    required this.affected,
    required this.message,
  });
}

/// Caso de uso: crear las rutinas predefinidas ([RoutineSeeds]) construidas
/// con ejercicios del dataset. Idempotente: omite las que ya existen por
/// nombre. Reutiliza [ManageRoutineUseCasePort] (validación de permisos,
/// resolución de plantillas y propagación de media incluidas).
class SeedRoutinesUseCase {
  final ManageRoutineUseCasePort _manageRoutines;

  SeedRoutinesUseCase({required ManageRoutineUseCasePort manageRoutines})
      : _manageRoutines = manageRoutines;

  FutureResult<RoutineMaintenanceResult> execute(UserId createdBy) async {
    try {
      final existingResult = await _manageRoutines.getAllRoutines();
      final existingNames = existingResult
          .getOrElse(() => [])
          .map((r) => r.name.toLowerCase())
          .toSet();

      var created = 0;
      final errors = <String>[];
      for (final seed in RoutineSeeds.all) {
        if (existingNames.contains(seed.name.toLowerCase())) continue;

        final result = await _manageRoutines.createRoutine(CreateRoutineCommand(
          name: seed.name,
          description: seed.description,
          difficulty: seed.difficulty,
          exercises: seed.exercises,
          createdBy: createdBy,
        ));
        result.fold(
          (f) => errors.add('${seed.name}: ${f.message}'),
          (_) => created++,
        );
      }

      if (errors.isNotEmpty && created == 0) {
        return left(ServerFailure(
          message: 'No se pudo crear ninguna rutina: ${errors.first}',
        ));
      }

      final message = created == 0
          ? 'Las rutinas predefinidas ya existen'
          : errors.isEmpty
              ? 'Se crearon $created rutinas predefinidas'
              : 'Se crearon $created rutinas; ${errors.length} fallaron';
      return right(RoutineMaintenanceResult(affected: created, message: message));
    } catch (e) {
      return left(ServerFailure(message: 'Error al crear rutinas: $e'));
    }
  }
}
