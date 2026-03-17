/// Gym Access Control - Sistema de check-in/check-out y control de acceso
import 'package:equatable/equatable.dart';

/// Tipo de check-in
enum CheckInType {
  qrScan('Escaneo QR'),
  manual('Manual'),
  nfc('NFC'),
  facialRecognition('Reconocimiento Facial');

  final String displayName;
  const CheckInType(this.displayName);
}

/// Registro de asistencia
class AttendanceRecord extends Equatable {
  final String id;
  final String memberId;
  final String memberName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final CheckInType checkInType;
  final String? staffId; // Quien registró (si fue manual)
  final String? notes;

  const AttendanceRecord({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.checkInTime,
    this.checkOutTime,
    this.checkInType = CheckInType.qrScan,
    this.staffId,
    this.notes,
  });

  /// ¿Sigue en el gym?
  bool get isCurrentlyInGym => checkOutTime == null;

  /// Duración de la visita
  Duration? get visitDuration {
    if (checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime);
  }

  /// Tiempo transcurrido desde check-in
  Duration get elapsedTime => DateTime.now().difference(checkInTime);

  /// Hora de check-in formateada
  String get checkInFormatted {
    final h = checkInTime.hour.toString().padLeft(2, '0');
    final m = checkInTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Hora de check-out formateada
  String? get checkOutFormatted {
    if (checkOutTime == null) return null;
    final h = checkOutTime!.hour.toString().padLeft(2, '0');
    final m = checkOutTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  AttendanceRecord copyWith({
    String? id,
    String? memberId,
    String? memberName,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    CheckInType? checkInType,
    String? staffId,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInType: checkInType ?? this.checkInType,
      staffId: staffId ?? this.staffId,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, memberId, checkInTime];
}

/// Zona del gimnasio
enum GymZone {
  weightRoom('Zona de Pesas', '🏋️', 40),
  cardioArea('Cardio', '🏃', 30),
  groupClassRoom('Sala Clases', '👥', 25),
  locker('Vestuarios', '🚿', 20),
  pool('Piscina', '🏊', 15),
  spa('Spa', '💆', 10),
  reception('Recepción', '🏢', 50);

  final String displayName;
  final String icon;
  final int maxCapacity;
  const GymZone(this.displayName, this.icon, this.maxCapacity);
}

/// Estado de ocupación del gimnasio
class GymOccupancy extends Equatable {
  final DateTime timestamp;
  final int totalCurrentMembers;
  final int maxCapacity;
  final Map<GymZone, int> zoneOccupancy;

  const GymOccupancy({
    required this.timestamp,
    required this.totalCurrentMembers,
    required this.maxCapacity,
    required this.zoneOccupancy,
  });

  /// Porcentaje de ocupación total
  double get occupancyPercent => (totalCurrentMembers / maxCapacity) * 100;

  /// Color según ocupación
  String get occupancyColorHex {
    if (occupancyPercent < 50) return '#10B981'; // Verde
    if (occupancyPercent < 80) return '#F59E0B'; // Amarillo
    return '#EF4444'; // Rojo
  }

  /// Estado textual
  String get occupancyStatus {
    if (occupancyPercent < 30) return 'Muy Tranquilo';
    if (occupancyPercent < 50) return 'Tranquilo';
    if (occupancyPercent < 70) return 'Moderado';
    if (occupancyPercent < 90) return 'Ocupado';
    return 'Muy Ocupado';
  }

  /// Ocupación por zona
  int getZoneOccupancy(GymZone zone) => zoneOccupancy[zone] ?? 0;

  /// Porcentaje por zona
  double getZonePercent(GymZone zone) {
    final current = getZoneOccupancy(zone);
    return (current / zone.maxCapacity) * 100;
  }

  @override
  List<Object?> get props => [timestamp, totalCurrentMembers];
}

/// Turno reservado (para control de aforo)
class TimeSlotReservation extends Equatable {
  final String id;
  final String memberId;
  final DateTime date;
  final String slotId;
  final String slotName; // "06:00-08:00"
  final DateTime startTime;
  final DateTime endTime;
  final bool checkedIn;
  final bool noShow;
  final DateTime reservationTime;

  const TimeSlotReservation({
    required this.id,
    required this.memberId,
    required this.date,
    required this.slotId,
    required this.slotName,
    required this.startTime,
    required this.endTime,
    this.checkedIn = false,
    this.noShow = false,
    required this.reservationTime,
  });

  /// ¿Está activo ahora?
  bool get isActiveNow {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// ¿Ya pasó?
  bool get hasPassed => DateTime.now().isAfter(endTime);

  @override
  List<Object?> get props => [id, memberId, slotId, date];
}

/// Control de acceso centralizado
class GymAccessControl {
  final String gymId;
  final List<AttendanceRecord> todayRecords;
  final GymOccupancy currentOccupancy;

  GymAccessControl({
    required this.gymId,
    required this.todayRecords,
    required this.currentOccupancy,
  });

  /// Generar código QR único para miembro
  String generateAccessQR(String memberId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'GYM_${gymId}_MEMBER_${memberId}_$timestamp';
  }

  /// Validar código QR
  bool validateQRCode(String qrCode) {
    if (!qrCode.startsWith('GYM_$gymId')) return false;
    final parts = qrCode.split('_');
    if (parts.length < 4) return false;
    // Validar que no tenga más de 24 horas
    final timestamp = int.tryParse(parts.last);
    if (timestamp == null) return false;
    final qrTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(qrTime).inHours < 24;
  }

  /// Miembros actualmente en el gym
  List<AttendanceRecord> get currentlyInGym {
    return todayRecords.where((r) => r.isCurrentlyInGym).toList();
  }

  /// Total de visitas hoy
  int get totalVisitsToday => todayRecords.length;
}

/// Peak hours analytics
class PeakHoursData extends Equatable {
  final Map<int, double> hourlyOccupancy; // 0-23 -> percentage

  const PeakHoursData({required this.hourlyOccupancy});

  /// Hora pico
  int get peakHour {
    int maxHour = 0;
    double maxValue = 0;
    hourlyOccupancy.forEach((hour, value) {
      if (value > maxValue) {
        maxValue = value;
        maxHour = hour;
      }
    });
    return maxHour;
  }

  /// Horas tranquilas
  List<int> get quietHours {
    return hourlyOccupancy.entries
        .where((e) => e.value < 30)
        .map((e) => e.key)
        .toList();
  }

  @override
  List<Object?> get props => [hourlyOccupancy];
}
