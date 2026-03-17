import 'package:equatable/equatable.dart';

enum WeekDay {
  monday, tuesday, wednesday, thursday, friday, saturday, sunday
}

extension WeekDayX on WeekDay {
  String get displayName {
    switch (this) {
      case WeekDay.monday: return 'Lunes';
      case WeekDay.tuesday: return 'Martes';
      case WeekDay.wednesday: return 'Miércoles';
      case WeekDay.thursday: return 'Jueves';
      case WeekDay.friday: return 'Viernes';
      case WeekDay.saturday: return 'Sábado';
      case WeekDay.sunday: return 'Domingo';
    }
  }
}

/// Representa un ejercicio dentro de una rutina con sus parámetros de entrenamiento
class RoutineStep extends Equatable {
  final String exerciseId;
  final String exerciseName;
  final String? imageUrl;
  final int sets;
  final String reps; // Ejemplo: "12", "8-10", "Al fallo"
  final String? rpe; // 1-10 (Esfuerzo percibido)
  final String? restTime; // Segundos o minutos

  const RoutineStep({
    required this.exerciseId,
    required this.exerciseName,
    this.imageUrl,
    this.sets = 3,
    this.reps = '12',
    this.rpe,
    this.restTime,
  });

  RoutineStep copyWith({
    int? sets,
    String? reps,
    String? rpe,
    String? restTime,
  }) {
    return RoutineStep(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      imageUrl: imageUrl,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      restTime: restTime ?? this.restTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'imageUrl': imageUrl,
      'sets': sets,
      'reps': reps,
      'rpe': rpe,
      'restTime': restTime,
    };
  }

  factory RoutineStep.fromMap(Map<String, dynamic> map) {
    return RoutineStep(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      imageUrl: map['imageUrl'],
      sets: map['sets'] ?? 3,
      reps: map['reps'] ?? '12',
      rpe: map['rpe'],
      restTime: map['restTime'],
    );
  }

  @override
  List<Object?> get props => [exerciseId, sets, reps, rpe];
}
