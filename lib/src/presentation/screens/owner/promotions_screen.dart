import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/theme.dart';

/// Tipos de promoción soportados
enum PromoType {
  percentDiscount('Descuento %', Icons.percent_rounded),
  fixedDiscount('Monto fijo', Icons.attach_money_rounded),
  twoForOne('2x1', Icons.group_add_rounded),
  freePass('Pase gratis', Icons.confirmation_number_rounded),
  referral('Referidos', Icons.handshake_rounded);

  final String label;
  final IconData icon;
  const PromoType(this.label, this.icon);

  static PromoType fromName(String? name) => PromoType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => PromoType.percentDiscount,
      );
}

/// Gestión de promociones del gimnasio (colección `promotions`).
/// El owner crea campañas con vigencia y las activa/pausa; el estado
/// (activa/programada/expirada) se deriva de las fechas.
class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _loading = true;
  String? _error;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _promos = const [];

  String? get _gymId => AuthStateNotifier.instance.profile?.gymId?.value;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final gymId = _gymId;
    if (gymId == null || gymId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No se pudo resolver el gimnasio de tu sesión';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await _firestore
          .collection('promotions')
          .where('gymId', isEqualTo: gymId)
          .get();
      final docs = snap.docs.toList()
        ..sort((a, b) {
          final ta = (a.data()['createdAt'] as Timestamp?)?.toDate() ??
              DateTime(1970);
          final tb = (b.data()['createdAt'] as Timestamp?)?.toDate() ??
              DateTime(1970);
          return tb.compareTo(ta);
        });
      if (!mounted) return;
      setState(() {
        _promos = docs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar las promociones: $e';
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Estado derivado de una promo
  // ═══════════════════════════════════════════════════════════════════

  (String, Color) _statusOf(Map<String, dynamic> d) {
    if (d['isActive'] != true) return ('Pausada', Colors.orange);
    final now = DateTime.now();
    final start = (d['startDate'] as Timestamp?)?.toDate();
    final end = (d['endDate'] as Timestamp?)?.toDate();
    if (start != null && now.isBefore(start)) {
      return ('Programada', Colors.blueAccent);
    }
    if (end != null && now.isAfter(end)) return ('Expirada', Colors.redAccent);
    return ('Activa', const Color(0xFF4ECDC4));
  }

  String _valueLabel(Map<String, dynamic> d) {
    final type = PromoType.fromName(d['type'] as String?);
    final value = (d['value'] as num?)?.toDouble() ?? 0;
    switch (type) {
      case PromoType.percentDiscount:
        return '${value.toStringAsFixed(0)}% de descuento';
      case PromoType.fixedDiscount:
        return '\$${value.toStringAsFixed(0)} de descuento';
      case PromoType.twoForOne:
        return '2x1 en membresías';
      case PromoType.freePass:
        return value > 0
            ? '${value.toStringAsFixed(0)} días de pase gratis'
            : 'Pase gratis';
      case PromoType.referral:
        return value > 0
            ? '\$${value.toStringAsFixed(0)} por referido'
            : 'Beneficio por referido';
    }
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '—' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ═══════════════════════════════════════════════════════════════════
  // Acciones
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _toggleActive(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final isActive = doc.data()['isActive'] == true;
    await doc.reference.update({'isActive': !isActive});
    _load();
  }

  Future<void> _delete(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final name = doc.data()['name'] ?? 'esta promoción';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GymColors.surface,
        title: const Text('Eliminar promoción',
            style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar "$name"? Esta acción no se puede deshacer.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      await doc.reference.delete();
      _load();
    }
  }

  Future<void> _openEditor(
      {QueryDocumentSnapshot<Map<String, dynamic>>? existing}) async {
    final gymId = _gymId;
    if (gymId == null) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PromotionEditorDialog(gymId: gymId, existing: existing),
    );
    if (saved == true) _load();
  }

  // ═══════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GymColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Promociones',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                        'Campañas de descuentos, 2x1 y referidos para atraer y retener socios.',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: GymColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva Promoción'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_promos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_offer_outlined,
                color: Colors.white12, size: 64),
            const SizedBox(height: 24),
            const Text('Sin promociones todavía',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Crea tu primera campaña: descuento de temporada,\n2x1 para nuevos socios o beneficios por referidos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear promoción'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
      itemCount: _promos.length,
      itemBuilder: (_, i) => _buildPromoCard(_promos[i]),
    );
  }

  Widget _buildPromoCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final type = PromoType.fromName(d['type'] as String?);
    final (statusLabel, statusColor) = _statusOf(d);
    final code = (d['code'] as String?)?.trim() ?? '';
    final start = (d['startDate'] as Timestamp?)?.toDate();
    final end = (d['endDate'] as Timestamp?)?.toDate();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GymCard(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: GymColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(type.icon, color: GymColors.primary, size: 26),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(d['name'] ?? 'Promoción',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(statusLabel,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                      if (code.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Código: $code',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_valueLabel(d),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    'Vigencia: ${_fmtDate(start)} → ${_fmtDate(end)}'
                    '${(d['description'] as String?)?.isNotEmpty == true ? '  ·  ${d['description']}' : ''}',
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Switch(
              value: d['isActive'] == true,
              activeThumbColor: GymColors.primary,
              onChanged: (_) => _toggleActive(doc),
            ),
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined, color: Colors.white54),
              onPressed: () => _openEditor(existing: doc),
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _delete(doc),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Editor (crear / editar)
// ═══════════════════════════════════════════════════════════════════════

class _PromotionEditorDialog extends StatefulWidget {
  final String gymId;
  final QueryDocumentSnapshot<Map<String, dynamic>>? existing;

  const _PromotionEditorDialog({required this.gymId, this.existing});

  @override
  State<_PromotionEditorDialog> createState() => _PromotionEditorDialogState();
}

class _PromotionEditorDialogState extends State<_PromotionEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameC;
  late final TextEditingController _descC;
  late final TextEditingController _valueC;
  late final TextEditingController _codeC;
  late PromoType _type;
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;

  Map<String, dynamic> get _d => widget.existing?.data() ?? const {};

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: _d['name'] as String? ?? '');
    _descC = TextEditingController(text: _d['description'] as String? ?? '');
    _valueC = TextEditingController(
        text: ((_d['value'] as num?)?.toDouble() ?? 0) > 0
            ? (_d['value'] as num).toDouble().toStringAsFixed(0)
            : '');
    _codeC = TextEditingController(text: _d['code'] as String? ?? '');
    _type = PromoType.fromName(_d['type'] as String?);
    _start = (_d['startDate'] as Timestamp?)?.toDate();
    _end = (_d['endDate'] as Timestamp?)?.toDate();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    _valueC.dispose();
    _codeC.dispose();
    super.dispose();
  }

  bool get _needsValue =>
      _type == PromoType.percentDiscount ||
      _type == PromoType.fixedDiscount ||
      _type == PromoType.freePass ||
      _type == PromoType.referral;

  String get _valueHint {
    switch (_type) {
      case PromoType.percentDiscount:
        return 'Porcentaje (ej. 20)';
      case PromoType.fixedDiscount:
        return 'Monto (ej. 500)';
      case PromoType.freePass:
        return 'Días gratis (ej. 7)';
      case PromoType.referral:
        return 'Beneficio por referido (ej. 300)';
      case PromoType.twoForOne:
        return '';
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_start ?? now) : (_end ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start != null && _end != null && _end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('La fecha de fin no puede ser anterior al inicio')));
      return;
    }

    setState(() => _saving = true);
    final data = {
      'gymId': widget.gymId,
      'name': _nameC.text.trim(),
      'description': _descC.text.trim(),
      'type': _type.name,
      'value': double.tryParse(_valueC.text.trim()) ?? 0,
      'code': _codeC.text.trim().toUpperCase(),
      'startDate': _start != null ? Timestamp.fromDate(_start!) : null,
      'endDate': _end != null ? Timestamp.fromDate(_end!) : null,
      'isActive': _d['isActive'] ?? true,
    };

    try {
      if (widget.existing != null) {
        await widget.existing!.reference.update(data);
      } else {
        await FirebaseFirestore.instance.collection('promotions').add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: GymColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Editar Promoción' : 'Nueva Promoción',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _field(_nameC, 'Nombre de la campaña *',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El nombre es obligatorio'
                        : null),
                const SizedBox(height: 16),
                _field(_descC, 'Descripción (opcional)', maxLines: 2),
                const SizedBox(height: 16),
                DropdownButtonFormField<PromoType>(
                  initialValue: _type,
                  dropdownColor: GymColors.surface,
                  decoration: _decoration('Tipo de promoción'),
                  style: const TextStyle(color: Colors.white),
                  items: PromoType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                Icon(t.icon,
                                    size: 18, color: GymColors.primary),
                                const SizedBox(width: 10),
                                Text(t.label),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (t) => setState(() => _type = t!),
                ),
                if (_needsValue) ...[
                  const SizedBox(height: 16),
                  _field(_valueC, _valueHint,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final parsed = double.tryParse(v?.trim() ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Ingresa un valor mayor a 0';
                        }
                        if (_type == PromoType.percentDiscount &&
                            parsed > 100) {
                          return 'El descuento no puede superar 100%';
                        }
                        return null;
                      }),
                ],
                const SizedBox(height: 16),
                _field(_codeC, 'Código promocional (opcional, ej. VERANO25)'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _dateButton('Inicio', _start,
                            () => _pickDate(isStart: true))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _dateButton(
                            'Fin', _end, () => _pickDate(isStart: false))),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: GymColors.primary),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : Text(isEdit ? 'Guardar cambios' : 'Crear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(label),
    );
  }

  Widget _dateButton(String label, DateTime? value, VoidCallback onTap) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_rounded,
          size: 16, color: Colors.white54),
      label: Text(
        value == null
            ? label
            : '$label: ${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}',
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }
}
