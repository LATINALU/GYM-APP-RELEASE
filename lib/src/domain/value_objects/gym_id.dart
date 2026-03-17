import 'package:uuid/uuid.dart';

/// Value Object for Gym Identifier
class GymId {
  final String value;

  const GymId(this.value);

  /// Factory: Generate a new unique GymId
  factory GymId.generate() {
    return GymId(const Uuid().v4());
  }

  /// Factory: Create from raw string
  factory GymId.fromString(String value) {
    if (value.isEmpty) {
      throw ArgumentError('GymId cannot be empty');
    }
    return GymId(value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymId && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
