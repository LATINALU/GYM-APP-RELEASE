/// Gym Class - Clases grupales del gimnasio
import 'package:equatable/equatable.dart';

/// Estado de una clase
enum GymClassStatus {
  scheduled('Programada'),
  inProgress('En Progreso'),
  completed('Completada'),
  cancelled('Cancelada');

  final String displayName;
  const GymClassStatus(this.displayName);
}

/// Tipo de clase
enum GymClassType {
  spinning('Spinning', '🚴', '#FF6B35'),
  yoga('Yoga', '🧘', '#7B68EE'),
  crossfit('CrossFit', '💪', '#DC143C'),
  zumba('Zumba', '💃', '#FF1493'),
  boxing('Boxeo', '🥊', '#8B0000'),
  pilates('Pilates', '🤸', '#20B2AA'),
  functional('Funcional', '🏋️', '#FF8C00'),
  bodyPump('Body Pump', '🔥', '#B22222'),
  stretching('Stretching', '🧘‍♂️', '#9370DB'),
  hiit('HIIT', '⚡', '#FF4500'),
  aquaGym('Aqua Gym', '🏊', '#1E90FF'),
  other('Otra', '🎯', '#708090');

  final String displayName;
  final String icon;
  final String colorHex;
  const GymClassType(this.displayName, this.icon, this.colorHex);
}

/// Clase grupal del gimnasio
class GymClass extends Equatable {
  final String id;
  final String name;
  final GymClassType type;
  final String instructorId;
  final String instructorName;
  final String room;
  final DateTime startTime;
  final int durationMinutes;
  final int capacity;
  final List<String> bookedMemberIds;
  final List<String> waitlistMemberIds;
  final GymClassStatus status;
  final String? description;
  final String? imageUrl;
  final int difficultyLevel; // 1-5
  final int caloriesBurnEstimate;

  const GymClass({
    required this.id,
    required this.name,
    required this.type,
    required this.instructorId,
    required this.instructorName,
    required this.room,
    required this.startTime,
    required this.durationMinutes,
    required this.capacity,
    this.bookedMemberIds = const [],
    this.waitlistMemberIds = const [],
    this.status = GymClassStatus.scheduled,
    this.description,
    this.imageUrl,
    this.difficultyLevel = 3,
    this.caloriesBurnEstimate = 300,
  });

  /// Hora de fin
  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));

  /// Lugares disponibles
  int get availableSpots => capacity - bookedMemberIds.length;

  /// ¿Está llena?
  bool get isFull => availableSpots <= 0;

  /// ¿Hay waitlist?
  bool get hasWaitlist => waitlistMemberIds.isNotEmpty;

  /// Porcentaje de ocupación
  double get occupancyPercent => (bookedMemberIds.length / capacity) * 100;

  /// ¿Ya comenzó?
  bool get hasStarted => DateTime.now().isAfter(startTime);

  /// ¿Ya terminó?
  bool get hasEnded => DateTime.now().isAfter(endTime);

  /// ¿Se puede reservar?
  bool get isBookable => !hasStarted && status == GymClassStatus.scheduled;

  /// Check if member is booked
  bool isMemberBooked(String memberId) => bookedMemberIds.contains(memberId);

  /// Check if member is on waitlist
  bool isMemberOnWaitlist(String memberId) => waitlistMemberIds.contains(memberId);

  /// Hora formateada
  String get timeFormatted {
    final hour = startTime.hour.toString().padLeft(2, '0');
    final minute = startTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Duración formateada
  String get durationFormatted => '${durationMinutes}min';

  GymClass copyWith({
    String? id,
    String? name,
    GymClassType? type,
    String? instructorId,
    String? instructorName,
    String? room,
    DateTime? startTime,
    int? durationMinutes,
    int? capacity,
    List<String>? bookedMemberIds,
    List<String>? waitlistMemberIds,
    GymClassStatus? status,
    String? description,
    String? imageUrl,
    int? difficultyLevel,
    int? caloriesBurnEstimate,
  }) {
    return GymClass(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      room: room ?? this.room,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      capacity: capacity ?? this.capacity,
      bookedMemberIds: bookedMemberIds ?? this.bookedMemberIds,
      waitlistMemberIds: waitlistMemberIds ?? this.waitlistMemberIds,
      status: status ?? this.status,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      caloriesBurnEstimate: caloriesBurnEstimate ?? this.caloriesBurnEstimate,
    );
  }

  @override
  List<Object?> get props => [id, name, startTime, status];
}

/// Reserva de clase
class ClassBooking extends Equatable {
  final String id;
  final String classId;
  final String memberId;
  final String memberName;
  final DateTime bookingTime;
  final bool attended;
  final bool cancelled;
  final DateTime? cancelledAt;

  const ClassBooking({
    required this.id,
    required this.classId,
    required this.memberId,
    required this.memberName,
    required this.bookingTime,
    this.attended = false,
    this.cancelled = false,
    this.cancelledAt,
  });

  ClassBooking copyWith({
    String? id,
    String? classId,
    String? memberId,
    String? memberName,
    DateTime? bookingTime,
    bool? attended,
    bool? cancelled,
    DateTime? cancelledAt,
  }) {
    return ClassBooking(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      bookingTime: bookingTime ?? this.bookingTime,
      attended: attended ?? this.attended,
      cancelled: cancelled ?? this.cancelled,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  @override
  List<Object?> get props => [id, classId, memberId, bookingTime];
}
