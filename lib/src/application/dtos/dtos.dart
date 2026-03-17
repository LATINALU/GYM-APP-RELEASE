import '../../domain/entities/entities.dart';

/// User DTO for presentation layer
class UserDTO {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String initials;
  final String role;
  final String roleDisplayName;
  final String? phone;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  const UserDTO({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.initials,
    required this.role,
    required this.roleDisplayName,
    this.phone,
    required this.createdAt,
    this.lastLoginAt,
    required this.isActive,
  });

  factory UserDTO.fromEntity(User user) {
    return UserDTO(
      id: user.id.value,
      email: user.email.value,
      firstName: user.name.firstName,
      lastName: user.name.lastName,
      fullName: user.displayName,
      initials: user.initials,
      role: user.role.toValue(),
      roleDisplayName: user.role.displayName,
      phone: user.phone?.value,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      isActive: user.isActive,
    );
  }
}

/// Routine DTO for presentation layer
class RoutineDTO {
  final String id;
  final String name;
  final String? description;
  final String difficulty;
  final String difficultyDisplayName;
  final int exerciseCount;
  final int estimatedDurationMinutes;
  final String durationDisplay;
  final List<ExerciseDTO> exercises;
  final DateTime createdAt;
  final bool isActive;

  const RoutineDTO({
    required this.id,
    required this.name,
    this.description,
    required this.difficulty,
    required this.difficultyDisplayName,
    required this.exerciseCount,
    required this.estimatedDurationMinutes,
    required this.durationDisplay,
    required this.exercises,
    required this.createdAt,
    required this.isActive,
  });

  factory RoutineDTO.fromEntity(WorkoutRoutine routine) {
    return RoutineDTO(
      id: routine.id.value,
      name: routine.name,
      description: routine.description,
      difficulty: routine.difficulty.name,
      difficultyDisplayName: routine.difficulty.displayName,
      exerciseCount: routine.exerciseCount,
      estimatedDurationMinutes: routine.estimatedDurationMinutes,
      durationDisplay: routine.durationDisplay,
      exercises: routine.exercises.map(ExerciseDTO.fromEntity).toList(),
      createdAt: routine.createdAt,
      isActive: routine.isActive,
    );
  }
}

/// Exercise DTO for presentation layer
class ExerciseDTO {
  final String id;
  final String name;
  final String? description;
  final String primaryMuscle;
  final String primaryMuscleDisplayName;
  final List<String> secondaryMuscles;
  final int sets;
  final int reps;
  final String setsRepsDisplay;
  final int? restSeconds;
  final String restDisplay;
  final String? notes;
  final String? videoUrl;

  const ExerciseDTO({
    required this.id,
    required this.name,
    this.description,
    required this.primaryMuscle,
    required this.primaryMuscleDisplayName,
    required this.secondaryMuscles,
    required this.sets,
    required this.reps,
    required this.setsRepsDisplay,
    this.restSeconds,
    required this.restDisplay,
    this.notes,
    this.videoUrl,
  });

  factory ExerciseDTO.fromEntity(Exercise exercise) {
    return ExerciseDTO(
      id: exercise.id.value,
      name: exercise.name,
      description: exercise.description,
      primaryMuscle: exercise.primaryMuscle.name,
      primaryMuscleDisplayName: exercise.primaryMuscle.displayName,
      secondaryMuscles: exercise.secondaryMuscles.map((m) => m.displayName).toList(),
      sets: exercise.sets,
      reps: exercise.reps,
      setsRepsDisplay: exercise.setsRepsDisplay,
      restSeconds: exercise.restSeconds,
      restDisplay: exercise.restDisplay,
      notes: exercise.notes,
      videoUrl: exercise.videoUrl,
    );
  }
}

/// Assignment DTO for presentation layer
class AssignmentDTO {
  final String id;
  final String routineId;
  final String clientId;
  final String assignedById;
  final DateTime assignedAt;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final String statusDisplayName;
  final String? notes;
  final bool isActive;
  final int? daysRemaining;

  const AssignmentDTO({
    required this.id,
    required this.routineId,
    required this.clientId,
    required this.assignedById,
    required this.assignedAt,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.statusDisplayName,
    this.notes,
    required this.isActive,
    this.daysRemaining,
  });

  factory AssignmentDTO.fromEntity(RoutineAssignment assignment) {
    return AssignmentDTO(
      id: assignment.id.value,
      routineId: assignment.routineId.value,
      clientId: assignment.clientId.value,
      assignedById: assignment.assignedById.value,
      assignedAt: assignment.assignedAt,
      startDate: assignment.startDate,
      endDate: assignment.endDate,
      status: assignment.status.name,
      statusDisplayName: assignment.status.displayName,
      notes: assignment.notes,
      isActive: assignment.isActive,
      daysRemaining: assignment.daysRemaining,
    );
  }
}

/// CheckIn DTO for presentation layer
class CheckInDTO {
  final String id;
  final String clientId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? registeredById;
  final String durationDisplay;
  final bool isActive;
  final String? notes;

  const CheckInDTO({
    required this.id,
    required this.clientId,
    required this.checkInTime,
    this.checkOutTime,
    this.registeredById,
    required this.durationDisplay,
    required this.isActive,
    this.notes,
  });

  factory CheckInDTO.fromEntity(CheckIn checkIn) {
    return CheckInDTO(
      id: checkIn.id.value,
      clientId: checkIn.clientId.value,
      checkInTime: checkIn.checkInTime,
      checkOutTime: checkIn.checkOutTime,
      registeredById: checkIn.registeredById?.value,
      durationDisplay: checkIn.durationDisplay,
      isActive: checkIn.isActive,
      notes: checkIn.notes,
    );
  }
}
