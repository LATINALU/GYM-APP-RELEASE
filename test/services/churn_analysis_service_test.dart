import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/application/services/churn_analysis_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ChurnAnalysisService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = ChurnAnalysisService(firestore: firestore);
  });

  Future<String> seedUser({
    required String gymId,
    String name = 'Usuario',
    String? churnRisk,
    DateTime? lastCheckIn,
  }) async {
    final doc = await firestore.collection('users').add({
      'gymId': gymId,
      'name': name,
      if (churnRisk != null) 'churn_risk': churnRisk,
      if (lastCheckIn != null) 'lastCheckIn': Timestamp.fromDate(lastCheckIn),
    });
    return doc.id;
  }

  group('calculateChurnRisk', () {
    test('sin lastCheckIn: riesgo CRITICAL con score 1.0', () async {
      final userId = await seedUser(gymId: 'g1');

      final result = await service.calculateChurnRisk(userId);

      expect(result['level'], 'CRITICAL');
      expect(result['score'], 1.0);
    });

    test('más de 15 días sin visitar: CRITICAL', () async {
      final userId = await seedUser(
        gymId: 'g1',
        lastCheckIn: DateTime.now().subtract(const Duration(days: 20)),
      );

      final result = await service.calculateChurnRisk(userId);

      expect(result['level'], 'CRITICAL');
    });

    test('entre 7 y 15 días sin visitar: HIGH', () async {
      final userId = await seedUser(
        gymId: 'g1',
        lastCheckIn: DateTime.now().subtract(const Duration(days: 10)),
      );

      final result = await service.calculateChurnRisk(userId);

      expect(result['level'], 'HIGH');
    });

    test('visita reciente y sin caída de asistencia: LOW', () async {
      final userId = await seedUser(
        gymId: 'g1',
        lastCheckIn: DateTime.now().subtract(const Duration(days: 1)),
      );
      await firestore.collection('users').doc(userId).update({
        'avgVisitsLastMonth': 10.0,
        'visitsThisMonth': 10.0,
      });

      final result = await service.calculateChurnRisk(userId);

      expect(result['level'], 'LOW');
    });

    test('persiste el riesgo calculado en el documento del usuario', () async {
      final userId = await seedUser(
        gymId: 'g1',
        lastCheckIn: DateTime.now().subtract(const Duration(days: 20)),
      );

      await service.calculateChurnRisk(userId);

      final doc = await firestore.collection('users').doc(userId).get();
      expect(doc.data()!['churn_risk'], 'CRITICAL');
    });
  });

  group('generateRecoveryMessage', () {
    test('CRITICAL menciona al usuario y ofrece incentivo', () {
      final message = service.generateRecoveryMessage('CRITICAL', 'Ana');
      expect(message, contains('Ana'));
    });

    test('HIGH y LOW también incluyen el nombre del usuario', () {
      expect(service.generateRecoveryMessage('HIGH', 'Luis'), contains('Luis'));
      expect(service.generateRecoveryMessage('LOW', 'Marta'), contains('Marta'));
    });
  });

  group('getHighRiskUsers', () {
    test('lanza si gymId está vacío (evita fuga multi-tenant sin filtro)', () {
      expect(
        () => service.getHighRiskUsers(gymId: '   '),
        throwsException,
      );
    });

    test('solo devuelve usuarios del gym indicado con riesgo CRITICAL o HIGH', () async {
      await seedUser(gymId: 'g1', name: 'Riesgo alto propio', churnRisk: 'HIGH');
      await seedUser(gymId: 'g1', name: 'Riesgo crítico propio', churnRisk: 'CRITICAL');
      await seedUser(gymId: 'g1', name: 'Sin riesgo propio', churnRisk: 'LOW');
      await seedUser(gymId: 'g2', name: 'Riesgo alto de otro gym', churnRisk: 'HIGH');

      final result = await service.getHighRiskUsers(gymId: 'g1');

      expect(result.length, 2);
      expect(
        result.map((u) => u['name']),
        containsAll(['Riesgo alto propio', 'Riesgo crítico propio']),
      );
      expect(
        result.map((u) => u['name']),
        isNot(contains('Riesgo alto de otro gym')),
      );
    });
  });
}
