import 'package:cloud_firestore/cloud_firestore.dart';

/// Permisos de módulo que un staff puede tener
enum StaffPermission {
  dashboard,
  memberManagement,
  pos,
  routineBuilder,
  exerciseAtlas,
  cashReconciliation,
  finance,
  retention,
  settings;

  String get displayName {
    switch (this) {
      case StaffPermission.dashboard:
        return 'Dashboard';
      case StaffPermission.memberManagement:
        return 'Gestión Miembros';
      case StaffPermission.pos:
        return 'Punto de Venta';
      case StaffPermission.routineBuilder:
        return 'Constructor Rutinas';
      case StaffPermission.exerciseAtlas:
        return 'Atlas Ejercicios';
      case StaffPermission.cashReconciliation:
        return 'Cierre de Caja';
      case StaffPermission.finance:
        return 'Finanzas';
      case StaffPermission.retention:
        return 'Retención IA';
      case StaffPermission.settings:
        return 'Configuración';
    }
  }
}

/// Application Service para gestión de staff y permisos del gimnasio.
class StaffService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene todos los miembros del staff
  Future<List<Map<String, dynamic>>> getAllStaff() async {
    try {
      final snapshot = await _firestore.collection('staff').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('No se pudo cargar el staff: $e');
    }
  }

  /// Agrega un nuevo miembro del staff
  Future<String> addStaffMember({
    required String name,
    required String email,
    required String role,
    List<String> permissions = const [],
  }) async {
    final doc = await _firestore.collection('staff').add({
      'name': name,
      'email': email,
      'role': role,
      'isActive': true,
      'permissions': permissions,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Registro de auditoría
    await _firestore.collection('audit_logs').add({
      'who': 'Administrador',
      'action': 'REGISTRÓ nuevo staff: $name ($role)',
      'timestamp': FieldValue.serverTimestamp(),
      'module': 'REGISTRO',
    });

    return doc.id;
  }

  /// Actualiza permisos de un staff member
  Future<void> updatePermissions(
    String staffId,
    List<String> permissions,
  ) async {
    await _firestore.collection('staff').doc(staffId).update({
      'permissions': permissions,
    });

    await _firestore.collection('audit_logs').add({
      'who': 'Administrador',
      'action': 'ACTUALIZÓ permisos de staff $staffId',
      'timestamp': FieldValue.serverTimestamp(),
      'module': 'ROLES',
    });
  }

  /// Activa/desactiva el acceso de un staff member
  Future<void> toggleAccess(String staffId, bool isActive, String? name) async {
    await _firestore.collection('staff').doc(staffId).update({
      'isActive': isActive,
    });

    await _firestore.collection('audit_logs').add({
      'who': 'Administrador',
      'action': isActive ? 'ACTIVÓ acceso a $name' : 'DESACTIVÓ acceso a $name',
      'timestamp': FieldValue.serverTimestamp(),
      'module': 'SEGURIDAD',
    });
  }

  /// Obtiene los logs de auditoría recientes
  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 10}) async {
    try {
      final snapshot =
          await _firestore
              .collection('audit_logs')
              .orderBy('timestamp', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('No se pudo cargar la auditoría de staff: $e');
    }
  }
}
