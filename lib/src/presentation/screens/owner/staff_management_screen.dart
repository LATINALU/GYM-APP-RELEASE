import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/theme.dart';
import '../../theme/gym_widgets.dart';
import '../../../../core/auth/auth_state_notifier.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 48),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lista de Staff
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Equipo de Trabajo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildStaffGrid(),
                    ],
                  ),
                ),

                const SizedBox(width: 48),

                // Auditoría Rápida
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registro de Auditoría',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildAuditLogs(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión de Staff',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Control de roles, auditoría inmutable y seguridad por Custom Claims.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
        GymButton(
          text: 'Agregar Personal',
          icon: Icons.person_add_outlined,
          onPressed: _showAddStaffDialog,
        ),
      ],
    );
  }

  Widget _buildStaffGrid() {
    final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
    if (gymId == null) {
      return _buildStatePanel(
        icon: Icons.lock_outline_rounded,
        title: 'Contexto de gimnasio no disponible',
        subtitle:
            'No se pudo identificar el gimnasio activo para cargar el staff.',
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('staff')
              .where('gymId', isEqualTo: gymId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildStatePanel(
            icon: Icons.error_outline_rounded,
            title: 'No se pudo cargar el staff',
            subtitle: 'Intenta nuevamente en unos minutos.',
          );
        }

        final staff = snapshot.data?.docs ?? [];
        if (staff.isEmpty) {
          return _buildStatePanel(
            icon: Icons.groups_2_outlined,
            title: 'Aún no hay personal registrado',
            subtitle: 'Agrega tu primer miembro de staff para comenzar.',
            actionLabel: 'Agregar personal',
            onAction: _showAddStaffDialog,
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: staff.length,
          itemBuilder: (context, index) {
            final doc = staff[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildStaffCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> member, String id) {
    final role = member['role'] ?? 'Staff';
    final isActive = member['isActive'] ?? true;

    Color roleColor;
    if (role == 'Dueño') {
      roleColor = const Color(0xFFFFD700);
    } else if (role == 'Entrenador') {
      roleColor = const Color(0xFF4D49FF);
    } else {
      roleColor = const Color(0xFF00E676);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF151725),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(member['name'] ?? 'S', roleColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'] ?? 'Staff',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildRoleBadge(role, roleColor),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (v) => _toggleStaffAccess(id, v, member['name']),
                activeThumbColor: const Color(0xFF00E676),
                inactiveThumbColor: Colors.white24,
                inactiveTrackColor: Colors.white10,
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isActive ? 'ACCESO ACTIVO' : 'ACCESO REVOCADO',
                style: TextStyle(
                  color:
                      isActive
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF3366),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GymButton(
                text: 'Editar Permisos',
                style: GymButtonStyle.ghost,
                size: GymButtonSize.small,
                onPressed: () => _showEditPermissionsDialog(member, id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.substring(0, 1).toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _toggleStaffAccess(String id, bool status, String? name) async {
    final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
    await _firestore.collection('staff').doc(id).update({'isActive': status});

    // Auditoría
    await _firestore.collection('audit_logs').add({
      'gymId': gymId,
      'who': AuthStateNotifier.instance.profile?.displayName ?? 'Administrador',
      'action': status ? 'ACTIVÓ acceso a $name' : 'DESACTIVÓ acceso a $name',
      'timestamp': FieldValue.serverTimestamp(),
      'module': 'SEGURIDAD',
    });
  }

  Widget _buildAuditLogs() {
    final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
    if (gymId == null) {
      return _buildStatePanel(
        icon: Icons.lock_outline_rounded,
        title: 'Sin contexto de gimnasio',
        subtitle: 'No se puede cargar la auditoría sin un gymId válido.',
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('audit_logs')
              .where('gymId', isEqualTo: gymId)
              .orderBy('timestamp', descending: true)
              .limit(10)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildStatePanel(
            icon: Icons.hourglass_top_rounded,
            title: 'Cargando auditoría...',
            subtitle: 'Esto puede tardar unos segundos.',
          );
        }

        if (snapshot.hasError) {
          return _buildStatePanel(
            icon: Icons.error_outline_rounded,
            title: 'No se pudo cargar la auditoría',
            subtitle: 'Verifica permisos y conexión con Firestore.',
          );
        }

        if (!snapshot.hasData || (snapshot.data?.docs.isEmpty ?? true)) {
          return _buildStatePanel(
            icon: Icons.history_toggle_off_rounded,
            title: 'Sin movimientos recientes',
            subtitle: 'Los eventos de seguridad aparecerán aquí.',
          );
        }

        final logs = snapshot.data!.docs;
        return _buildAuditLogContainer(
          logs.map((doc) {
            final log = doc.data() as Map<String, dynamic>;
            final time =
                (log['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            return _buildAuditLogEntry(
              log['who'] ?? 'Sistema',
              log['action'] ?? '',
              log['module'] ?? '',
              time,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAuditLogContainer(List<Widget> entries) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF151725),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(children: entries),
    );
  }

  Widget _buildStatePanel({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF151725),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white38, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            GymButton(text: actionLabel, onPressed: onAction),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditLogEntry(
    String who,
    String action,
    String module,
    DateTime time,
  ) {
    Color moduleColor;
    switch (module) {
      case 'SEGURIDAD':
        moduleColor = Colors.red;
        break;
      case 'ROLES':
        moduleColor = Colors.blue;
        break;
      case 'REGISTRO':
        moduleColor = Colors.green;
        break;
      default:
        moduleColor = const Color(0xFF4D49FF);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: moduleColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$who ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: action,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: moduleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        module,
                        style: TextStyle(
                          color: moduleColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedRole = 'Staff';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: Row(
                    children: [
                      const Text(
                        'Agregar personal',
                        style: TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dialogField('Nombre completo', Icons.person, nameCtrl),
                        const SizedBox(height: 12),
                        _dialogField('Email', Icons.email_outlined, emailCtrl),
                        const SizedBox(height: 12),
                        _dialogField(
                          'Teléfono',
                          Icons.phone_outlined,
                          phoneCtrl,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedRole,
                            dropdownColor: const Color(0xFF1A1A2E),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Rol',
                              labelStyle: const TextStyle(
                                color: Colors.white38,
                              ),
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                color: Color(0xFF4D49FF),
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Recepcionista',
                                child: Text('Recepcionista'),
                              ),
                              DropdownMenuItem(
                                value: 'Entrenador',
                                child: Text('Entrenador'),
                              ),
                              DropdownMenuItem(
                                value: 'Staff',
                                child: Text('Staff General'),
                              ),
                              DropdownMenuItem(
                                value: 'Limpieza',
                                child: Text('Limpieza'),
                              ),
                            ],
                            onChanged:
                                (v) => setDialogState(
                                  () => selectedRole = v ?? 'Staff',
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('El nombre es requerido'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          final gymId =
                              AuthStateNotifier.instance.profile?.gymId?.value;
                          await _firestore.collection('staff').add({
                            'gymId': gymId,
                            'name': nameCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                            'role': selectedRole,
                            'isActive': true,
                            'permissions': _defaultPermissions(selectedRole),
                            'registeredAt': FieldValue.serverTimestamp(),
                          });
                          await _firestore.collection('audit_logs').add({
                            'gymId': gymId,
                            'who':
                                AuthStateNotifier
                                    .instance
                                    .profile
                                    ?.displayName ??
                                'Owner',
                            'action':
                                'Registró nuevo staff: ${nameCtrl.text.trim()} como $selectedRole',
                            'timestamp': FieldValue.serverTimestamp(),
                            'module': 'REGISTRO',
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✓ ${nameCtrl.text.trim()} agregado como $selectedRole',
                                ),
                                backgroundColor: const Color(0xFF00E676),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4D49FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Agregar'),
                    ),
                  ],
                ),
          ),
    );
  }

  Map<String, bool> _defaultPermissions(String role) {
    switch (role) {
      case 'Recepcionista':
        return {
          'cobros': true,
          'check_in': true,
          'ventas': true,
          'miembros_lectura': true,
          'miembros_editar': false,
          'finanzas': false,
          'staff': false,
        };
      case 'Entrenador':
        return {
          'cobros': false,
          'check_in': true,
          'ventas': false,
          'miembros_lectura': true,
          'miembros_editar': false,
          'finanzas': false,
          'staff': false,
        };
      default:
        return {
          'cobros': false,
          'check_in': true,
          'ventas': false,
          'miembros_lectura': false,
          'miembros_editar': false,
          'finanzas': false,
          'staff': false,
        };
    }
  }

  void _showEditPermissionsDialog(Map<String, dynamic> member, String id) {
    final perms = Map<String, bool>.from(
      member['permissions'] ?? _defaultPermissions(member['role'] ?? 'Staff'),
    );

    final permLabels = {
      'cobros': 'Cobrar membresías',
      'check_in': 'Check-in / Acceso',
      'ventas': 'Punto de Venta (POS)',
      'miembros_lectura': 'Ver miembros',
      'miembros_editar': 'Editar miembros',
      'finanzas': 'Ver finanzas',
      'staff': 'Gestionar staff',
    };

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: Text(
                    'Permisos: ${member['name']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: SizedBox(
                    width: 380,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          perms.entries
                              .map<Widget>((e) => CheckboxListTile(
                                title: Text(
                                  permLabels[e.key] ?? e.key,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                value: e.value,
                                activeColor: const Color(0xFF4D49FF),
                                onChanged:
                                    (v) => setDialogState(
                                      () => perms[e.key] = v ?? false,
                                    ),
                                dense: true,
                              ))
                              .toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          final gymId =
                              AuthStateNotifier.instance.profile?.gymId?.value;
                          await _firestore.collection('staff').doc(id).update({
                            'permissions': perms,
                          });
                          await _firestore.collection('audit_logs').add({
                            'gymId': gymId,
                            'who':
                                AuthStateNotifier
                                    .instance
                                    .profile
                                    ?.displayName ??
                                'Owner',
                            'action': 'Actualizó permisos de ${member['name']}',
                            'timestamp': FieldValue.serverTimestamp(),
                            'module': 'ROLES',
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✓ Permisos de ${member['name']} actualizados',
                                ),
                                backgroundColor: const Color(0xFF00E676),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4D49FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _dialogField(
    String label,
    IconData icon,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: const Color(0xFF4D49FF), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
