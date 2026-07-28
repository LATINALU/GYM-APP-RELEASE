import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/domain/entities/entities.dart';
import 'package:gym_app/src/domain/value_objects/value_objects.dart';
import 'package:gym_app/src/infrastructure/mappers/user_mapper.dart';

void main() {
  group('UserMapper Supabase (gym_members) round-trip', () {
    test('toSupabase produce columnas snake_case y fromSupabase reconstruye el mismo valor', () {
      final user = User.create(
        email: Email('ana@example.com'),
        name: PersonName(firstName: 'Ana', lastName: 'García'),
        role: const GymRole.client(),
        gymId: const GymId('gym-1'),
        weight: 62.5,
        height: 165,
        fitnessGoal: 'Tonificar',
        membershipStatus: MembershipStatus.approved,
      );

      final row = UserMapper.toSupabase(user);

      expect(row['id'], user.id.value);
      expect(row['gym_id'], 'gym-1');
      expect(row['email'], 'ana@example.com');
      expect(row['first_name'], 'Ana');
      expect(row['last_name'], 'García');
      expect(row['role'], 'client');
      expect(row['weight'], 62.5);
      expect(row['fitness_goal'], 'Tonificar');
      expect(row.containsKey('gymId'), isFalse);
      expect(row.containsKey('firstName'), isFalse);

      final fromDb = UserMapper.fromSupabase(row);

      expect(fromDb.id, user.id);
      expect(fromDb.email, user.email);
      expect(fromDb.name.firstName, 'Ana');
      expect(fromDb.name.lastName, 'García');
      expect(fromDb.role.type, GymRoleType.client);
      expect(fromDb.gymId, user.gymId);
      expect(fromDb.weight, 62.5);
      expect(fromDb.height, 165);
      expect(fromDb.fitnessGoal, 'Tonificar');
      expect(fromDb.membershipStatus, MembershipStatus.approved);
    });

    test('fromSupabase reconstruye un owner sin datos fitness', () {
      final row = {
        'id': 'owner-1',
        'gym_id': 'gym-1',
        'email': 'owner@example.com',
        'first_name': 'Carlos',
        'last_name': 'Mendoza',
        'role': 'owner',
        'phone': null,
        'is_active': true,
        'membership_status': 'approved',
        'weight': null,
        'height': null,
        'fitness_goal': null,
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
      };

      final user = UserMapper.fromSupabase(row);

      expect(user.role.type, GymRoleType.owner);
      expect(user.weight, isNull);
      expect(user.fitnessGoal, isNull);
      expect(user.isActive, isTrue);
    });
  });
}
