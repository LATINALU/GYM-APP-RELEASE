import 'package:flutter/material.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../../infrastructure/config/di.dart';
import '../../../infrastructure/adapters/firebase/firebase_owner_member_repository.dart';
import '../../../domain/services/membership_renewal.dart';
import '../../theme/quantum_colors.dart';

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

      final repo = getIt<FirebaseOwnerMemberRepository>();
      final membersData = await repo.loadMembers(gymId);

      final loaded = membersData.map((d) => _MemberData(
        id: d['id'],
        name: d['name'],
        plan: d['plan'],
        expiry: d['expiry'],
        status: d['status'],
        email: d['email'],
        phone: d['phone'],
        isFrozen: d['isFrozen'] ?? false,
      )).toList();

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
      backgroundColor: QuantumColors.cosmicBlack,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: QuantumColors.holoPurple, onPressed: _showAddMember,
        icon: const Icon(Icons.person_add, color: Colors.white), label: const Text('Nuevo Miembro', style: TextStyle(color: Colors.white))),
      body: RefreshIndicator(
        color: QuantumColors.holoPurple,
        onRefresh: _loadMembersFromFirestore,
        child: CustomScrollView(slivers: [
        const SliverAppBar(expandedHeight: 80, backgroundColor: QuantumColors.cosmicBlack, pinned: true,
          flexibleSpace: FlexibleSpaceBar(title: Text('Miembros', style: TextStyle(fontWeight: FontWeight.w700)))),
        // Stats row
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          _kpi('Total', '${_members.length}', Icons.people, QuantumColors.holoPurple),
          const SizedBox(width: 8),
          _kpi('Activos', '${_members.where((m) => m.status == 'Activos').length}', Icons.check_circle, QuantumColors.matrixCyan),
          const SizedBox(width: 8),
          _kpi('Vencidos', '${_members.where((m) => m.status == 'Vencidos').length}', Icons.error, QuantumColors.error),
          const SizedBox(width: 8),
          _kpi('Nuevos (30d)', '${_members.where((m) => m.status == 'Nuevos').length}', Icons.fiber_new, QuantumColors.warning),
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
              label: Text(f), selected: sel, selectedColor: QuantumColors.holoPurple,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              labelStyle: TextStyle(color: sel ? Colors.white : Colors.white54, fontSize: 12),
              onSelected: (_) => setState(() => _filter = f)));
          }))),
        // Loading indicator
        if (_isLoading)
          const SliverToBoxAdapter(child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: QuantumColors.holoPurple)),
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
      ),
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
    final statusColors = {'Activos': QuantumColors.matrixCyan, 'Vencidos': QuantumColors.error,
      'Próx. Vencer': QuantumColors.warning, 'Nuevos': QuantumColors.holoPurple};
    final c = statusColors[m.status] ?? Colors.white38;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: m.isFrozen ? QuantumColors.voidGray.withValues(alpha: 0.5) : QuantumColors.voidGray, 
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
          color: QuantumColors.voidGray,
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
                Icon(Icons.fitness_center_rounded, color: QuantumColors.holoPurple, size: 18),
                SizedBox(width: 12),
                Text('Asignar Rutina', style: TextStyle(color: QuantumColors.holoPurple)),
              ],
            )),
            const PopupMenuItem(value: 'renew', child: Row(
              children: [
                Icon(Icons.payments_rounded, color: QuantumColors.matrixCyan, size: 18),
                SizedBox(width: 12),
                Text('Cobrar / Renovar', style: TextStyle(color: QuantumColors.matrixCyan)),
              ],
            )),
            PopupMenuItem(value: 'freeze', child: Row(
              children: [
                Icon(m.isFrozen ? Icons.play_arrow_rounded : Icons.ac_unit_rounded, 
                  color: QuantumColors.warning, size: 18),
                const SizedBox(width: 12),
                Text(m.isFrozen ? 'Descongelar' : 'Congelar', 
                  style: const TextStyle(color: QuantumColors.warning)),
              ],
            )),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'delete', child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, color: QuantumColors.error, size: 18),
                SizedBox(width: 12),
                Text('Eliminar', style: TextStyle(color: QuantumColors.error)),
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
        backgroundColor: QuantumColors.voidGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: QuantumColors.holoPurple.withValues(alpha: 0.15),
                child: Text(member.name[0], style: const TextStyle(color: QuantumColors.holoPurple, fontSize: 32, fontWeight: FontWeight.bold)),
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
                    backgroundColor: QuantumColors.holoPurple,
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

  /// Cobro de membresía real: registra el pago en `payments` (alimenta el
  /// BI y las finanzas) y renueva el vencimiento del miembro en Firestore.
  Future<void> _renewMember(_MemberData member) async {
    final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
    final registeredBy = AuthStateNotifier.instance.profile?.uid;
    if (gymId == null || registeredBy == null || member.id == null) return;

    final repo = getIt<FirebaseOwnerMemberRepository>();
    List<Map<String, dynamic>> plans = const [];
    try {
      plans = await repo.loadMembershipPlans(gymId);
    } catch (_) {
      // Sin planes configurados: el diálogo permite monto personalizado
    }
    if (!mounted) return;

    // null = monto/duración personalizados
    Map<String, dynamic>? selectedPlan = plans.isNotEmpty ? plans.first : null;
    final amountCtrl = TextEditingController(
        text: selectedPlan != null
            ? (selectedPlan['price'] as double).toStringAsFixed(0)
            : '');
    final monthsCtrl = TextEditingController(text: '1');
    var method = 'Efectivo';
    var saving = false;

    int durationDays() => selectedPlan != null
        ? selectedPlan!['durationDays'] as int
        : (int.tryParse(monthsCtrl.text) ?? 1) * 30;

    String previewExpiry() => MembershipRenewal.formatExpiry(
          MembershipRenewal.computeNewExpiry(
            currentExpiry: member.expiry,
            days: durationDays(),
          ),
        );

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: QuantumColors.voidGray,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Cobrar membresía: ${member.name}',
              style: const TextStyle(color: Colors.white, fontSize: 18)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (plans.isNotEmpty) ...[
                  DropdownButtonFormField<Map<String, dynamic>?>(
                    initialValue: selectedPlan,
                    dropdownColor: QuantumColors.voidGray,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Plan',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.card_membership,
                          color: QuantumColors.holoPurple, size: 20),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                    ),
                    items: [
                      for (final p in plans)
                        DropdownMenuItem(
                          value: p,
                          child: Text(
                              '${p['name']} — \$${(p['price'] as double).toStringAsFixed(0)} (${p['durationDays']} días)'),
                        ),
                      const DropdownMenuItem(
                          value: null, child: Text('Personalizado…')),
                    ],
                    onChanged: (p) => setDialogState(() {
                      selectedPlan = p;
                      if (p != null) {
                        amountCtrl.text =
                            (p['price'] as double).toStringAsFixed(0);
                      }
                    }),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: amountCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Monto cobrado (\$)',
                    labelStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.attach_money,
                        color: QuantumColors.matrixCyan, size: 20),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                  ),
                ),
                if (selectedPlan == null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: monthsCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Meses a renovar',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.calendar_month,
                          color: QuantumColors.holoPurple, size: 20),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Método de pago',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final m in const [
                      'Efectivo',
                      'Transferencia',
                      'Tarjeta'
                    ])
                      ChoiceChip(
                        label: Text(m),
                        selected: method == m,
                        selectedColor: QuantumColors.matrixCyan,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        labelStyle: TextStyle(
                            color:
                                method == m ? Colors.black : Colors.white54,
                            fontSize: 12),
                        onSelected: (_) =>
                            setDialogState(() => method = m),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: QuantumColors.matrixCyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Vence: ${member.expiry}  →  Nuevo vencimiento: ${previewExpiry()}',
                    style: const TextStyle(
                        color: QuantumColors.matrixCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final amount =
                          double.tryParse(amountCtrl.text.trim()) ?? -1;
                      if (amount < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Ingresa un monto válido')));
                        return;
                      }
                      setDialogState(() => saving = true);
                      try {
                        final newExpiry =
                            await repo.registerMembershipPayment(
                          gymId: gymId,
                          memberId: member.id!,
                          memberName: member.name,
                          planName: selectedPlan != null
                              ? selectedPlan!['name'] as String
                              : member.plan,
                          amount: amount,
                          durationDays: durationDays(),
                          method: method,
                          registeredBy: registeredBy,
                          currentExpiry: member.expiry,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _logAudit(
                            'Cobró \$${amount.toStringAsFixed(0)} ($method) a ${member.name} — vence $newExpiry',
                            'MEMBRESÍA');
                        _loadMembersFromFirestore();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✓ Pago registrado. ${member.name} renovado hasta $newExpiry'),
                              backgroundColor: QuantumColors.matrixCyan,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content:
                                  Text('No se pudo registrar el pago: $e')));
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: QuantumColors.matrixCyan),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Registrar cobro'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFreeze(_MemberData member) {
    final isFreezing = !member.isFrozen;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.voidGray,
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
                  backgroundColor: QuantumColors.warning.withValues(alpha: 0.9),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isFreezing ? Colors.blueAccent : QuantumColors.matrixCyan,
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
        backgroundColor: QuantumColors.voidGray,
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
                  backgroundColor: QuantumColors.error,
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
            style: ElevatedButton.styleFrom(backgroundColor: QuantumColors.error),
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

      await getIt<FirebaseOwnerMemberRepository>().deleteMember(gymId, member.id!);
    } catch (e) { debugPrint('Error deleting member: $e'); }
  }

  Future<void> _logAudit(String action, String module) async {
    try {
      final auth = AuthStateNotifier.instance;
      final gymId = auth.profile?.gymId?.value;
      await getIt<FirebaseOwnerMemberRepository>().logAudit(
        who: auth.profile?.displayName ?? 'Owner',
        action: action,
        module: module,
        gymId: gymId,
      );
    } catch (e) { debugPrint('Error logging audit: $e'); }
  }

  void _showAddMember() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedPlan = 'Mensual';

    showModalBottomSheet(
      context: context, 
      backgroundColor: QuantumColors.voidGray, 
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
                            initialValue: selectedPlan,
                dropdownColor: QuantumColors.voidGray,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Plan',
                  labelStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.card_membership, color: QuantumColors.holoPurple, size: 20),
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
                    backgroundColor: QuantumColors.matrixCyan,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: QuantumColors.holoPurple,
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

      await getIt<FirebaseOwnerMemberRepository>().saveMember(gymId, {
        'name': member.name,
        'plan': member.plan,
        'expiry': member.expiry,
        'status': member.status,
        'email': member.email,
        'phone': member.phone,
        'isFrozen': member.isFrozen,
      });
    } catch (e) { debugPrint('Error saving member: $e'); }
  }

  Widget _inputField(String label, IconData ic, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(ic, color: QuantumColors.holoPurple, size: 20), filled: true,
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

    // Fetch available routines from repository
    final routines = await getIt<FirebaseOwnerMemberRepository>().loadActiveRoutines(gymId);

    if (!mounted) return;

    if (routines.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: QuantumColors.voidGray,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Sin rutinas disponibles', style: TextStyle(color: Colors.white)),
          content: const Text(
            'No hay rutinas activas en tu gimnasio. Crea rutinas en el Training Forge primero.',
            style: TextStyle(color: Colors.white54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido', style: TextStyle(color: QuantumColors.holoPurple)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: QuantumColors.voidGray,
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
                        border: Border.all(color: QuantumColors.holoPurple.withValues(alpha: 0.2)),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: QuantumColors.holoPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fitness_center, color: QuantumColors.holoPurple, size: 20),
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
        backgroundColor: QuantumColors.voidGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar Asignación', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rutina: ${routine['name']}', style: const TextStyle(color: QuantumColors.holoPurple, fontWeight: FontWeight.bold)),
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
            style: ElevatedButton.styleFrom(backgroundColor: QuantumColors.holoPurple),
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

      await getIt<FirebaseOwnerMemberRepository>().createAssignment(
        gymId: gymId,
        routineId: routine['id'],
        clientId: member.id!,
        assignedById: assignerId,
        startDate: parsedStartDate,
        endDate: parsedEndDate,
        notes: notes.isNotEmpty ? notes : null,
      );

      _logAudit('Asignó rutina "${routine['name']}" a ${member.name}', 'RUTINAS');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Rutina "${routine['name']}" asignada a ${member.name}'),
            backgroundColor: QuantumColors.matrixCyan,
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
