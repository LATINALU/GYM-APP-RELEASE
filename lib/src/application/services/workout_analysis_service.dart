import 'package:cloud_firestore/cloud_firestore.dart';

/// Workout Analysis Service - GYM-APP
/// Advanced workout metrics: frequency, consistency, muscle balance, PRs
class WorkoutAnalysisService {
  final FirebaseFirestore _firestore;
  WorkoutAnalysisService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const List<String> _weekdayLabels = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];
  static const List<String> _monthLabels = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  /// Get comprehensive workout analytics
  Future<Map<String, dynamic>> getAnalytics(String userId) async {
    try {
      final sessionDocs = await _fetchRecentSessions(
        userId: userId,
        limit: 180,
      );
      if (sessionDocs.isEmpty) return _emptyAnalytics();

      final sessions = sessionDocs.map(_buildSessionMetric).toList();
      final uniqueWorkoutDays = _uniqueWorkoutDays(sessions);

      final totalWorkouts = sessions.length;
      final totalDurationMinutes = sessions.fold<double>(
        0,
        (acc, session) => acc + session.durationMinutes,
      );
      final totalVolume = sessions.fold<double>(
        0,
        (acc, session) => acc + session.totalVolume,
      );

      final streak = _calculateStreak(uniqueWorkoutDays);
      final weeklyAverage = _calculateWeeklyAverage(
        totalWorkouts: totalWorkouts,
        uniqueDays: uniqueWorkoutDays,
      );
      final consistencyScore = _calculateConsistencyScore(uniqueWorkoutDays);

      final monthlyTrend = _buildMonthlyTrendFromSessions(sessions, months: 6);
      final improvementRate = _calculateImprovementRate(monthlyTrend);

      final mostTrainedMuscle = _selectTopLabel(
        sessions.expand((session) => session.muscleCounts.entries).toList(),
        pickMost: true,
      );
      final leastTrainedMuscle = _selectTopLabel(
        sessions.expand((session) => session.muscleCounts.entries).toList(),
        pickMost: false,
      );
      final favoriteExercise = _selectTopLabel(
        sessions.expand((session) => session.exerciseCounts.entries).toList(),
        pickMost: true,
      );

      return {
        'totalWorkouts': totalWorkouts,
        'totalHours': totalDurationMinutes / 60,
        'avgDuration':
            totalWorkouts == 0 ? 0.0 : (totalDurationMinutes / totalWorkouts),
        'currentStreak': streak.current,
        'longestStreak': streak.longest,
        'avgWorkoutsPerWeek': weeklyAverage,
        'totalVolume': totalVolume,
        'avgVolumePerSession':
            totalWorkouts == 0 ? 0.0 : (totalVolume / totalWorkouts),
        'mostTrainedMuscle': mostTrainedMuscle,
        'leastTrainedMuscle': leastTrainedMuscle,
        'favoriteExercise': favoriteExercise,
        'consistencyScore': consistencyScore,
        'improvementRate': improvementRate,
      };
    } catch (e) {
      throw Exception('No se pudo cargar analytics de entrenamiento: $e');
    }
  }

  /// Get personal records
  Future<List<Map<String, dynamic>>> getPersonalRecords(String userId) async {
    try {
      final snap =
          await _firestore
              .collection('personal_records')
              .where('userId', isEqualTo: userId)
              .get();

      if (snap.docs.isNotEmpty) {
        final records =
            snap.docs
                .map((doc) => _normalizePersonalRecord(doc.data()))
                .where((record) => record['exercise'].toString().isNotEmpty)
                .toList()
              ..sort(
                (a, b) => (_toDate(b['date']) ?? DateTime(1970)).compareTo(
                  _toDate(a['date']) ?? DateTime(1970),
                ),
              );
        return records;
      }

      final sessionDocs = await _fetchRecentSessions(
        userId: userId,
        limit: 240,
      );
      if (sessionDocs.isEmpty) return const [];

      final sessions = sessionDocs.map(_buildSessionMetric).toList();
      return _buildPersonalRecordsFromSessions(sessions);
    } catch (e) {
      throw Exception('No se pudieron cargar los récords personales: $e');
    }
  }

  /// Get workout frequency by day of week
  Future<Map<String, int>> getFrequencyByDay(String userId) async {
    try {
      final docs = await _fetchRecentSessions(userId: userId, limit: 120);
      final frequency = <String, int>{
        for (final label in _weekdayLabels) label: 0,
      };

      for (final doc in docs) {
        final date =
            _toDate(doc.data()['date']) ?? _toDate(doc.data()['createdAt']);
        if (date == null) continue;
        final label = _weekdayLabels[date.weekday - 1];
        frequency[label] = (frequency[label] ?? 0) + 1;
      }

      return frequency;
    } catch (e) {
      throw Exception('No se pudo calcular la frecuencia semanal: $e');
    }
  }

  /// Get monthly workout count trend
  Future<List<Map<String, dynamic>>> getMonthlyTrend(String userId) async {
    try {
      final docs = await _fetchRecentSessions(userId: userId, limit: 240);
      if (docs.isEmpty) return _buildEmptyMonthlyTrend();
      final sessions = docs.map(_buildSessionMetric).toList();
      return _buildMonthlyTrendFromSessions(sessions, months: 6);
    } catch (e) {
      throw Exception('No se pudo cargar la tendencia mensual: $e');
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _fetchRecentSessions({required String userId, int limit = 90}) async {
    final snap =
        await _firestore
            .collection('workout_sessions')
            .where('userId', isEqualTo: userId)
            .orderBy('date', descending: true)
            .limit(limit)
            .get();
    return snap.docs;
  }

  _SessionMetric _buildSessionMetric(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final date =
        _toDate(data['date']) ?? _toDate(data['createdAt']) ?? DateTime.now();
    final exercises = _parseExercises(data['exercises']);
    final totalVolume =
        _asDouble(data['totalVolume']) ??
        _calculateVolumeFromExercises(exercises);

    final exerciseCounts = <String, int>{};
    final muscleCounts = <String, int>{};
    final performances = <_ExercisePerformance>[];

    for (final exercise in exercises) {
      exerciseCounts[exercise.name] = (exerciseCounts[exercise.name] ?? 0) + 1;
      muscleCounts[exercise.muscle] = (muscleCounts[exercise.muscle] ?? 0) + 1;
      for (final set in exercise.sets) {
        if (set.reps <= 0 || set.weight < 0) continue;
        performances.add(
          _ExercisePerformance(
            exercise: exercise.name,
            weight: set.weight,
            reps: set.reps,
            date: date,
          ),
        );
      }
    }

    return _SessionMetric(
      date: date,
      durationMinutes: _extractDurationMinutes(data),
      totalVolume: totalVolume,
      muscleCounts: muscleCounts,
      exerciseCounts: exerciseCounts,
      performances: performances,
    );
  }

  List<_ParsedExercise> _parseExercises(dynamic rawExercises) {
    if (rawExercises is! List) return const [];
    final parsed = <_ParsedExercise>[];

    for (final rawExercise in rawExercises) {
      if (rawExercise is! Map) continue;
      final exercise = rawExercise.cast<String, dynamic>();
      final name = _readFirstString(exercise, const [
        'name',
        'exerciseName',
        'exercise_id',
        'exerciseId',
      ]);
      final muscle = _readFirstString(exercise, const [
        'muscleGroup',
        'muscle',
        'targetMuscle',
      ]);
      final sets = _parseSets(exercise['sets']);

      parsed.add(
        _ParsedExercise(
          name: name.isEmpty ? 'Ejercicio' : name,
          muscle: muscle.isEmpty ? 'Otro' : muscle,
          sets: sets,
        ),
      );
    }

    return parsed;
  }

  List<_ParsedSet> _parseSets(dynamic rawSets) {
    if (rawSets is! List) return const [];
    final sets = <_ParsedSet>[];
    for (final rawSet in rawSets) {
      if (rawSet is! Map) continue;
      final set = rawSet.cast<String, dynamic>();
      sets.add(
        _ParsedSet(
          reps: _asInt(set['reps']),
          weight: _asDouble(set['weight']) ?? 0,
        ),
      );
    }
    return sets;
  }

  double _calculateVolumeFromExercises(List<_ParsedExercise> exercises) {
    var total = 0.0;
    for (final exercise in exercises) {
      for (final set in exercise.sets) {
        total += set.weight * set.reps;
      }
    }
    return total;
  }

  double _extractDurationMinutes(Map<String, dynamic> raw) {
    final start = _toDate(raw['startTime']);
    final end = _toDate(raw['endTime']);
    if (start != null && end != null && end.isAfter(start)) {
      return end.difference(start).inMinutes.toDouble();
    }
    final duration = _asDouble(raw['duration']);
    if (duration != null) {
      if (duration <= 0) return 0;
      return duration / 60;
    }
    return 0;
  }

  Set<DateTime> _uniqueWorkoutDays(List<_SessionMetric> sessions) {
    return sessions
        .map(
          (session) =>
              DateTime(session.date.year, session.date.month, session.date.day),
        )
        .toSet();
  }

  _Streak _calculateStreak(Set<DateTime> uniqueDays) {
    if (uniqueDays.isEmpty) return const _Streak(current: 0, longest: 0);

    final desc = uniqueDays.toList()..sort((a, b) => b.compareTo(a));
    var current = 1;
    for (var i = 0; i < desc.length - 1; i++) {
      if (desc[i].difference(desc[i + 1]).inDays == 1) {
        current++;
      } else {
        break;
      }
    }

    final asc = uniqueDays.toList()..sort();
    var longest = 1;
    var running = 1;
    for (var i = 1; i < asc.length; i++) {
      if (asc[i].difference(asc[i - 1]).inDays == 1) {
        running++;
        if (running > longest) longest = running;
      } else {
        running = 1;
      }
    }

    return _Streak(current: current, longest: longest);
  }

  double _calculateWeeklyAverage({
    required int totalWorkouts,
    required Set<DateTime> uniqueDays,
  }) {
    if (totalWorkouts == 0 || uniqueDays.isEmpty) return 0;
    final sorted = uniqueDays.toList()..sort();
    final spanDays = (sorted.last.difference(sorted.first).inDays + 1).clamp(
      1,
      3650,
    );
    final spanWeeks = spanDays / 7;
    return totalWorkouts / spanWeeks;
  }

  int _calculateConsistencyScore(Set<DateTime> uniqueDays) {
    if (uniqueDays.isEmpty) return 0;
    final now = DateTime.now();
    final last30 = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 29));
    final activeDays = uniqueDays.where((day) => !day.isBefore(last30)).length;
    const expectedTrainingDays = 20.0; // ~5 entrenamientos/semana
    final score = ((activeDays / expectedTrainingDays) * 100).clamp(0, 100);
    return score.round();
  }

  List<Map<String, dynamic>> _buildMonthlyTrendFromSessions(
    List<_SessionMetric> sessions, {
    int months = 6,
  }) {
    if (months <= 0) return const [];
    final now = DateTime.now();
    final counts = <String, int>{};

    for (var i = months - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      counts['${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}'] =
          0;
    }

    for (final session in sessions) {
      final key =
          '${session.date.year}-${session.date.month.toString().padLeft(2, '0')}';
      if (!counts.containsKey(key)) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    return counts.entries.map((entry) {
      final month = int.tryParse(entry.key.split('-').last) ?? 1;
      return {'month': _monthLabels[month - 1], 'count': entry.value};
    }).toList();
  }

  List<Map<String, dynamic>> _buildEmptyMonthlyTrend() {
    final now = DateTime.now();
    return List.generate(6, (index) {
      final date = DateTime(now.year, now.month - (5 - index), 1);
      return {'month': _monthLabels[date.month - 1], 'count': 0};
    });
  }

  double _calculateImprovementRate(List<Map<String, dynamic>> monthlyTrend) {
    if (monthlyTrend.length < 2) return 0;
    final first = _asDouble(monthlyTrend.first['count']) ?? 0;
    final last = _asDouble(monthlyTrend.last['count']) ?? 0;
    if (first <= 0) return last > 0 ? 100 : 0;
    return ((last - first) / first) * 100;
  }

  String _selectTopLabel(
    List<MapEntry<String, int>> entries, {
    required bool pickMost,
  }) {
    if (entries.isEmpty) return 'Sin datos';
    final merged = <String, int>{};
    for (final entry in entries) {
      if (entry.key.trim().isEmpty) continue;
      merged[entry.key] = (merged[entry.key] ?? 0) + entry.value;
    }
    if (merged.isEmpty) return 'Sin datos';
    if (!pickMost && merged.length == 1) return 'Sin datos';

    final ordered =
        merged.entries.toList()..sort((a, b) {
          final comparison =
              pickMost
                  ? b.value.compareTo(a.value)
                  : a.value.compareTo(b.value);
          if (comparison != 0) return comparison;
          return a.key.compareTo(b.key);
        });
    return ordered.first.key;
  }

  List<Map<String, dynamic>> _buildPersonalRecordsFromSessions(
    List<_SessionMetric> sessions,
  ) {
    final grouped = <String, List<_ExercisePerformance>>{};
    for (final session in sessions) {
      for (final perf in session.performances) {
        grouped.putIfAbsent(perf.exercise, () => []).add(perf);
      }
    }

    final records = <Map<String, dynamic>>[];
    grouped.forEach((exercise, perfs) {
      perfs.sort((a, b) {
        final byWeight = b.weight.compareTo(a.weight);
        if (byWeight != 0) return byWeight;
        return b.date.compareTo(a.date);
      });
      final best = perfs.first;
      final previous = perfs.length > 1 ? perfs[1].weight : best.weight;
      records.add({
        'exercise': exercise,
        'weight': best.weight,
        'reps': best.reps,
        'date': best.date.toIso8601String(),
        'previous': previous,
      });
    });

    records.sort(
      (a, b) => (_toDate(b['date']) ?? DateTime(1970)).compareTo(
        _toDate(a['date']) ?? DateTime(1970),
      ),
    );
    return records;
  }

  Map<String, dynamic> _normalizePersonalRecord(Map<String, dynamic> raw) {
    final exercise = _readFirstString(raw, const [
      'exercise',
      'exerciseName',
      'name',
    ]);
    final weight =
        _asDouble(raw['weight']) ??
        _asDouble(raw['maxWeight']) ??
        _asDouble(raw['oneRepMax']) ??
        0;
    final reps = _asInt(raw['reps']) == 0 ? 1 : _asInt(raw['reps']);
    final date =
        _toDate(raw['date']) ?? _toDate(raw['createdAt']) ?? DateTime.now();
    final previous = _asDouble(raw['previous']) ?? weight;

    return {
      'exercise': exercise,
      'weight': weight,
      'reps': reps,
      'date': date.toIso8601String(),
      'previous': previous,
    };
  }

  String _readFirstString(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) return DateTime.tryParse(value);
    try {
      final dynamicDate = (value as dynamic).toDate();
      if (dynamicDate is DateTime) return dynamicDate;
    } catch (_) {
      // Ignore unsupported dynamic date values.
    }
    return null;
  }

  Map<String, dynamic> _emptyAnalytics() => {
    'totalWorkouts': 0,
    'totalHours': 0.0,
    'avgDuration': 0.0,
    'currentStreak': 0,
    'longestStreak': 0,
    'avgWorkoutsPerWeek': 0.0,
    'totalVolume': 0.0,
    'avgVolumePerSession': 0.0,
    'mostTrainedMuscle': 'Sin datos',
    'leastTrainedMuscle': 'Sin datos',
    'favoriteExercise': 'Sin datos',
    'consistencyScore': 0,
    'improvementRate': 0.0,
  };
}

class _SessionMetric {
  final DateTime date;
  final double durationMinutes;
  final double totalVolume;
  final Map<String, int> muscleCounts;
  final Map<String, int> exerciseCounts;
  final List<_ExercisePerformance> performances;

  const _SessionMetric({
    required this.date,
    required this.durationMinutes,
    required this.totalVolume,
    required this.muscleCounts,
    required this.exerciseCounts,
    required this.performances,
  });
}

class _ParsedExercise {
  final String name;
  final String muscle;
  final List<_ParsedSet> sets;

  const _ParsedExercise({
    required this.name,
    required this.muscle,
    required this.sets,
  });
}

class _ParsedSet {
  final int reps;
  final double weight;

  const _ParsedSet({required this.reps, required this.weight});
}

class _ExercisePerformance {
  final String exercise;
  final double weight;
  final int reps;
  final DateTime date;

  const _ExercisePerformance({
    required this.exercise,
    required this.weight,
    required this.reps,
    required this.date,
  });
}

class _Streak {
  final int current;
  final int longest;

  const _Streak({required this.current, required this.longest});
}
