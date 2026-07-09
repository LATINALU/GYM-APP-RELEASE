import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/output_ports.dart';
import '../../../domain/value_objects/value_objects.dart';

/// Aggregated client data for the entire client UI
class ClientProfileData {
  final UserFitnessProfile fitnessProfile;
  final List<WorkoutSession> recentSessions;
  final WorkoutPlan? assignedPlan;
  final List<RoutineAssignment> activeAssignments;
  final List<WorkoutRoutine> assignedRoutines;
  final Map<String, double> muscleVolumeMap; // muscle -> volume
  final List<Map<String, dynamic>> weeklyFrequency; // [{day, count}]

  const ClientProfileData({
    required this.fitnessProfile,
    required this.recentSessions,
    this.assignedPlan,
    required this.activeAssignments,
    required this.assignedRoutines,
    required this.muscleVolumeMap,
    required this.weeklyFrequency,
  });

  /// Total volume from recent sessions
  double get totalVolume =>
      recentSessions.fold(0.0, (acc, s) => acc + s.totalVolume);

  /// Total workouts completed
  int get completedWorkouts =>
      recentSessions.where((s) => s.isCompleted).length;

  /// Today's workout from the assigned plan
  WorkoutDay? get todayWorkout {
    if (assignedPlan == null) return null;
    final today = WeekDay.fromDateTime(DateTime.now());
    try {
      return assignedPlan!.weeklySchedule.firstWhere(
        (d) => d.day == today && !d.isRestDay,
      );
    } catch (_) {
      return null;
    }
  }

  /// Next workout day from the assigned plan
  WorkoutDay? get nextWorkout {
    if (assignedPlan == null) return null;
    final todayIndex = DateTime.now().weekday - 1;
    final schedule = assignedPlan!.weeklySchedule
        .where((d) => !d.isRestDay)
        .toList();
    if (schedule.isEmpty) return null;

    // Find next day after today
    for (final day in schedule) {
      if (day.day.index > todayIndex) return day;
    }
    // Wrap around to first day of next week
    return schedule.first;
  }
}

/// Use case that fetches all client-related data in one call
class GetClientProfileUseCase {
  final AssignmentRepositoryPort _assignmentRepository;
  final RoutineRepositoryPort _routineRepository;
  final FirebaseFirestore _firestore;

  GetClientProfileUseCase({
    required AssignmentRepositoryPort assignmentRepository,
    required RoutineRepositoryPort routineRepository,
    required FirebaseFirestore firestore,
  })  : _assignmentRepository = assignmentRepository,
        _routineRepository = routineRepository,
        _firestore = firestore;

  FutureResult<ClientProfileData> execute(UserId userId, GymId gymId) async {
    try {
      // 1. Fetch workout sessions from Firestore
      final sessions = await _fetchWorkoutSessions(userId.value);

      // 2. Calculate streak from sessions
      final streakData = _calculateStreak(sessions);

      // 3. Calculate personal records
      final personalRecords = _extractPersonalRecords(sessions);

      // 4. Calculate weight history from sessions
      final weightHistory = _extractWeightHistory(sessions);

      // 5. Fetch assigned plan from Firestore routines collection
      final assignedPlan = await _fetchAssignedPlan(userId.value);

      // 6. Fetch active routine assignments
      final assignmentsResult =
          await _assignmentRepository.findActiveByClient(userId);
      final assignments =
          assignmentsResult.fold((_) => <RoutineAssignment>[], (a) => a);

      // 7. Fetch routine details for each assignment
      final routines = <WorkoutRoutine>[];
      for (final assignment in assignments) {
        final result =
            await _routineRepository.findById(assignment.routineId);
        result.fold((_) {}, (r) => routines.add(r));
      }

      // 8. Calculate muscle volume map from sessions
      final muscleVolumeMap = _calculateMuscleVolume(sessions);

      // 9. Calculate weekly frequency
      final weeklyFrequency = _calculateWeeklyFrequency(sessions);

      // 10. Build fitness profile
      final fitnessProfile = UserFitnessProfile(
        id: userId.value,
        name: 'User', // Will be overridden by AuthBloc user data
        gender: Gender.male,
        height: 175,
        currentWeight: weightHistory.isNotEmpty
            ? weightHistory.last.weight
            : 75.0,
        level: ExperienceLevel.intermediate,
        primaryGoal: FitnessGoal.buildMuscle,
        totalWorkouts: sessions.where((s) => s.isCompleted).length,
        currentStreak: streakData['current'] ?? 0,
        longestStreak: streakData['longest'] ?? 0,
        lastWorkoutDate: sessions.isNotEmpty ? sessions.first.date : null,
        weightHistory: weightHistory,
        personalRecords: personalRecords,
      );

      return right(ClientProfileData(
        fitnessProfile: fitnessProfile,
        recentSessions: sessions,
        assignedPlan: assignedPlan,
        activeAssignments: assignments,
        assignedRoutines: routines,
        muscleVolumeMap: muscleVolumeMap,
        weeklyFrequency: weeklyFrequency,
      ));
    } catch (e) {
      debugPrint('GetClientProfileUseCase error: $e');
      return left(const ServerFailure(
        message: 'No se pudieron cargar los datos del perfil del cliente.',
      ));
    }
  }

  Future<List<WorkoutSession>> _fetchWorkoutSessions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('workout_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(50)
          .get();

      final sessions = <WorkoutSession>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          // Convert Firestore Timestamps to ISO strings for fromJson
          _convertTimestamps(data);
          // Ensure required fields exist with defaults
          data['name'] ??= 'Sesión';
          data['status'] ??= 'completed';
          data['exercises'] ??= [];
          sessions.add(WorkoutSession.fromJson(data));
        } catch (e) {
          debugPrint('Skipping malformed session ${doc.id}: $e');
        }
      }
      return sessions;
    } catch (e) {
      debugPrint('Error fetching workout sessions: $e');
      return [];
    }
  }

  /// Recursively convert Firestore Timestamps to ISO strings
  void _convertTimestamps(Map<String, dynamic> data) {
    for (final key in data.keys.toList()) {
      final value = data[key];
      if (value is Timestamp) {
        data[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        _convertTimestamps(value);
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          if (value[i] is Timestamp) {
            value[i] = (value[i] as Timestamp).toDate().toIso8601String();
          } else if (value[i] is Map<String, dynamic>) {
            _convertTimestamps(value[i]);
          }
        }
      }
    }
  }

  Future<WorkoutPlan?> _fetchAssignedPlan(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('routines')
          .where('assigned_to', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      final structure = data['structure'] as Map<String, dynamic>?;
      if (structure == null) return null;

      List<WorkoutDay> weeklySchedule = [];
      structure.forEach((dayName, steps) {
        final day = WeekDay.values.firstWhere(
          (d) => d.name == dayName,
          orElse: () => WeekDay.monday,
        );
        final exercises = (steps as List).asMap().entries.map((entry) {
          final step = entry.value as Map<String, dynamic>;
          return PlannedExercise(
            exerciseId: step['exerciseId'] ?? 'unknown',
            exerciseName: step['exerciseName'] ?? 'Ejercicio',
            muscleGroup: step['muscleGroup'] ?? 'General',
            targetSets: step['sets'] ?? 3,
            targetReps: '${step['reps'] ?? 10}',
            suggestedWeight: step['weight']?.toDouble(),
            notes: step['notes'],
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

      return WorkoutPlan(
        id: snapshot.docs.first.id,
        name: data['name'] ?? 'Mi Plan Personalizado',
        description: data['description'] ?? 'Plan diseñado por tu coach',
        weeklySchedule: weeklySchedule,
        difficulty: PlanDifficulty.intermediate,
        focus: PlanFocus.hypertrophy,
        createdAt: (data['created_at'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        isActive: true,
      );
    } catch (e) {
      debugPrint('Error fetching assigned plan: $e');
      return null;
    }
  }

  Map<String, int> _calculateStreak(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return {'current': 0, 'longest': 0};

    final completedDates = sessions
        .where((s) => s.isCompleted)
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (completedDates.isEmpty) return {'current': 0, 'longest': 0};

    // Current streak: count consecutive days from today backwards
    int currentStreak = 0;
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    DateTime checkDate = today;

    // Allow 1 day gap (yesterday counts)
    if (completedDates.first.difference(today).inDays.abs() <= 1) {
      for (final date in completedDates) {
        if (checkDate.difference(date).inDays <= 1) {
          currentStreak++;
          checkDate = date;
        } else {
          break;
        }
      }
    }

    // Longest streak
    int longestStreak = 0;
    int tempStreak = 1;
    for (int i = 0; i < completedDates.length - 1; i++) {
      if (completedDates[i].difference(completedDates[i + 1]).inDays <= 1) {
        tempStreak++;
      } else {
        longestStreak =
            tempStreak > longestStreak ? tempStreak : longestStreak;
        tempStreak = 1;
      }
    }
    longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

    return {
      'current': currentStreak,
      'longest': longestStreak,
    };
  }

  Map<String, PersonalRecord> _extractPersonalRecords(
      List<WorkoutSession> sessions) {
    final prs = <String, PersonalRecord>{};

    for (final session in sessions) {
      for (final exercise in session.exercises) {
        final bestSet = exercise.bestSet;
        if (bestSet == null) continue;

        final existing = prs[exercise.exerciseId];
        if (existing == null || bestSet.weight > existing.weight) {
          prs[exercise.exerciseId] = PersonalRecord(
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.exerciseName,
            weight: bestSet.weight,
            reps: bestSet.reps,
            date: session.date,
          );
        }
      }
    }

    return prs;
  }

  List<WeightEntry> _extractWeightHistory(List<WorkoutSession> sessions) {
    return sessions
        .where((s) => s.bodyWeight != null)
        .map((s) => WeightEntry(date: s.date, weight: s.bodyWeight!))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Map<String, double> _calculateMuscleVolume(
      List<WorkoutSession> sessions) {
    final volumeMap = <String, double>{};
    final recentSessions = sessions.take(20); // Last 20 sessions

    for (final session in recentSessions) {
      for (final exercise in session.exercises) {
        final group = exercise.muscleGroup;
        volumeMap[group] = (volumeMap[group] ?? 0) + exercise.totalVolume;
      }
    }

    return volumeMap;
  }

  List<Map<String, dynamic>> _calculateWeeklyFrequency(
      List<WorkoutSession> sessions) {
    final dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final counts = List.filled(7, 0);

    // Count workouts per day of week from last 4 weeks
    final fourWeeksAgo =
        DateTime.now().subtract(const Duration(days: 28));
    for (final session in sessions) {
      if (session.date.isAfter(fourWeeksAgo) && session.isCompleted) {
        counts[session.date.weekday - 1]++;
      }
    }

    return List.generate(
        7,
        (i) => {
              'day': dayNames[i],
              'count': counts[i],
            });
  }

}
