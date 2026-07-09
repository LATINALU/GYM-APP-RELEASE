import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_app/src/application/services/admin_metrics_service.dart';
import 'package:gym_app/src/infrastructure/config/di.dart';
import 'package:gym_app/src/presentation/screens/admin/admin_dashboard_screen.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() async {
    await getIt.reset();
    firestore = FakeFirebaseFirestore();
    getIt.registerFactory<AdminMetricsService>(
      () => AdminMetricsService(firestore: firestore),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('AdminDashboardScreen muestra KPIs reales de Firestore',
      (tester) async {
    await firestore.collection('gyms').doc('g1').set({
      'name': 'Gym Uno',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await firestore.collection('users').doc('u1').set({'role': 'client'});
    await firestore.collection('payments').add({
      'gymId': 'g1',
      'type': 'subscription',
      'amount': 750,
      'date': Timestamp.fromDate(DateTime.now()),
    });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdminDashboardScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('PANEL SUPER ADMIN'), findsOneWidget);
    expect(find.text('Gimnasios Activos'), findsOneWidget);
    expect(find.text('Usuarios Totales'), findsOneWidget);
    // 1 gym activo de 1 registrado
    expect(find.text('de 1 registrados'), findsOneWidget);
  });

  testWidgets(
      'AdminDashboardScreen muestra error recuperable si falla la carga',
      (tester) async {
    // Sin AdminMetricsService registrado, getIt lanza y la pantalla debe
    // mostrar su estado de error con opción de reintentar, no crashear.
    await getIt.reset();

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdminDashboardScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudieron cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
