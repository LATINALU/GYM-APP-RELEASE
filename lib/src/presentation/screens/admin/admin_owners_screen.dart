import 'package:flutter/material.dart';
import '../../theme/quantum_colors.dart';

/// Gestión de Dueños - Super Admin
class AdminOwnersScreen extends StatefulWidget {
  const AdminOwnersScreen({super.key});

  @override
  State<AdminOwnersScreen> createState() => _AdminOwnersScreenState();
}

class _AdminOwnersScreenState extends State<AdminOwnersScreen> {
  final List<Map<String, dynamic>> _owners = [
    {'name': 'Carlos Mendoza', 'email': 'carlos@irontemple.com', 'gym': 'Iron Temple GYM', 'members': 342, 'status': 'active', 'since': '2024-01-15', 'plan': 'Premium'},
    {'name': 'Ana García', 'email': 'ana@fitzone.com', 'gym': 'FitZone Pro', 'members': 189, 'status': 'active', 'since': '2024-03-20', 'plan': 'Básico'},
    {'name': 'Roberto Díaz', 'email': 'roberto@powerhouse.com', 'gym': 'PowerHouse', 'members': 567, 'status': 'active', 'since': '2023-11-05', 'plan': 'Enterprise'},
    {'name': 'Laura Torres', 'email': 'laura@flex.com', 'gym': 'Flex Academy', 'members': 98, 'status': 'trial', 'since': '2025-01-28', 'plan': 'Trial'},
    {'name': 'Miguel Ángel', 'email': 'miguel@titan.com', 'gym': 'Titan Fitness', 'members': 421, 'status': 'active', 'since': '2024-06-10', 'plan': 'Premium'},
    {'name': 'Patricia Ruiz', 'email': 'patricia@crossfit.com', 'gym': 'CrossFit Arena', 'members': 234, 'status': 'suspended', 'since': '2024-02-14', 'plan': 'Básico'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QuantumColors.backgroundStart.withValues(alpha: 0.5), QuantumColors.cosmicBlack],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildOwnersTable(),
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
            Text('GESTIÓN DE DUEÑOS', style: QuantumTypography.h1.copyWith(fontSize: 32, letterSpacing: -1, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Administra los propietarios de gimnasios registrados', style: TextStyle(color: Colors.white38)),
          ],
        ),
        Row(
          children: [
            _buildStatBadge('${_owners.length}', 'Total', const Color(0xFFFF6B35)),
            const SizedBox(width: 12),
            _buildStatBadge('${_owners.where((o) => o['status'] == 'active').length}', 'Activos', const Color(0xFF10B981)),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _showCreateOwnerDialog,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Crear Dueño'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOwnersTable() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Dueño', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Gimnasio', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Miembros', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Plan', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Estado', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Desde', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 80),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ..._owners.map((owner) => _buildOwnerRow(owner)),
        ],
      ),
    );
  }

  Widget _buildOwnerRow(Map<String, dynamic> owner) {
    final statusColor = owner['status'] == 'active'
        ? const Color(0xFF10B981)
        : owner['status'] == 'trial'
            ? const Color(0xFFF59E0B)
            : Colors.redAccent;
    final statusLabel = owner['status'] == 'active' ? 'Activo' : owner['status'] == 'trial' ? 'Prueba' : 'Suspendido';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                  child: Text(owner['name'][0], style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(owner['name'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      Text(owner['email'], style: const TextStyle(color: Colors.white30, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(owner['gym'], style: const TextStyle(color: Colors.white60, fontSize: 13))),
          Expanded(child: Text('${owner['members']}', style: const TextStyle(color: Colors.white, fontSize: 13))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(owner['plan'], style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11), textAlign: TextAlign.center),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12)),
              ],
            ),
          ),
          Expanded(child: Text(owner['since'], style: const TextStyle(color: Colors.white30, fontSize: 12))),
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.white24, size: 18), onPressed: () => _showEditOwnerDialog(owner), tooltip: 'Editar'),
                IconButton(icon: Icon(owner['status'] == 'suspended' ? Icons.play_arrow_rounded : Icons.block_rounded, color: Colors.white24, size: 18), onPressed: () => _toggleOwnerStatus(owner), tooltip: owner['status'] == 'suspended' ? 'Activar' : 'Suspender'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CREATE OWNER DIALOG
  // ═══════════════════════════════════════════════════════════════════

  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();
  final _ownerPasswordCtrl = TextEditingController();
  String _selectedGym = 'Iron Temple GYM';

  void _showCreateOwnerDialog() {
    _ownerNameCtrl.clear();
    _ownerEmailCtrl.clear();
    _ownerPhoneCtrl.clear();
    _ownerPasswordCtrl.clear();
    _selectedGym = 'Iron Temple GYM';

    final availableGyms = ['Iron Temple GYM', 'FitZone Pro', 'PowerHouse', 'Flex Academy', 'Titan Fitness', 'CrossFit Arena', 'Nuevo Gym (sin dueño)'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: QuantumColors.surface(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Crear Nuevo Dueño', style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 20)),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: Colors.white24)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('El dueño será vinculado al gimnasio seleccionado', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 24),
                  _ownerField('Nombre Completo *', _ownerNameCtrl, 'Ej: Carlos Mendoza'),
                  const SizedBox(height: 16),
                  _ownerField('Email *', _ownerEmailCtrl, 'Ej: carlos@gym.com'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _ownerField('Teléfono', _ownerPhoneCtrl, '+52 55 1234 5678')),
                      const SizedBox(width: 16),
                      Expanded(child: _ownerField('Contraseña Temporal *', _ownerPasswordCtrl, 'Mínimo 6 caracteres')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Gimnasio Asignado *', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedGym,
                      isExpanded: true,
                      dropdownColor: QuantumColors.surface(),
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      items: availableGyms.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) { if (v != null) setDialogState(() => _selectedGym = v); },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text('El dueño recibirá un email con sus credenciales de acceso', style: TextStyle(color: const Color(0xFFF59E0B).withValues(alpha: 0.8), fontSize: 11))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_ownerNameCtrl.text.trim().isEmpty || _ownerEmailCtrl.text.trim().isEmpty || _ownerPasswordCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nombre, email y contraseña son requeridos'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }
                          if (_ownerPasswordCtrl.text.trim().length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }
                          setState(() {
                            _owners.add({
                              'name': _ownerNameCtrl.text.trim(),
                              'email': _ownerEmailCtrl.text.trim(),
                              'gym': _selectedGym,
                              'members': 0,
                              'status': 'active',
                              'since': DateTime.now().toString().substring(0, 10),
                              'plan': 'Trial',
                            });
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Dueño "${_ownerNameCtrl.text.trim()}" creado y vinculado a $_selectedGym'), backgroundColor: const Color(0xFF10B981)),
                          );
                        },
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('Crear Dueño'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ownerField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          obscureText: label.contains('Contraseña'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.16)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFF6B35))),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  void _toggleOwnerStatus(Map<String, dynamic> owner) {
    final isSuspended = owner['status'] == 'suspended';
    final action = isSuspended ? 'activar' : 'suspender';
    final actionColor = isSuspended ? const Color(0xFF10B981) : Colors.redAccent;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.surface(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿$action a ${owner['name']}?', style: const TextStyle(color: Colors.white)),
        content: Text(
          isSuspended
            ? 'El dueño recuperará acceso a su gimnasio.'
            : 'Se revocará el acceso del dueño a su gimnasio.',
          style: const TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                final idx = _owners.indexOf(owner);
                if (idx >= 0) {
                  _owners[idx] = {
                    ...owner,
                    'status': isSuspended ? 'active' : 'suspended',
                  };
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${owner['name']} ${isSuspended ? "activado" : "suspendido"}'),
                  backgroundColor: actionColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: actionColor),
            child: Text(isSuspended ? 'Activar' : 'Suspender'),
          ),
        ],
      ),
    );
  }

  void _showEditOwnerDialog(Map<String, dynamic> owner) {
    final nameCtrl = TextEditingController(text: owner['name']);
    final emailCtrl = TextEditingController(text: owner['email']);
    String selectedPlan = owner['plan'] as String;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: QuantumColors.surface(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Editar ${owner['name']}', style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditField('Nombre', nameCtrl),
                const SizedBox(height: 16),
                _buildEditField('Email', emailCtrl),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedPlan,
                  dropdownColor: QuantumColors.surface(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Plan',
                    labelStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.03),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Trial', child: Text('Trial')),
                    DropdownMenuItem(value: 'Básico', child: Text('Básico')),
                    DropdownMenuItem(value: 'Premium', child: Text('Premium')),
                    DropdownMenuItem(value: 'Enterprise', child: Text('Enterprise')),
                  ],
                  onChanged: (v) => selectedPlan = v ?? 'Básico',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                setState(() {
                  final idx = _owners.indexOf(owner);
                  if (idx >= 0) {
                    _owners[idx] = {
                      ...owner,
                      'name': nameCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'plan': selectedPlan,
                    };
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dueño actualizado'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFF6B35))),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }
}
