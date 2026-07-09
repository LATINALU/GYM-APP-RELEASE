import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/application/services/finance_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FinanceService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = FinanceService(firestore: firestore);
  });

  Future<void> seedSubscription({
    required String gymId,
    required String status,
    required double monthlyAmount,
  }) {
    return firestore.collection('subscriptions').add({
      'gymId': gymId,
      'status': status,
      'monthlyAmount': monthlyAmount,
    }).then((_) {});
  }

  group('calculateMRR', () {
    test('suma solo suscripciones activas del gym indicado', () async {
      await seedSubscription(gymId: 'g1', status: 'active', monthlyAmount: 500);
      await seedSubscription(gymId: 'g1', status: 'active', monthlyAmount: 300);
      await seedSubscription(
          gymId: 'g1', status: 'delinquent', monthlyAmount: 900);
      await seedSubscription(gymId: 'g2', status: 'active', monthlyAmount: 999);

      final mrr = await service.calculateMRR(gymId: 'g1');

      expect(mrr, 800);
    });

    test('lanza si gymId está vacío', () async {
      expect(
        () => service.calculateMRR(gymId: '  '),
        throwsA(isA<Exception>()),
      );
    });
  });

  test('calculateARR es MRR × 12', () async {
    await seedSubscription(gymId: 'g1', status: 'active', monthlyAmount: 100);

    final arr = await service.calculateARR(gymId: 'g1');

    expect(arr, 1200);
  });

  group('getDelinquencyRate', () {
    test('calcula porcentaje de morosos sobre el total', () async {
      await seedSubscription(gymId: 'g1', status: 'active', monthlyAmount: 1);
      await seedSubscription(gymId: 'g1', status: 'active', monthlyAmount: 1);
      await seedSubscription(gymId: 'g1', status: 'active', monthlyAmount: 1);
      await seedSubscription(
          gymId: 'g1', status: 'delinquent', monthlyAmount: 1);

      final rate = await service.getDelinquencyRate(gymId: 'g1');

      expect(rate, 25);
    });

    test('devuelve 0 sin suscripciones', () async {
      final rate = await service.getDelinquencyRate(gymId: 'g1');

      expect(rate, 0);
    });
  });

  group('getMonthlyRevenue', () {
    test('agrupa pagos por mes y tipo', () async {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 5);
      final lastMonth = DateTime(now.year, now.month - 1, 5);

      await firestore.collection('payments').add({
        'gymId': 'g1',
        'type': 'subscription',
        'amount': 400,
        'date': Timestamp.fromDate(thisMonth),
      });
      await firestore.collection('payments').add({
        'gymId': 'g1',
        'type': 'pos',
        'amount': 150,
        'date': Timestamp.fromDate(thisMonth),
      });
      await firestore.collection('payments').add({
        'gymId': 'g1',
        'type': 'subscription',
        'amount': 900,
        'date': Timestamp.fromDate(lastMonth),
      });
      // Pago de otro gym: no debe contarse.
      await firestore.collection('payments').add({
        'gymId': 'g2',
        'type': 'subscription',
        'amount': 5000,
        'date': Timestamp.fromDate(thisMonth),
      });

      final revenue = await service.getMonthlyRevenue(gymId: 'g1', months: 2);

      expect(revenue.length, 2);
      expect(revenue[0]['subscriptions'], 900); // mes anterior
      expect(revenue[1]['subscriptions'], 400); // mes actual
      expect(revenue[1]['pos'], 150);
    });
  });
}
