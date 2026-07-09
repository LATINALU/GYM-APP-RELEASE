import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Repository for owner-level member management operations.
/// Handles the gyms/{gymId}/members subcollection and audit_logs.
class FirebaseOwnerMemberRepository {
  final FirebaseFirestore _firestore;

  FirebaseOwnerMemberRepository(this._firestore);

  /// Load all members for a gym from the members subcollection.
  Future<List<Map<String, dynamic>>> loadMembers(String gymId) async {
    final snapshot = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .get();

    return snapshot.docs.map((doc) {
      final d = doc.data();
      return {
        'id': doc.id,
        'name': d['name'] ?? 'Sin nombre',
        'plan': d['plan'] ?? 'Sin plan',
        'expiry': d['expiry'] ?? '--',
        'status': d['status'] ?? 'Activos',
        'email': d['email'],
        'phone': d['phone'],
        'isFrozen': d['isFrozen'] ?? false,
      };
    }).toList();
  }

  /// Save a new member to the gym's members subcollection.
  Future<void> saveMember(String gymId, Map<String, dynamic> memberData) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .add({
      ...memberData,
      'registeredAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a member from the gym's members subcollection.
  Future<void> deleteMember(String gymId, String memberId) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .doc(memberId)
        .delete();
  }

  /// Log an audit event to the audit_logs collection.
  Future<void> logAudit({
    required String who,
    required String action,
    required String module,
    String? gymId,
  }) async {
    try {
      await _firestore.collection('audit_logs').add({
        'who': who,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'module': module,
        if (gymId != null) 'gymId': gymId,
      });
    } catch (e) {
      debugPrint('Error logging audit: $e');
    }
  }

  /// Load active routines for a gym (returns raw maps for UI consumption).
  Future<List<Map<String, dynamic>>> loadActiveRoutines(String gymId) async {
    final snapshot = await _firestore
        .collection('routines')
        .where('gymId', isEqualTo: gymId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Sin nombre',
        'difficulty': data['difficulty'] ?? 'intermediate',
        'focus': data['focus'] ?? 'general',
        'exerciseCount': (data['exercises'] as List?)?.length ?? 0,
      };
    }).toList();
  }

  /// Create a routine assignment for a member.
  Future<void> createAssignment({
    required String gymId,
    required String routineId,
    required String clientId,
    required String assignedById,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
  }) async {
    await _firestore.collection('assignments').add({
      'routineId': routineId,
      'clientId': clientId,
      'assignedById': assignedById,
      'assignedAt': DateTime.now().toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'status': 'active',
      'gymId': gymId,
    });
  }

  /// Load dashboard KPIs for a gym.
  /// Returns a map with: activeMemberships, totalMembers, expiredMembers,
  /// monthlyRevenue, accesses24h.
  Future<Map<String, dynamic>> loadDashboardKPIs(String gymId) async {
    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month, 1);
    final last24h = today.subtract(const Duration(hours: 24));

    // Active memberships
    final membersSnap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .where('status', isEqualTo: 'Activos')
        .get();

    // All members for churn
    final allMembersSnap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .get();

    // Monthly revenue from daily_closings
    final revenueSnap = await _firestore
        .collection('daily_closings')
        .where('gymId', isEqualTo: gymId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();

    double totalRevenue = 0;
    for (final doc in revenueSnap.docs) {
      totalRevenue += (doc.data()['real_amount'] as num? ?? 0).toDouble();
    }

    // Access logs in last 24h
    final accessSnap = await _firestore
        .collection('access_logs')
        .where('gymId', isEqualTo: gymId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(last24h))
        .get();

    final totalMembers = allMembersSnap.docs.length;
    final expired = allMembersSnap.docs
        .where((d) => d.data()['status'] == 'Vencidos')
        .length;

    return {
      'activeMemberships': membersSnap.docs.length,
      'totalMembers': totalMembers,
      'expiredMembers': expired,
      'monthlyRevenue': totalRevenue,
      'accesses24h': accessSnap.docs.length,
    };
  }
}
