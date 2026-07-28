import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/application/services/routine_service.dart';

void main() {
  late RoutineService service;

  setUp(() {
    service = RoutineService(firestore: FakeFirebaseFirestore());
  });

  group('calculateVolume', () {
    test('reps numéricas simples: sets * reps * peso', () {
      expect(service.calculateVolume(4, '10', 50), 2000);
    });

    test('reps en rango ("8-12"): usa solo los dígitos, concatenados', () {
      // replaceAll(RegExp(r'[^0-9]'), '') convierte "8-12" en "812"
      expect(service.calculateVolume(3, '8-12', 20), 3 * 812 * 20);
    });

    test('reps no numéricas ("Al fallo"): cuenta como 0 reps, volumen 0', () {
      expect(service.calculateVolume(4, 'Al fallo', 50), 0);
    });

    test('reps vacías: cuenta como 0 reps, volumen 0', () {
      expect(service.calculateVolume(4, '', 50), 0);
    });
  });
}
