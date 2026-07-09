import 'package:cloud_firestore/cloud_firestore.dart';

/// Resumen global de la plataforma para el dashboard de super admin.
class PlatformOverview {
  final int totalGyms;
  final int activeGyms;
  final int newGymsThisMonth;
  final int totalUsers;
  final double monthRevenue;
  final int accesses24h;

  const PlatformOverview({
    required this.totalGyms,
    required this.activeGyms,
    required this.newGymsThisMonth,
    required this.totalUsers,
    required this.monthRevenue,
    required this.accesses24h,
  });
}

/// Ingresos de un mes calendario, separados por origen.
class PlatformMonthRevenue {
  final DateTime month;
  final double subscriptions;
  final double pos;

  const PlatformMonthRevenue({
    required this.month,
    required this.subscriptions,
    required this.pos,
  });

  double get total => subscriptions + pos;
}

/// Posición de un gimnasio en el ranking de ingresos.
class TopGymRevenue {
  final String gymId;
  final String name;
  final double revenue;

  const TopGymRevenue({
    required this.gymId,
    required this.name,
    required this.revenue,
  });
}

/// Distribución de usuarios de la plataforma por rol.
class PlatformUserDistribution {
  final int admins;
  final int owners;
  final int staff;
  final int clients;
  final int unknown;
  final int newUsersThisMonth;

  const PlatformUserDistribution({
    required this.admins,
    required this.owners,
    required this.staff,
    required this.clients,
    required this.unknown,
    required this.newUsersThisMonth,
  });

  int get total => admins + owners + staff + clients + unknown;
}

/// Plan de suscripción que la plataforma ofrece a los gimnasios.
class PlatformPlan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final int maxMembers; // 0 = ilimitado
  final int maxStaff; // 0 = ilimitado
  final List<String> features;
  final int sortOrder;
  final bool isActive;
  final int colorValue;

  const PlatformPlan({
    required this.id,
    required this.name,
    required this.price,
    this.currency = 'MXN',
    required this.maxMembers,
    required this.maxStaff,
    required this.features,
    required this.sortOrder,
    this.isActive = true,
    required this.colorValue,
  });

  factory PlatformPlan.fromMap(String id, Map<String, dynamic> data) {
    return PlatformPlan(
      id: id,
      name: data['name']?.toString() ?? 'Plan',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: data['currency']?.toString() ?? 'MXN',
      maxMembers: (data['maxMembers'] as num?)?.toInt() ?? 0,
      maxStaff: (data['maxStaff'] as num?)?.toInt() ?? 0,
      features:
          (data['features'] as List<dynamic>? ?? const [])
              .map((f) => f.toString())
              .toList(),
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      colorValue: (data['colorValue'] as num?)?.toInt() ?? 0xFF6366F1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'currency': currency,
      'maxMembers': maxMembers,
      'maxStaff': maxStaff,
      'features': features,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'colorValue': colorValue,
    };
  }

  PlatformPlan copyWith({String? name, double? price}) {
    return PlatformPlan(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      currency: currency,
      maxMembers: maxMembers,
      maxStaff: maxStaff,
      features: features,
      sortOrder: sortOrder,
      isActive: isActive,
      colorValue: colorValue,
    );
  }
}

/// Factura emitida por la plataforma a un gimnasio.
class PlatformInvoice {
  final String id;
  final String gymId;
  final String gymName;
  final String planId;
  final String planName;
  final double amount;
  final String status; // paid | overdue | trial
  final DateTime date;

  const PlatformInvoice({
    required this.id,
    required this.gymId,
    required this.gymName,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.status,
    required this.date,
  });

  factory PlatformInvoice.fromMap(String id, Map<String, dynamic> data) {
    final rawDate = data['date'];
    return PlatformInvoice(
      id: id,
      gymId: data['gymId']?.toString() ?? '',
      gymName: data['gymName']?.toString() ?? 'Gimnasio',
      planId: data['planId']?.toString() ?? '',
      planName: data['planName']?.toString() ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      status: data['status']?.toString() ?? 'paid',
      date:
          rawDate is Timestamp
              ? rawDate.toDate()
              : DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Resumen de facturación de la plataforma (MRR y monto vencido).
class PlatformBillingSummary {
  final double mrr;
  final double overdueAmount;

  const PlatformBillingSummary({
    required this.mrr,
    required this.overdueAmount,
  });
}

/// Application Service con métricas globales de la plataforma
/// para las pantallas de super admin (dashboard, facturación, reportes).
///
/// Las agregaciones de `payments` se hacen con una sola query de rango por
/// fecha y agrupación en cliente para no requerir índices compuestos.
class AdminMetricsService {
  AdminMetricsService({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════

  Future<PlatformOverview> getOverview() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final last24h = now.subtract(const Duration(hours: 24));

    final totalGyms = await _count(_firestore.collection('gyms'));
    final activeGyms = await _count(
      _firestore.collection('gyms').where('isActive', isEqualTo: true),
    );
    // createdAt de gyms/users se guarda como string ISO8601 (ver mappers),
    // por eso el rango se compara contra toIso8601String().
    final newGymsThisMonth = await _count(
      _firestore
          .collection('gyms')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: startOfMonth.toIso8601String(),
          ),
    );
    final totalUsers = await _count(_firestore.collection('users'));
    final accesses24h = await _count(
      _firestore
          .collection('access_logs')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(last24h),
          ),
    );

    final monthPayments = await _fetchPaymentsSince(startOfMonth);
    double monthRevenue = 0;
    for (final payment in monthPayments) {
      monthRevenue += (payment['amount'] as num?)?.toDouble() ?? 0;
    }

    return PlatformOverview(
      totalGyms: totalGyms,
      activeGyms: activeGyms,
      newGymsThisMonth: newGymsThisMonth,
      totalUsers: totalUsers,
      monthRevenue: monthRevenue,
      accesses24h: accesses24h,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REPORTES
  // ═══════════════════════════════════════════════════════════════════════

  /// Ingresos por mes de TODA la plataforma (últimos [months] meses).
  Future<List<PlatformMonthRevenue>> getPlatformMonthlyRevenue({
    int months = 6,
  }) async {
    final now = DateTime.now();
    final rangeStart = DateTime(now.year, now.month - (months - 1), 1);
    final payments = await _fetchPaymentsSince(rangeStart);

    final buckets = <DateTime, List<double>>{};
    for (int i = 0; i < months; i++) {
      buckets[DateTime(rangeStart.year, rangeStart.month + i, 1)] = [0, 0];
    }

    for (final payment in payments) {
      final date = _paymentDate(payment);
      if (date == null) continue;
      final key = DateTime(date.year, date.month, 1);
      final bucket = buckets[key];
      if (bucket == null) continue;
      final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
      if (payment['type'] == 'pos') {
        bucket[1] += amount;
      } else {
        bucket[0] += amount;
      }
    }

    return buckets.entries
        .map(
          (e) => PlatformMonthRevenue(
            month: e.key,
            subscriptions: e.value[0],
            pos: e.value[1],
          ),
        )
        .toList()
      ..sort((a, b) => a.month.compareTo(b.month));
  }

  /// Top gimnasios por ingresos desde [since].
  Future<List<TopGymRevenue>> getTopGymsByRevenue({
    required DateTime since,
    int limit = 5,
  }) async {
    final payments = await _fetchPaymentsSince(since);

    final revenueByGym = <String, double>{};
    for (final payment in payments) {
      final gymId = payment['gymId']?.toString();
      if (gymId == null || gymId.isEmpty) continue;
      revenueByGym[gymId] =
          (revenueByGym[gymId] ?? 0) +
          ((payment['amount'] as num?)?.toDouble() ?? 0);
    }

    final gymNames = await _fetchGymNames();
    final ranking =
        revenueByGym.entries
            .map(
              (e) => TopGymRevenue(
                gymId: e.key,
                name: gymNames[e.key] ?? e.key,
                revenue: e.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return ranking.take(limit).toList();
  }

  /// Distribución de usuarios por rol. El campo `role` puede venir como
  /// string o como map {'type': ...} según la versión del registro.
  Future<PlatformUserDistribution> getUserDistribution() async {
    final snapshot = await _firestore.collection('users').get();
    final startOfMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      1,
    );

    int admins = 0, owners = 0, staff = 0, clients = 0, unknown = 0;
    int newUsers = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      dynamic rawRole = data['role'];
      if (rawRole is Map) rawRole = rawRole['type'];
      switch (rawRole?.toString().trim().toLowerCase()) {
        case 'admin':
          admins++;
        case 'owner':
        case 'dueño':
          owners++;
        case 'employee':
        case 'staff':
        case 'empleado':
          staff++;
        case 'client':
        case 'cliente':
          clients++;
        default:
          unknown++;
      }

      final createdAt = DateTime.tryParse(data['createdAt']?.toString() ?? '');
      if (createdAt != null && !createdAt.isBefore(startOfMonth)) {
        newUsers++;
      }
    }

    return PlatformUserDistribution(
      admins: admins,
      owners: owners,
      staff: staff,
      clients: clients,
      unknown: unknown,
      newUsersThisMonth: newUsers,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FACTURACIÓN DE PLATAFORMA
  // ═══════════════════════════════════════════════════════════════════════

  /// Planes de la plataforma ordenados por sortOrder.
  /// El filtro de activos se hace en cliente para no exigir índice compuesto.
  Future<List<PlatformPlan>> getPlans({bool onlyActive = true}) async {
    final snapshot =
        await _firestore.collection('platform_plans').orderBy('sortOrder').get();
    final plans = snapshot.docs
        .map((doc) => PlatformPlan.fromMap(doc.id, doc.data()))
        .toList();
    return onlyActive ? plans.where((p) => p.isActive).toList() : plans;
  }

  Future<void> savePlan(PlatformPlan plan) async {
    await _firestore
        .collection('platform_plans')
        .doc(plan.id)
        .set(plan.toMap(), SetOptions(merge: true));
  }

  /// Crea los planes por defecto si la colección está vacía.
  /// Devuelve true si tuvo que sembrarlos.
  Future<bool> ensureDefaultPlans() async {
    final existing = await _count(_firestore.collection('platform_plans'));
    if (existing > 0) return false;

    final batch = _firestore.batch();
    for (final plan in _defaultPlans) {
      batch.set(
        _firestore.collection('platform_plans').doc(plan.id),
        plan.toMap(),
      );
    }
    await batch.commit();
    return true;
  }

  Future<List<PlatformInvoice>> getRecentInvoices({int limit = 50}) async {
    final snapshot =
        await _firestore
            .collection('platform_invoices')
            .orderBy('date', descending: true)
            .limit(limit)
            .get();
    return snapshot.docs
        .map((doc) => PlatformInvoice.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// MRR de plataforma = suma del precio del plan de cada gym activo.
  /// Vencido = suma de facturas en estado overdue.
  Future<PlatformBillingSummary> getBillingSummary({
    required List<PlatformPlan> plans,
    required List<PlatformInvoice> invoices,
  }) async {
    final priceByPlan = {for (final p in plans) p.id: p.price};

    final gymsSnapshot = await _firestore.collection('gyms').get();
    double mrr = 0;
    for (final doc in gymsSnapshot.docs) {
      final data = doc.data();
      if (data['platformPlanStatus']?.toString() != 'active') continue;
      mrr += priceByPlan[data['platformPlanId']?.toString()] ?? 0;
    }

    double overdue = 0;
    for (final invoice in invoices) {
      if (invoice.status == 'overdue') overdue += invoice.amount;
    }

    return PlatformBillingSummary(mrr: mrr, overdueAmount: overdue);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> _fetchPaymentsSince(
    DateTime since,
  ) async {
    final snapshot =
        await _firestore
            .collection('payments')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(since),
            )
            .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  DateTime? _paymentDate(Map<String, dynamic> payment) {
    final raw = payment['date'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw?.toString() ?? '');
  }

  Future<Map<String, String>> _fetchGymNames() async {
    final snapshot = await _firestore.collection('gyms').get();
    return {
      for (final doc in snapshot.docs)
        doc.id: doc.data()['name']?.toString() ?? doc.id,
    };
  }

  static const _defaultPlans = [
    PlatformPlan(
      id: 'trial',
      name: 'Trial',
      price: 0,
      maxMembers: 50,
      maxStaff: 1,
      features: ['50 miembros', '1 staff', 'Dashboard básico', '14 días'],
      sortOrder: 0,
      colorValue: 0xFFF59E0B,
    ),
    PlatformPlan(
      id: 'basico',
      name: 'Básico',
      price: 999,
      maxMembers: 200,
      maxStaff: 5,
      features: ['200 miembros', '5 staff', 'Reportes', 'POS'],
      sortOrder: 1,
      colorValue: 0xFF6366F1,
    ),
    PlatformPlan(
      id: 'premium',
      name: 'Premium',
      price: 2499,
      maxMembers: 500,
      maxStaff: 15,
      features: ['500 miembros', '15 staff', 'BI Dashboard', 'IA Retención'],
      sortOrder: 2,
      colorValue: 0xFFFF6B35,
    ),
    PlatformPlan(
      id: 'enterprise',
      name: 'Enterprise',
      price: 4999,
      maxMembers: 0,
      maxStaff: 0,
      features: [
        'Miembros ilimitados',
        'Staff ilimitado',
        'Multi-sucursal',
        'Soporte 24/7',
      ],
      sortOrder: 3,
      colorValue: 0xFF10B981,
    ),
  ];
}
