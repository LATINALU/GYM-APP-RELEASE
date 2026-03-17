import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/auth/auth_state_notifier.dart';

class OwnerMembersScreen extends StatefulWidget {
  const OwnerMembersScreen({super.key});
  @override
  State<OwnerMembersScreen> createState() => _OwnerMembersScreenState();
}

class _OwnerMembersScreenState extends State<OwnerMembersScreen> {
  String _search = '';
  String _filter = 'Todos';
  final _filters = ['Todos', 'Activos', 'Vencidos', 'Próx. Vencer', 'Nuevos'];
  List<_MemberData> _members = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadMembersFromFirestore();
  }

  Future<void> _loadMembersFromFirestore() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final auth = AuthStateNotifier.instance;
      final gymId = auth.profile?.gymId?.value;
      if (gymId == null) {
        throw Exception('No se pudo resolver el gimnasio actual');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('gyms')
          .doc(gymId)
          .collection('members')
          .get();

      final loaded = snapshot.docs.map((doc) {
        final d = doc.data();
        return _MemberData(
          id: doc.id,
          name: d['name'] ?? 'Sin nombre',
          plan: d['plan'] ?? 'Sin plan',
          expiry: d['expiry'] ?? '--',
          status: d['status'] ?? 'Activos',
          email: d['email'],
          phone: d['phone'],
          isFrozen: d['isFrozen'] ?? false,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _members = loaded;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _members = [];
        _loadError = 'No se pudieron cargar los miembros.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _members.where((m) {
      final matchSearch = _search.isEmpty || m.name.toLowerCase().contains(_search.toLowerCase());
      final matchFilter = _filter == 'Todos' || m.status == _filter;
      return matchSearch && matchFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6C63FF), onPressed: _showAddMember,
        icon: const Icon(Icons.person_add, color: Colors.white), label: const Text('Nuevo Miembro', style: TextStyle(color: Colors.white))),
      body: CustomScrollView(slivers: [
        const SliverAppBar(expandedHeight: 80, backgroundColor: Color(0xFF0A0A0F), pinned: true,
          flexibleSpace: FlexibleSpaceBar(title: Text('Miembros', style: TextStyle(fontWeight: FontWeight.w700)))),
        // Stats row
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          _kpi('Total', '${_members.length}', Icons.people, const Color(0xFF6C63FF)),
          const SizedBox(width: 8),
          _kpi('Activos', '${_members.where((m) => m.status == 'Activos').length}', Icons.check_circle, const Color(0xFF4ECDC4)),
          const SizedBox(width: 8),
          _kpi('Vencidos', '${_members.where((m) => m.status == 'Vencidos').length}', Icons.error, const Color(0xFFFF6B6B)),
          const SizedBox(width: 8),
          _kpi('Nuevos (30d)', '${_members.where((m) => m.status == 'Nuevos').length}', Icons.fiber_new, const Color(0xFFFFE66D)),
        ]))),
        // Search
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(style: const TextStyle(color: Colors.white), onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(hintText: 'Buscar miembro...', hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: Colors.white24), filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))))),
        // Filters
        SliverToBoxAdapter(child: SizedBox(height: 52, child: ListView.builder(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _filters.length, itemBuilder: (_, i) {
            final f = _filters[i]; final sel = f == _filter;
            return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
              label: Text(f), selected: sel, selectedColor: const Color(0xFF6C63FF),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              labelStyle: TextStyle(color: sel ? Colors.white : Colors.white54, fontSize: 12),
              onSelected: (_) => setState(() => _filter = f)));
          }))),
        // Loading indicator
        if (_isLoading)
          const SliverToBoxAdapter(child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
          )),
        if (!_isLoading && _loadError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 44),
                    const SizedBox(height: 12),
                    Text(_loadError!, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadMembersFromFirestore,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (!_isLoading && _loadError == null && filtered.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline_rounded, color: Colors.white24, size: 56),
                    SizedBox(height: 12),
                    Text('No hay miembros registrados', style: TextStyle(color: Colors.white38)),
                  ],
                ),
              ),
            ),
          ),
        // Member list
        if (!_isLoading && _loadError == null && filtered.isNotEmpty)
          SliverList(delegate: SliverChildBuilderDelegate((_, i) {
            final m = filtered[i];
            return _memberTile(m);
          }, childCount: filtered.length)),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ]),
    );
  }

  Widget _kpi(String label, String val, IconData ic, Color c) => Expanded(child: Container(
    padding: const EdgeInsets.all(12), decoration: BoxDecoration(
      color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: c.withValues(alpha: 0.12))),
    child: Column(children: [
      Icon(ic, color: c, size: 18),
      const SizedBox(height: 4),
      Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    ]),
  ));

  Widget _memberTile(_MemberData m) {
    final statusColors = {'Activos': const Color(0xFF4ECDC4), 'Vencidos': const Color(0xFFFF6B6B),
      'Próx. Vencer': const Color(0xFFFFE66D), 'Nuevos': const Color(0xFF6C63FF)};
    final c = statusColors[m.status] ?? Colors.white38;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: m.isFrozen ? const Color(0xFF12121A).withValues(alpha: 0.5) : const Color(0xFF12121A), 
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: m.isFrozen ? Colors.blue.withValues(alpha: 0.12) : c.withValues(alpha: 0.08))),
      child: Row(children: [
        CircleAvatar(radius: 22, backgroundColor: c.withValues(alpha: 0.15),
          child: Text(m.name.isNotEmpty ? m.name[0] : '?', style: TextStyle(color: c, fontWeight: FontWeight.w700))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Text(m.name, style: TextStyle(
                color: m.isFrozen ? Colors.white38 : Colors.white, 
                fontWeight: FontWeight.w600,
                decoration: m.isFrozen ? TextDecoration.lineThrough : null,
              )),
              if (m.isFrozen) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                  child: const Text('CONGELADO', style: TextStyle(color: Colors.blueAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          Text('${m.plan} · Vence: ${m.expiry}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(m.status, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white24, size: 20),
          color: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (action) => _handleMemberAction(action, m),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'profile', child: Row(
              children: [
                Icon(Icons.person_outline, color: Colors.white54, size: 18),
                SizedBox(width: 12),
                Text('Ver Perfil', style: TextStyle(color: Colors.white)),
              ],
            )),
            const PopupMenuItem(value: 'assign_routine', child: Row(
              children: [
                Icon(Icons.fitness_center_rounded, color: Color(0xFF6C63FF), size: 18),
                SizedBox(width: 12),
                Text('Asignar Rutina', style: TextStyle(color: Color(0xFF6C63FF))),
              ],
            )),
            const PopupMenuItem(value: 'renew', child: Row(
              children: [
                Icon(Icons.refresh_rounded, color: Color(0xFF4ECDC4), size: 18),
                SizedBox(width: 12),
                Text('Renovar', style: TextStyle(color: Color(0xFF4ECDC4))),
              ],
            )),
            PopupMenuItem(value: 'freeze', child: Row(
              children: [
                Icon(m.isFrozen ? Icons.play_arrow_rounded : Icons.ac_unit_rounded, 
                  color: const Color(0xFFFFE66D), size: 18),
                const SizedBox(width: 12),
                Text(m.isFrozen ? 'Descongelar' : 'Congelar', 
                  style: const TextStyle(color: Color(0xFFFFE66D))),
              ],
            )),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'delete', child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B6B), size: 18),
                SizedBox(width: 12),
                Text('Eliminar', style: TextStyle(color: Color(0xFFFF6B6B))),
              ],
            )),
          ],
        ),
      ]),
    );
  }

  void _handleMemberAction(String action, _MemberData member) {
    switch (action) {
      case 'profile':
        _showMemberProfile(member);
        break;
      case 'assign_routine':
        _showAssignRoutineDialog(member);
        break;
      case 'renew':
        _renewMember(member);
        break;
      case 'freeze':
        _toggleFreeze(member);
        break;
      case 'delete':
        _confirmDeleteMember(member);
        break;
    }
  }

  void _showMemberProfile(_MemberData member) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                child: Text(member.name[0], style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Text(member.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(member.email ?? 'Sin email registrado', style: const TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 24),
              _profileRow(Icons.card_membership, 'Plan', member.plan),
              _profileRow(Icons.event, 'Vencimiento', member.expiry),
              _profileRow(Icons.phone_outlined, 'Teléfono', member.phone ?? 'No registrado'),
              _profileRow(Icons.flag_outlined, 'Estado', member.isFrozen ? 'Congelado' : member.status),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 18),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  void _renewMember(_MemberData member) {
    final planCtrl = TextEditingController(text: member.plan);
    final monthsCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Renovar: ${member.name}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: planCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Plan', labelStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.card_membership, color: Color(0xFF6C63FF), size: 20),
                filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: monthsCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Meses a renovar', labelStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.calendar_month, color: Color(0xFF6C63FF), size: 20),
                filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              final months = int.tryParse(monthsCtrl.text) ?? 1;
              final newExpiry = DateTime.now().add(Duration(days: months * 30));
              final formattedExpiry = '${newExpiry.day.toString().padLeft(2, '0')}/${newExpiry.month.toString().padLeft(2, '0')}/${newExpiry.year}';
              
              setState(() {
                final idx = _members.indexOf(member);
                if (idx >= 0) {
                  _members[idx] = member.copyWith(
                    plan: planCtrl.text,
                    expiry: formattedExpiry,
                    status: 'Activos',
                    isFrozen: false,
                  );
                }
              });
              
              Navigator.pop(ctx);
              _logAudit('Renovó membresía de ${member.name} por $months meses', 'MEMBRESÍA');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ ${member.name} renovado hasta $formattedExpiry'),
                  backgroundColor: const Color(0xFF4ECDC4),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ECDC4)),
            child: const Text('Renovar'),
          ),
        ],
      ),
    );
  }

  void _toggleFreeze(_MemberData member) {
    final isFreezing = !member.isFrozen;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isFreezing ? '¿Congelar membresía?' : '¿Descongelar membresía?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isFreezing
              ? '${member.name} no podrá acceder al gym mientras esté congelado. Los días congelados se compensarán al descongelar.'
              : '${member.name} podrá acceder al gym nuevamente.',
          style: const TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final idx = _members.indexOf(member);
                if (idx >= 0) {
                  _members[idx] = member.copyWith(isFrozen: isFreezing);
                }
              });
              Navigator.pop(ctx);
              _logAudit(
                isFreezing ? 'Congeló membresía de ${member.name}' : 'Descongeló membresía de ${member.name}',
                'MEMBRESÍA',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFreezing ? '❄ Membresía de ${member.name} congelada' : '☀ Membresía de ${member.name} descongelada'),
                  backgroundColor: const Color(0xFFFFE66D).withValues(alpha: 0.9),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isFreezing ? Colors.blueAccent : const Color(0xFF4ECDC4),
            ),
            child: Text(isFreezing ? 'Congelar' : 'Descongelar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMember(_MemberData member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('⚠ Eliminar Miembro', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de eliminar a ${member.name}?\n\nEsta acción no se puede deshacer y quedará registrada en la auditoría.',
          style: const TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _members.remove(member));
              Navigator.pop(ctx);
              _logAudit('Eliminó al miembro ${member.name}', 'MEMBRESÍA');
              
              // Try to delete from Firestore too
              _deleteFromFirestore(member);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${member.name} eliminado'),
                  backgroundColor: const Color(0xFFFF6B6B),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  action: SnackBarAction(
                    label: 'DESHACER',
                    textColor: Colors.white,
                    onPressed: () {
                      setState(() => _members.add(member));
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFromFirestore(_MemberData member) async {
    try {
      final auth = AuthStateNotifier.instance;
      final gymId = auth.profile?.gymId?.value;
      if (gymId == null || member.id == null) return;

      await FirebaseFirestore.instance
          .collection('gyms')
          .doc(gymId)
          .collection('members')
          .doc(member.id)
          .delete();
    } catch (_) {}
  }

  Future<void> _logAudit(String action, String module) async {
    try {
      final auth = AuthStateNotifier.instance;
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'who': auth.profile?.displayName ?? 'Owner',
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'module': module,
      });
    } catch (_) {}
  }

  void _showAddMember() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedPlan = 'Mensual';

    showModalBottomSheet(
      context: context, 
      backgroundColor: const Color(0xFF1A1A2E), 
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nuevo Miembro', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _inputField('Nombre completo', Icons.person, nameCtrl),
            const SizedBox(height: 12),
            _inputField('Email', Icons.email, emailCtrl),
            const SizedBox(height: 12),
            _inputField('Teléfono', Icons.phone, phoneCtrl),
            const SizedBox(height: 12),
            // Plan dropdown
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonFormField<String>(
                            value: selectedPlan,
                dropdownColor: const Color(0xFF1A1A2E),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Plan',
                  labelStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.card_membership, color: Color(0xFF6C63FF), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: 'Mensual', child: Text('Mensual')),
                  DropdownMenuItem(value: 'Trimestral', child: Text('Trimestral')),
                  DropdownMenuItem(value: 'Premium Mensual', child: Text('Premium Mensual')),
                  DropdownMenuItem(value: 'Premium Anual', child: Text('Premium Anual')),
                  DropdownMenuItem(value: 'Anual', child: Text('Anual')),
                ],
                onChanged: (v) => setSheetState(() => selectedPlan = v ?? 'Mensual'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre es requerido'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }
                
                final months = selectedPlan.contains('Anual') ? 12 : selectedPlan.contains('Trimestral') ? 3 : 1;
                final expiry = DateTime.now().add(Duration(days: months * 30));
                final formattedExpiry = '${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}';
                
                final newMember = _MemberData(
                  name: nameCtrl.text.trim(),
                  plan: selectedPlan,
                  expiry: formattedExpiry,
                  status: 'Nuevos',
                  email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                );
                
                setState(() => _members.insert(0, newMember));
                _saveMemberToFirestore(newMember);
                Navigator.pop(ctx);
                _logAudit('Registró nuevo miembro: ${newMember.name}', 'REGISTRO');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ ${newMember.name} registrado exitosamente'),
                    backgroundColor: const Color(0xFF4ECDC4),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Registrar Miembro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
          ]),
        ),
      ),
    );
  }

  Future<void> _saveMemberToFirestore(_MemberData member) async {
    try {
      final auth = AuthStateNotifier.instance;
      final gymId = auth.profile?.gymId?.value;
      if (gymId == null) return;

      await FirebaseFirestore.instance
          .collection('gyms')
          .doc(gymId)
          .collection('members')
          .add({
        'name': member.name,
        'plan': member.plan,
        'expiry': member.expiry,
        'status': member.status,
        'email': member.email,
        'phone': member.phone,
        'isFrozen': member.isFrozen,
        'registeredAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Widget _inputField(String label, IconData ic, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(ic, color: const Color(0xFF6C63FF), size: 20), filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  void _showAssignRoutineDialog(_MemberData member) async {
    final auth = AuthStateNotifier.instance;
    final gymId = auth.profile?.gymId?.value;
    
    if (gymId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener el ID del gimnasio'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Fetch available routines from Firestore
    final routinesSnapshot = await FirebaseFirestore.instance
        .collection('routines')
        .where('gymId', isEqualTo: gymId)
        .where('isActive', isEqualTo: true)
        .get();

    if (!mounted) return;

    if (routinesSnapshot.docs.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Sin rutinas disponibles', style: TextStyle(color: Colors.white)),
          content: const Text(
            'No hay rutinas activas en tu gimnasio. Crea rutinas en el Training Forge primero.',
            style: TextStyle(color: Colors.white54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido', style: TextStyle(color: Color(0xFF6C63FF))),
            ),
          ],
        ),
      );
      return;
    }

    final routines = routinesSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Sin nombre',
        'difficulty': data['difficulty'] ?? 'intermediate',
        'focus': data['focus'] ?? 'general',
        'exerciseCount': (data['exercises'] as List?)?.length ?? 0,
      };
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Asignar Rutina', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Para: ${member.name}', style: const TextStyle(color: Colors.white38, fontSize: 14)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Selecciona una rutina:', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: routines.length,
                  itemBuilder: (_, i) {
                    final routine = routines[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fitness_center, color: Color(0xFF6C63FF), size: 20),
                        ),
                        title: Text(routine['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${routine['exerciseCount']} ejercicios · ${routine['difficulty']} · ${routine['focus']}',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                        onTap: () {
                          Navigator.pop(ctx);
                          _confirmAssignRoutine(member, routine);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmAssignRoutine(_MemberData member, Map<String, dynamic> routine) {
    final startDateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final endDateCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0]);
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar Asignación', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rutina: ${routine['name']}', style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
              Text('Cliente: ${member.name}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              TextField(
                controller: startDateCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Fecha de inicio',
                  labelStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endDateCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Fecha de fin (opcional)',
                  labelStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notas (opcional)',
                  labelStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _assignRoutineToClient(member, routine, startDateCtrl.text, endDateCtrl.text, notesCtrl.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            child: const Text('Asignar'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignRoutineToClient(
    _MemberData member,
    Map<String, dynamic> routine,
    String startDate,
    String endDate,
    String notes,
  ) async {
    try {
      final auth = AuthStateNotifier.instance;
      final assignerId = auth.profile?.uid;
      final gymId = auth.profile?.gymId?.value;
      final parsedStartDate = DateTime.tryParse(startDate);
      final parsedEndDate = endDate.isNotEmpty ? DateTime.tryParse(endDate) : null;

      if (assignerId == null || member.id == null || gymId == null) {
        throw Exception('Datos de usuario incompletos');
      }
      if (parsedStartDate == null) {
        throw Exception('La fecha de inicio no es válida');
      }
      if (endDate.isNotEmpty && parsedEndDate == null) {
        throw Exception('La fecha de fin no es válida');
      }

      await FirebaseFirestore.instance.collection('assignments').add({
        'routineId': routine['id'],
        'clientId': member.id,
        'assignedById': assignerId,
        'assignedAt': DateTime.now().toIso8601String(),
        'startDate': parsedStartDate.toIso8601String(),
        'endDate': parsedEndDate?.toIso8601String(),
        'notes': notes.isNotEmpty ? notes : null,
        'status': 'active',
        'gymId': gymId,
      });

      _logAudit('Asignó rutina "${routine['name']}" a ${member.name}', 'RUTINAS');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Rutina "${routine['name']}" asignada a ${member.name}'),
            backgroundColor: const Color(0xFF4ECDC4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar rutina: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _MemberData {
  final String? id;
  final String name, plan, expiry, status;
  final String? email, phone;
  final bool isFrozen;

  _MemberData({
    this.id,
    required this.name, 
    required this.plan, 
    required this.expiry, 
    required this.status,
    this.email,
    this.phone,
    this.isFrozen = false,
  });

  _MemberData copyWith({
    String? plan,
    String? expiry,
    String? status,
    bool? isFrozen,
  }) {
    return _MemberData(
      id: id,
      name: name,
      plan: plan ?? this.plan,
      expiry: expiry ?? this.expiry,
      status: status ?? this.status,
      email: email,
      phone: phone,
      isFrozen: isFrozen ?? this.isFrozen,
    );
  }
}
