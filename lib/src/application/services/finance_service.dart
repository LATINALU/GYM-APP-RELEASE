import 'package:cloud_firestore/cloud_firestore.dart';

/// Application Service para cálculos financieros del gimnasio.
/// Centraliza la lógica de negocio de finanzas sin depender de la UI.
class FinanceService {
  FinanceService({FirebaseFirestore? firestore}) : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  // Lazy: permite inyectar un Firestore fake en tests y no exige
  // Firebase.initializeApp() al construir el servicio.
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  String _requireGymId(String gymId) {
    final normalized = gymId.trim();
    if (normalized.isEmpty) {
      throw Exception('gymId es obligatorio para consultas financieras');
    }
    return normalized;
  }

  /// Calcula el Monthly Recurring Revenue (MRR)
  /// basado en suscripciones activas
  Future<double> calculateMRR({required String gymId}) async {
    try {
      final resolvedGymId = _requireGymId(gymId);
      final snapshot =
          await _firestore
              .collection('subscriptions')
              .where('gymId', isEqualTo: resolvedGymId)
              .where('status', isEqualTo: 'active')
              .get();

      double mrr = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        mrr += (data['monthlyAmount'] as num?)?.toDouble() ?? 0;
      }
      return mrr;
    } catch (e) {
      throw Exception('No se pudo calcular MRR: $e');
    }
  }

  /// Calcula el Annual Recurring Revenue (ARR) = MRR × 12
  Future<double> calculateARR({required String gymId}) async {
    final mrr = await calculateMRR(gymId: gymId);
    return mrr * 12;
  }

  /// Obtiene la tasa de morosidad actual
  /// (Usuarios con pago vencido / Total usuarios activos)
  Future<double> getDelinquencyRate({required String gymId}) async {
    try {
      final resolvedGymId = _requireGymId(gymId);
      final activeCount =
          await _firestore
              .collection('subscriptions')
              .where('gymId', isEqualTo: resolvedGymId)
              .where('status', isEqualTo: 'active')
              .count()
              .get();

      final delinquentCount =
          await _firestore
              .collection('subscriptions')
              .where('gymId', isEqualTo: resolvedGymId)
              .where('status', isEqualTo: 'delinquent')
              .count()
              .get();

      final total = (activeCount.count ?? 0) + (delinquentCount.count ?? 0);
      if (total == 0) return 0;
      return ((delinquentCount.count ?? 0) / total) * 100;
    } catch (e) {
      throw Exception('No se pudo calcular la tasa de morosidad: $e');
    }
  }

  /// Obtiene el historial de ingresos mensuales (últimos 6 meses)
  /// Retorna un Map con keys 'subscriptions' y 'pos' por mes
  Future<List<Map<String, double>>> getMonthlyRevenue({
    required String gymId,
    int months = 6,
  }) async {
    try {
      final resolvedGymId = _requireGymId(gymId);
      final now = DateTime.now();
      final results = <Map<String, double>>[];

      for (int i = months - 1; i >= 0; i--) {
        final monthStart = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 0);

        final subsSnapshot =
            await _firestore
                .collection('payments')
                .where('gymId', isEqualTo: resolvedGymId)
                .where('type', isEqualTo: 'subscription')
                .where(
                  'date',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
                )
                .where(
                  'date',
                  isLessThanOrEqualTo: Timestamp.fromDate(monthEnd),
                )
                .get();

        final posSnapshot =
            await _firestore
                .collection('payments')
                .where('gymId', isEqualTo: resolvedGymId)
                .where('type', isEqualTo: 'pos')
                .where(
                  'date',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
                )
                .where(
                  'date',
                  isLessThanOrEqualTo: Timestamp.fromDate(monthEnd),
                )
                .get();

        double subTotal = 0;
        for (final doc in subsSnapshot.docs) {
          subTotal += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        }

        double posTotal = 0;
        for (final doc in posSnapshot.docs) {
          posTotal += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        }

        results.add({'subscriptions': subTotal, 'pos': posTotal});
      }

      return results;
    } catch (e) {
      throw Exception('No se pudo cargar historial de ingresos: $e');
    }
  }

  /// Obtiene pagos recientes con filtrado
  Future<List<Map<String, dynamic>>> getRecentPayments({
    required String gymId,
    String? statusFilter,
    int limit = 20,
  }) async {
    try {
      final resolvedGymId = _requireGymId(gymId);
      var query = _firestore
          .collection('payments')
          .where('gymId', isEqualTo: resolvedGymId)
          .orderBy('date', descending: true)
          .limit(limit);

      if (statusFilter != null && statusFilter != 'Todos') {
        query = query.where('status', isEqualTo: statusFilter.toLowerCase());
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('No se pudieron cargar pagos recientes: $e');
    }
  }
}
