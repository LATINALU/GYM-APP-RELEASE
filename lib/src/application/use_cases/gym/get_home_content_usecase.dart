import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/output_ports.dart';
import '../../../domain/value_objects/value_objects.dart';

class GetHomeContentUseCase {
  final GymRepositoryPort _gymRepository;
  final AssignmentRepositoryPort _assignmentRepository;
  final RoutineRepositoryPort _routineRepository;

  GetHomeContentUseCase({
    required GymRepositoryPort gymRepository,
    required AssignmentRepositoryPort assignmentRepository,
    required RoutineRepositoryPort routineRepository,
  })  : _gymRepository = gymRepository,
        _assignmentRepository = assignmentRepository,
        _routineRepository = routineRepository;

  FutureResult<HomeContent> execute(UserId userId, GymId gymId) async {
    try {
      // 1. Get Gym Info
      final gymResult = await _gymRepository.findById(gymId);
      final gym = gymResult.fold((f) => null, (g) => g);

      // 2. Get Assigned Plan from 'routines' collection (as saved by Level 2 RoutineBuilder)
      WorkoutPlan? assignedPlan;
      try {
        final planSnapshot = await FirebaseFirestore.instance
            .collection('routines')
            .where('assigned_to', isEqualTo: userId.value)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();

        if (planSnapshot.docs.isNotEmpty) {
          final data = planSnapshot.docs.first.data();
          final structure = data['structure'] as Map<String, dynamic>;
          
          List<WorkoutDay> weeklySchedule = [];
          structure.forEach((dayName, steps) {
            final day = WeekDay.values.firstWhere((d) => d.name == dayName, orElse: () => WeekDay.monday);
            final exercises = (steps as List).asMap().entries.map((entry) {
              return PlannedExercise(
                exerciseId: entry.value['exerciseId'],
                exerciseName: entry.value['exerciseName'],
                muscleGroup: 'General', 
                targetSets: entry.value['sets'] ?? 3,
                targetReps: entry.value['reps'] ?? '10',
                order: entry.key,
              );
            }).toList();

            weeklySchedule.add(WorkoutDay(
              day: day,
              name: day.displayName,
              exercises: exercises,
              estimatedDuration: 60,
            ));
          });

          assignedPlan = WorkoutPlan(
            id: planSnapshot.docs.first.id,
            name: 'Mi Plan Personalizado',
            description: 'Plan diseñado por tu coach',
            weeklySchedule: weeklySchedule,
            difficulty: PlanDifficulty.intermediate,
            focus: PlanFocus.hypertrophy,
            createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isActive: true,
          );
        }
      } catch (e) {
        debugPrint('Error fetching assigned plan: $e');
      }

      // 3. Get Active Assignments (Legacy/Specific routines)
      final assignmentsResult = await _assignmentRepository.findActiveByClient(userId);
      final List<RoutineAssignment> assignments = assignmentsResult.fold((f) => [], (a) => a);

      final List<WorkoutRoutine> routines = [];
      for (var assignment in assignments) {
        final routineResult = await _routineRepository.findById(assignment.routineId);
        routineResult.fold((f) => null, (r) => routines.add(r));
      }

      // 4. Get catalog routines
      final allRoutinesResult = await _routineRepository.findAllActive();
      final quickRoutines = allRoutinesResult.fold((f) => <WorkoutRoutine>[], (r) => r.take(5).toList());

      return right(HomeContent(
        gymName: gym?.name ?? 'Quantum Fit',
        activeRoutines: routines,
        quickRoutines: quickRoutines,
        assignedPlan: assignedPlan,
        caloriesBurnedToday: 580.0,
        workoutsCompletedThisWeek: 4,
        weeklyVolumeTons: 12.8,
        trainingStreakDays: 5,
      ));
    } catch (e) {
      return left(ServerFailure(message: 'Error al cargar contenido de inicio: $e'));
    }
  }
}

