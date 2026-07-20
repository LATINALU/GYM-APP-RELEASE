import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/domain/services/membership_renewal.dart';

void main() {
  group('MembershipRenewal.parseExpiry', () {
    test('parsea dd/MM/yyyy válido', () {
      expect(MembershipRenewal.parseExpiry('05/08/2026'), DateTime(2026, 8, 5));
      expect(MembershipRenewal.parseExpiry('31/12/2025'),
          DateTime(2025, 12, 31));
    });

    test('rechaza formatos inválidos', () {
      expect(MembershipRenewal.parseExpiry(null), isNull);
      expect(MembershipRenewal.parseExpiry('--'), isNull);
      expect(MembershipRenewal.parseExpiry(''), isNull);
      expect(MembershipRenewal.parseExpiry('2026-08-05'), isNull);
      expect(MembershipRenewal.parseExpiry('99/99/2026'), isNull);
      expect(MembershipRenewal.parseExpiry('31/02/2026'), isNull);
    });
  });

  group('MembershipRenewal.formatExpiry', () {
    test('formatea con ceros a la izquierda', () {
      expect(MembershipRenewal.formatExpiry(DateTime(2026, 8, 5)),
          '05/08/2026');
      expect(MembershipRenewal.formatExpiry(DateTime(2026, 12, 25)),
          '25/12/2026');
    });
  });

  group('MembershipRenewal.computeNewExpiry', () {
    final today = DateTime(2026, 7, 20);

    test('miembro vigente: suma días al vencimiento actual (no pierde días)',
        () {
      final result = MembershipRenewal.computeNewExpiry(
        currentExpiry: '25/07/2026',
        days: 30,
        now: today,
      );
      expect(result, DateTime(2026, 8, 24));
    });

    test('miembro vencido: cuenta desde hoy', () {
      final result = MembershipRenewal.computeNewExpiry(
        currentExpiry: '01/06/2026',
        days: 30,
        now: today,
      );
      expect(result, DateTime(2026, 8, 19));
    });

    test('sin fecha válida (--): cuenta desde hoy', () {
      final result = MembershipRenewal.computeNewExpiry(
        currentExpiry: '--',
        days: 90,
        now: today,
      );
      expect(result, DateTime(2026, 10, 18));
    });

    test('duración anual', () {
      final result = MembershipRenewal.computeNewExpiry(
        currentExpiry: null,
        days: 365,
        now: today,
      );
      expect(result, DateTime(2027, 7, 20));
    });
  });
}
