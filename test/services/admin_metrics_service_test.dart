import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/application/services/admin_metrics_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AdminMetricsService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = AdminMetricsService(firestore: firestore);
  });

  group('getOverview', () {
    test('agrega gyms, usuarios, ingresos del mes y accesos 24h', () async {
      final now = DateTime.now();

      await firestore.collection('gyms').doc('g1').set({
        'name': 'Gym Uno',
        'isActive': true,
        'createdAt': now.toIso8601String(),
      });
      await firestore.collection('gyms').doc('g2').set({
        'name': 'Gym Dos',
        'isActive': false,
        'createdAt': '2025-01-01T00:00:00.000',
      });

      await firestore.collection('users').doc('u1').set({'role': 'client'});
      await firestore.collection('users').doc('u2').set({'role': 'owner'});

      await firestore.collection('payments').add({
        'gymId': 'g1',
        'type': 'subscription',
        'amount': 350,
        'date': Timestamp.fromDate(DateTime(now.year, now.month, 1)),
      });

      await firestore.collection('access_logs').add({
        'gymId': 'g1',
        'timestamp': Timestamp.fromDate(now),
      });
      await firestore.collection('access_logs').add({
        'gymId': 'g1',
        'timestamp':
            Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      });

      final overview = await service.getOverview();

      expect(overview.totalGyms, 2);
      expect(overview.activeGyms, 1);
      expect(overview.newGymsThisMonth, 1);
      expect(overview.totalUsers, 2);
      expect(overview.monthRevenue, 350);
      expect(overview.accesses24h, 1);
    });
  });

  group('getPlatformMonthlyRevenue', () {
    test('separa por mes y por tipo (subscription vs pos)', () async {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 10);
      final lastMonth = DateTime(now.year, now.month - 1, 10);

      await firestore.collection('payments').add({
        'gymId': 'g1',
        'type': 'subscription',
        'amount': 200,
        'date': Timestamp.fromDate(thisMonth),
      });
      await firestore.collection('payments').add({
        'gymId': 'g2',
        'type': 'pos',
        'amount': 80,
        'date': Timestamp.fromDate(thisMonth),
      });
      await firestore.collection('payments').add({
        'gymId': 'g1',
        'type': 'subscription',
        'amount': 500,
        'date': Timestamp.fromDate(lastMonth),
      });

      final revenue = await service.getPlatformMonthlyRevenue(months: 3);

      expect(revenue.length, 3);
      expect(revenue[1].subscriptions, 500);
      expect(revenue[2].subscriptions, 200);
      expect(revenue[2].pos, 80);
      expect(revenue[2].total, 280);
    });
  });

  group('getTopGymsByRevenue', () {
    test('agrupa por gym, resuelve nombres y ordena descendente', () async {
      final now = DateTime.now();
      await firestore
          .collection('gyms')
          .doc('g1')
          .set({'name': 'Iron Temple'});
      await firestore.collection('gyms').doc('g2').set({'name': 'PowerHouse'});

      await firestore.collection('payments').add({
        'gymId': 'g1',
        'amount': 100,
        'date': Timestamp.fromDate(now),
      });
      await firestore.collection('payments').add({
        'gymId': 'g2',
        'amount': 900,
        'date': Timestamp.fromDate(now),
      });
      await firestore.collection('payments').add({
        'gymId': 'g2',
        'amount': 100,
        'date': Timestamp.fromDate(now),
      });

      final top = await service.getTopGymsByRevenue(
        since: now.subtract(const Duration(days: 30)),
      );

      expect(top.length, 2);
      expect(top.first.name, 'PowerHouse');
      expect(top.first.revenue, 1000);
      expect(top.last.revenue, 100);
    });
  });

  group('getUserDistribution', () {
    test('cuenta roles en formato string y map', () async {
      await firestore.collection('users').doc('a').set({'role': 'owner'});
      await firestore.collection('users').doc('b').set({
        'role': {'type': 'client'},
      });
      await firestore.collection('users').doc('c').set({'role': 'employee'});
      await firestore.collection('users').doc('d').set({'sinRol': true});

      final distribution = await service.getUserDistribution();

      expect(distribution.owners, 1);
      expect(distribution.clients, 1);
      expect(distribution.staff, 1);
      expect(distribution.unknown, 1);
      expect(distribution.total, 4);
    });
  });

  group('planes de plataforma', () {
    test('ensureDefaultPlans siembra 4 planes solo la primera vez', () async {
      final seeded = await service.ensureDefaultPlans();
      final seededAgain = await service.ensureDefaultPlans();
      final plans = await service.getPlans();

      expect(seeded, isTrue);
      expect(seededAgain, isFalse);
      expect(plans.length, 4);
      expect(plans.first.name, 'Trial');
      expect(plans.last.name, 'Enterprise');
    });

    test('savePlan persiste cambios de nombre y precio', () async {
      await service.ensureDefaultPlans();
      final plans = await service.getPlans();

      await service.savePlan(
        plans.first.copyWith(name: 'Prueba Gratis', price: 49),
      );

      final updated = await service.getPlans();
      expect(updated.first.name, 'Prueba Gratis');
      expect(updated.first.price, 49);
    });
  });

  group('getBillingSummary', () {
    test('MRR suma planes de gyms activos y vencido suma facturas overdue',
        () async {
      await service.ensureDefaultPlans();
      final plans = await service.getPlans();

      await firestore.collection('gyms').doc('g1').set({
        'name': 'Gym Uno',
        'platformPlanId': 'premium',
        'platformPlanStatus': 'active',
      });
      await firestore.collection('gyms').doc('g2').set({
        'name': 'Gym Dos',
        'platformPlanId': 'basico',
        'platformPlanStatus': 'trial',
      });

      await firestore.collection('platform_invoices').add({
        'gymId': 'g2',
        'gymName': 'Gym Dos',
        'planId': 'basico',
        'planName': 'Básico',
        'amount': 999,
        'status': 'overdue',
        'date': Timestamp.fromDate(DateTime.now()),
      });

      final invoices = await service.getRecentInvoices();
      final summary = await service.getBillingSummary(
        plans: plans,
        invoices: invoices,
      );

      expect(summary.mrr, 2499); // solo g1 (premium activo)
      expect(summary.overdueAmount, 999);
    });
  });
}
