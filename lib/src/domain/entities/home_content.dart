import 'entities.dart';

class HomeContent {
  final String gymName;
  final List<WorkoutRoutine> activeRoutines;
  final List<WorkoutRoutine> quickRoutines;
  final WorkoutPlan? assignedPlan;
  
  // Expert Metrics
  final double caloriesBurnedToday;
  final int workoutsCompletedThisWeek;
  final double weeklyVolumeTons;
  final int trainingStreakDays;

  HomeContent({
    required this.gymName,
    required this.activeRoutines,
    required this.quickRoutines,
    this.assignedPlan,
    this.caloriesBurnedToday = 420.0,
    this.workoutsCompletedThisWeek = 3,
    this.weeklyVolumeTons = 12.4,
    this.trainingStreakDays = 5,
  });
}
