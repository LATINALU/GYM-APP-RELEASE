import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/domain/entities/entities.dart';
import 'package:gym_app/src/infrastructure/mappers/gym_mapper.dart';

void main() {
  group('GymMapper Supabase round-trip', () {
    test('toSupabase produce columnas snake_case y fromSupabase reconstruye el mismo valor', () {
      final gym = Gym.create(
        name: 'Iron Temple GYM',
        address: 'Av. Siempre Viva 123',
        logoUrl: 'https://example.com/logo.png',
      );

      final row = GymMapper.toSupabase(gym);

      expect(row['id'], gym.id.value);
      expect(row['code'], gym.code.value);
      expect(row['name'], 'Iron Temple GYM');
      expect(row['address'], 'Av. Siempre Viva 123');
      expect(row['logo_url'], 'https://example.com/logo.png');
      expect(row['is_active'], isTrue);

      final fromDb = GymMapper.fromSupabase(row);

      expect(fromDb.id, gym.id);
      expect(fromDb.code, gym.code);
      expect(fromDb.name, gym.name);
      expect(fromDb.address, gym.address);
      expect(fromDb.logoUrl, gym.logoUrl);
      expect(fromDb.isActive, isTrue);
    });

    test('fromSupabase tolera un gimnasio sin dirección ni teléfono', () {
      final row = {
        'id': 'gym-1',
        'code': 'IRO1234',
        'name': 'Gym Mínimo',
        'address': null,
        'phone': null,
        'logo_url': null,
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
        'is_active': false,
      };

      final gym = GymMapper.fromSupabase(row);

      expect(gym.name, 'Gym Mínimo');
      expect(gym.address, isNull);
      expect(gym.phone, isNull);
      expect(gym.isActive, isFalse);
    });
  });
}
