import 'package:flutter/material.dart';
import '../../theme/quantum_colors.dart';

/// Gestión de Gimnasios - Super Admin
/// CRUD de gimnasios, suspender/activar, ver métricas por gym
class AdminGymsScreen extends StatefulWidget {
  const AdminGymsScreen({super.key});

  @override
  State<AdminGymsScreen> createState() => _AdminGymsScreenState();
}

class _AdminGymsScreenState extends State<AdminGymsScreen> {
  String _filter = 'Todos';
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _gyms = [
    {'id': '1', 'name': 'Iron Temple GYM', 'owner': 'Carlos Mendoza', 'members': 342, 'staff': 8, 'status': 'active', 'plan': 'Premium', 'city': 'CDMX', 'monthlyRevenue': 85000.0, 'createdAt': '2024-01-15'},
    {'id': '2', 'name': 'FitZone Pro', 'owner': 'Ana García', 'members': 189, 'staff': 4, 'status': 'active', 'plan': 'Básico', 'city': 'Guadalajara', 'monthlyRevenue': 32000.0, 'createdAt': '2024-03-20'},
    {'id': '3', 'name': 'PowerHouse', 'owner': 'Roberto Díaz', 'members': 567, 'staff': 12, 'status': 'active', 'plan': 'Enterprise', 'city': 'Monterrey', 'monthlyRevenue': 145000.0, 'createdAt': '2023-11-05'},
    {'id': '4', 'name': 'Flex Academy', 'owner': 'Laura Torres', 'members': 98, 'staff': 3, 'status': 'trial', 'plan': 'Trial', 'city': 'Puebla', 'monthlyRevenue': 0.0, 'createdAt': '2025-01-28'},
    {'id': '5', 'name': 'Titan Fitness', 'owner': 'Miguel Ángel', 'members': 421, 'staff': 9, 'status': 'active', 'plan': 'Premium', 'city': 'CDMX', 'monthlyRevenue': 98000.0, 'createdAt': '2024-06-10'},
    {'id': '6', 'name': 'CrossFit Arena', 'owner': 'Patricia Ruiz', 'members': 234, 'staff': 6, 'status': 'suspended', 'plan': 'Básico', 'city': 'Cancún', 'monthlyRevenue': 0.0, 'createdAt': '2024-02-14'},
  ];

  List<Map<String, dynamic>> get _filteredGyms {
    var filtered = _gyms;
    if (_filter != 'Todos') {
      final statusMap = {'Activos': 'active', 'Suspendidos': 'suspended', 'Prueba': 'trial'};
      filtered = filtered.where((g) => g['status'] == statusMap[_filter]).toList();
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((g) =>
        g['name'].toString().toLowerCase().contains(query) ||
        g['owner'].toString().toLowerCase().contains(query) ||
        g['city'].toString().toLowerCase().contains(query)
      ).toList();
    }
    return filtered;
  }

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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildFiltersAndSearch(),
            const SizedBox(height: 24),
            _buildGymsGrid(),
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
            Text('GESTIÓN DE GIMNASIOS', style: QuantumTypography.h1.copyWith(fontSize: 32, letterSpacing: -1, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Administra todos los gimnasios de la plataforma', style: TextStyle(color: Colors.white38)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddGymDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nuevo Gimnasio'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersAndSearch() {
    final filters = ['Todos', 'Activos', 'Suspendidos', 'Prueba'];
    return Row(
      children: [
        ...filters.map((f) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(f),
            selected: _filter == f,
            onSelected: (_) => setState(() => _filter = f),
            selectedColor: const Color(0xFFFF6B35).withValues(alpha: 0.2),
            backgroundColor: QuantumColors.surface(),
            labelStyle: TextStyle(color: _filter == f ? const Color(0xFFFF6B35) : Colors.white38, fontSize: 13),
            side: BorderSide(color: _filter == f ? const Color(0xFFFF6B35).withValues(alpha: 0.3) : Colors.white10),
          ),
        )),
        const Spacer(),
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar gimnasio, dueño o ciudad...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white24, size: 20),
              filled: true,
              fillColor: QuantumColors.surface(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGymsGrid() {
    final gyms = _filteredGyms;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.3,
      ),
      itemCount: gyms.length,
      itemBuilder: (context, index) => _buildGymCard(gyms[index]),
    );
  }

  Widget _buildGymCard(Map<String, dynamic> gym) {
    final statusColor = gym['status'] == 'active'
        ? const Color(0xFF10B981)
        : gym['status'] == 'trial'
            ? const Color(0xFFF59E0B)
            : Colors.redAccent;
    final statusLabel = gym['status'] == 'active' ? 'Activo' : gym['status'] == 'trial' ? 'Prueba' : 'Suspendido';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Color(0xFFFF6B35), size: 20),
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(gym['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${gym['city']} • ${gym['owner']}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const Spacer(),
          Row(
            children: [
              _buildMiniStat(Icons.people_alt_rounded, '${gym['members']}', 'Miembros'),
              const SizedBox(width: 16),
              _buildMiniStat(Icons.badge_rounded, '${gym['staff']}', 'Staff'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(gym['plan'], style: const TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showGymDetails(gym),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: const BorderSide(color: Colors.white10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Detalles', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _toggleGymStatus(gym),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gym['status'] == 'suspended' ? const Color(0xFF10B981) : Colors.redAccent.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(gym['status'] == 'suspended' ? 'Activar' : 'Suspender', style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white24, size: 14),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  final _gymNameCtrl = TextEditingController();
  final _gymCityCtrl = TextEditingController();
  final _gymAddressCtrl = TextEditingController();
  final _gymPhoneCtrl = TextEditingController();
  final _gymEmailCtrl = TextEditingController();
  String _gymPlan = 'Trial';

  void _showAddGymDialog() {
    _gymNameCtrl.clear();
    _gymCityCtrl.clear();
    _gymAddressCtrl.clear();
    _gymPhoneCtrl.clear();
    _gymEmailCtrl.clear();
    _gymPlan = 'Trial';

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
                      Text('Registrar Nuevo Gimnasio', style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 20)),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: Colors.white24)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _dialogField('Nombre del Gimnasio *', _gymNameCtrl, 'Ej: Iron Temple GYM'),
                  const SizedBox(height: 16),
                  _dialogField('Ciudad *', _gymCityCtrl, 'Ej: CDMX'),
                  const SizedBox(height: 16),
                  _dialogField('Dirección', _gymAddressCtrl, 'Dirección completa'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _dialogField('Teléfono', _gymPhoneCtrl, '+52 55 1234 5678')),
                      const SizedBox(width: 16),
                      Expanded(child: _dialogField('Email', _gymEmailCtrl, 'contacto@gym.com')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Plan Inicial', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButton<String>(
                      value: _gymPlan,
                      isExpanded: true,
                      dropdownColor: QuantumColors.surface(),
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      items: ['Trial', 'Básico', 'Premium', 'Enterprise'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (v) { if (v != null) setDialogState(() => _gymPlan = v); },
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
                          if (_gymNameCtrl.text.trim().isEmpty || _gymCityCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nombre y ciudad son requeridos'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }
                          setState(() {
                            _gyms.add({
                              'id': '${_gyms.length + 1}',
                              'name': _gymNameCtrl.text.trim(),
                              'owner': 'Sin asignar',
                              'members': 0,
                              'staff': 0,
                              'status': 'trial',
                              'plan': _gymPlan,
                              'city': _gymCityCtrl.text.trim(),
                              'monthlyRevenue': 0.0,
                              'createdAt': DateTime.now().toString().substring(0, 10),
                            });
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gimnasio "${_gymNameCtrl.text.trim()}" creado exitosamente'), backgroundColor: const Color(0xFF10B981)),
                          );
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Crear Gimnasio'),
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

  Widget _dialogField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
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

  void _showGymDetails(Map<String, dynamic> gym) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QuantumColors.surface(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(gym['name'], style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Dueño', gym['owner']),
            _detailRow('Ciudad', gym['city']),
            _detailRow('Miembros', '${gym['members']}'),
            _detailRow('Staff', '${gym['staff']}'),
            _detailRow('Plan', gym['plan']),
            _detailRow('Ingreso Mensual', '\$${gym['monthlyRevenue']}'),
            _detailRow('Creado', gym['createdAt']),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _toggleGymStatus(Map<String, dynamic> gym) {
    final isSuspended = gym['status'] == 'suspended';
    final action = isSuspended ? 'activar' : 'suspender';
    final actionColor = isSuspended ? const Color(0xFF10B981) : Colors.redAccent;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.surface(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿$action ${gym['name']}?', style: const TextStyle(color: Colors.white)),
        content: Text(
          isSuspended
            ? 'El gimnasio volverá a estar operativo para dueño, staff y clientes.'
            : 'Se bloqueará el acceso al gimnasio para todos los usuarios.',
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
                final idx = _gyms.indexWhere((g) => g['id'] == gym['id']);
                if (idx >= 0) {
                  _gyms[idx] = {
                    ..._gyms[idx],
                    'status': isSuspended ? 'active' : 'suspended',
                  };
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${gym['name']} ${isSuspended ? "activado" : "suspendido"}'),
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
}
