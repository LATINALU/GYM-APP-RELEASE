import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../../domain/entities/membership_plan.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../theme/quantum_colors.dart';

/// Gestión de Planes de Membresía - Owner
/// Crear, editar, activar/desactivar planes para el gym
class MembershipPlansScreen extends StatefulWidget {
  const MembershipPlansScreen({super.key});

  @override
  State<MembershipPlansScreen> createState() => _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends State<MembershipPlansScreen> {
  bool _showCreateForm = false;
  final List<MembershipPlan> _plans = [];
  bool _isLoadingPlans = true;
  String? _loadError;
  MembershipPlan? _editingPlan;
  String _membersWithPlanLabel = '—';

  // Form controllers
  final _planNameCtrl = TextEditingController();
  final _planDescCtrl = TextEditingController();
  final _planPriceCtrl = TextEditingController();
  PlanDuration _planDuration = PlanDuration.monthly;
  final int _planMaxClasses = 0;
  bool _planLocker = false;
  bool _planShower = true;
  bool _planParking = false;
  bool _planTrainer = false;
  final List<String> _planFeatures = [];
  final _featureCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _planNameCtrl.dispose();
    _planDescCtrl.dispose();
    _planPriceCtrl.dispose();
    _featureCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _loadError = null;
    });

    try {
      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      if (gymId == null) {
        throw Exception('No se pudo resolver el gimnasio actual');
      }

      final plansSnapshot =
          await FirebaseFirestore.instance
              .collection('membership_plans')
              .where('gymId', isEqualTo: gymId)
              .get();

      final membersSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('gymId', isEqualTo: gymId)
              .where('role.type', isEqualTo: 'client')
              .get();

      final plans =
          plansSnapshot.docs.map(_planFromFirestore).toList()
            ..sort((a, b) => a.price.compareTo(b.price));

      if (!mounted) return;

      setState(() {
        _plans
          ..clear()
          ..addAll(plans);
        _membersWithPlanLabel = '${membersSnapshot.docs.length}';
        _isLoadingPlans = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'No se pudieron cargar los planes.';
        _isLoadingPlans = false;
      });
    }
  }

  MembershipPlan _planFromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return MembershipPlan.restore(
      id: PlanId(doc.id),
      gymId: GymId(data['gymId'] as String? ?? ''),
      name: data['name'] as String? ?? 'Sin nombre',
      description: data['description'] as String?,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      duration: _planDurationFromString(data['duration'] as String?),
      maxClasses: data['maxClasses'] as int? ?? 0,
      includesLocker: data['includesLocker'] as bool? ?? false,
      includesShower: data['includesShower'] as bool? ?? true,
      includesParking: data['includesParking'] as bool? ?? false,
      includesPersonalTrainer: data['includesPersonalTrainer'] as bool? ?? false,
      features: (data['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _dateTimeFromFirestore(data['createdAt']),
      updatedAt: _nullableDateTimeFromFirestore(data['updatedAt']),
    );
  }

  Map<String, dynamic> _planToFirestore(MembershipPlan plan) {
    return {
      'planId': plan.id.value,
      'gymId': plan.gymId.value,
      'name': plan.name,
      'description': plan.description,
      'price': plan.price,
      'currency': 'MXN',
      'duration': plan.duration.name,
      'durationDays': plan.duration.days,
      'maxClasses': plan.maxClasses,
      'includesLocker': plan.includesLocker,
      'includesShower': plan.includesShower,
      'includesParking': plan.includesParking,
      'includesPersonalTrainer': plan.includesPersonalTrainer,
      'features': plan.features,
      'isActive': plan.isActive,
      'createdAt': Timestamp.fromDate(plan.createdAt),
      'updatedAt': plan.updatedAt != null ? Timestamp.fromDate(plan.updatedAt!) : null,
    };
  }

  PlanDuration _planDurationFromString(String? value) {
    return PlanDuration.values.firstWhere(
      (duration) => duration.name == value,
      orElse: () => PlanDuration.monthly,
    );
  }

  DateTime _dateTimeFromFirestore(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  DateTime? _nullableDateTimeFromFirestore(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
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
      child: _showCreateForm ? _buildCreateForm() : _buildPlansView(),
    );
  }

  Widget _buildPlansView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStatsRow(),
          const SizedBox(height: 32),
          _buildPlansGrid(),
        ],
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
            Text('PLANES DE MEMBRESÍA', style: QuantumTypography.h1.copyWith(fontSize: 32, letterSpacing: -1, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Gestiona los planes y precios de tu gimnasio', style: TextStyle(color: Colors.white38)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => setState(() {
            _showCreateForm = true;
            _editingPlan = null;
            _resetForm();
          }),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Crear Plan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: QuantumColors.matrixCyan,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final activePlans = _plans.where((p) => p.isActive).length;
    final avgPrice = _plans.isEmpty ? 0.0 : _plans.map((p) => p.price).reduce((a, b) => a + b) / _plans.length;
    return Row(
      children: [
        _buildStatCard('Planes Activos', '$activePlans', Icons.card_membership_rounded, QuantumColors.matrixCyan),
        const SizedBox(width: 16),
        _buildStatCard('Total Planes', '${_plans.length}', Icons.layers_rounded, const Color(0xFF6366F1)),
        const SizedBox(width: 16),
        _buildStatCard('Precio Promedio', '\$${avgPrice.toStringAsFixed(0)}', Icons.attach_money_rounded, const Color(0xFF10B981)),
        const SizedBox(width: 16),
        _buildStatCard('Miembros con Plan', _membersWithPlanLabel, Icons.people_alt_rounded, const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: QuantumColors.surface(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 20)),
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansGrid() {
    if (_isLoadingPlans) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPlans,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_plans.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.card_membership_rounded, color: Colors.white12, size: 64),
              SizedBox(height: 16),
              Text('Todavía no hay planes registrados', style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.1,
      ),
      itemCount: _plans.length,
      itemBuilder: (context, index) => _buildPlanCard(_plans[index], index),
    );
  }

  Widget _buildPlanCard(MembershipPlan plan, int index) {
    final colors = [QuantumColors.matrixCyan, const Color(0xFF6366F1), const Color(0xFFFF6B35), const Color(0xFF10B981)];
    final color = colors[index % colors.length];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: plan.isActive ? 0.2 : 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(plan.duration.displayName, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: plan.isActive ? const Color(0xFF10B981) : Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(plan.isActive ? 'Activo' : 'Inactivo', style: TextStyle(color: plan.isActive ? const Color(0xFF10B981) : Colors.redAccent, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(plan.name, style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 4),
          if (plan.description != null)
            Text(plan.description!, style: const TextStyle(color: Colors.white38, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${plan.price.toStringAsFixed(0)}', style: QuantumTypography.h1.copyWith(color: color, fontSize: 36)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/${plan.duration.displayName.toLowerCase()}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ],
          ),
          const Spacer(),
          // Includes
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (plan.includesShower) _buildIncludeChip('Regaderas', Icons.shower_rounded),
              if (plan.includesLocker) _buildIncludeChip('Locker', Icons.lock_rounded),
              if (plan.includesParking) _buildIncludeChip('Parking', Icons.local_parking_rounded),
              if (plan.includesPersonalTrainer) _buildIncludeChip('Trainer', Icons.sports_rounded),
              ...plan.features.map((f) => _buildIncludeChip(f, Icons.check_circle_outline_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _editPlan(plan),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: const BorderSide(color: Colors.white10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Editar', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _togglePlanStatus(plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: plan.isActive ? Colors.redAccent.withValues(alpha: 0.15) : const Color(0xFF10B981).withValues(alpha: 0.15),
                    foregroundColor: plan.isActive ? Colors.redAccent : const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(plan.isActive ? 'Desactivar' : 'Activar', style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncludeChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white30, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CREATE PLAN FORM
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _showCreateForm = false),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white60),
              ),
              const SizedBox(width: 12),
              Text(_editingPlan == null ? 'CREAR NUEVO PLAN' : 'EDITAR PLAN', style: QuantumTypography.h1.copyWith(fontSize: 28, letterSpacing: -1, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Basic info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormSection('Información del Plan', [
                      _buildTextField('Nombre del Plan', _planNameCtrl, 'Ej: Plan Premium'),
                      const SizedBox(height: 16),
                      _buildTextField('Descripción', _planDescCtrl, 'Descripción del plan', maxLines: 3),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Precio (\$)', _planPriceCtrl, '0.00', keyboardType: TextInputType.number)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDurationDropdown()),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildFormSection('Características Extra', [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildToggleFeature('Regaderas', Icons.shower_rounded, _planShower, (v) => setState(() => _planShower = v)),
                          _buildToggleFeature('Locker', Icons.lock_rounded, _planLocker, (v) => setState(() => _planLocker = v)),
                          _buildToggleFeature('Estacionamiento', Icons.local_parking_rounded, _planParking, (v) => setState(() => _planParking = v)),
                          _buildToggleFeature('Entrenador Personal', Icons.sports_rounded, _planTrainer, (v) => setState(() => _planTrainer = v)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Características Adicionales', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _featureCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Ej: Clases Grupales',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.16)),
                                filled: true,
                                fillColor: QuantumColors.surface(),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: QuantumColors.matrixCyan)),
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              if (_featureCtrl.text.trim().isNotEmpty) {
                                setState(() {
                                  _planFeatures.add(_featureCtrl.text.trim());
                                  _featureCtrl.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                      if (_planFeatures.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _planFeatures.map((f) => Chip(
                            label: Text(f, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: QuantumColors.surface(),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
                            onDeleted: () => setState(() => _planFeatures.remove(f)),
                            side: const BorderSide(color: Colors.white10),
                          )).toList(),
                        ),
                      ],
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right: Preview
              Expanded(child: _buildPlanPreview()),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _showCreateForm = false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white60,
                  side: const BorderSide(color: Colors.white10),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _createPlan,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(_editingPlan == null ? 'Crear Plan' : 'Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuantumColors.matrixCyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.16)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: QuantumColors.matrixCyan)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Duración', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButton<PlanDuration>(
            value: _planDuration,
            isExpanded: true,
            dropdownColor: QuantumColors.surface(),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: PlanDuration.values.map((d) => DropdownMenuItem(value: d, child: Text(d.displayName))).toList(),
            onChanged: (v) { if (v != null) setState(() => _planDuration = v); },
          ),
        ),
      ],
    );
  }

  Widget _buildToggleFeature(String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value ? QuantumColors.matrixCyan.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value ? QuantumColors.matrixCyan.withValues(alpha: 0.3) : Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: value ? QuantumColors.matrixCyan : Colors.white24, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: value ? Colors.white : Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanPreview() {
    final price = double.tryParse(_planPriceCtrl.text) ?? 0;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: QuantumColors.matrixCyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vista Previa', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: QuantumColors.matrixCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_planDuration.displayName, style: const TextStyle(color: QuantumColors.matrixCyan, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Text(
            _planNameCtrl.text.isEmpty ? 'Nombre del Plan' : _planNameCtrl.text,
            style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            _planDescCtrl.text.isEmpty ? 'Descripción...' : _planDescCtrl.text,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Text('\$${price.toStringAsFixed(0)}', style: QuantumTypography.h1.copyWith(color: QuantumColors.matrixCyan, fontSize: 32)),
          const SizedBox(height: 16),
          if (_planShower || _planLocker || _planParking || _planTrainer || _planFeatures.isNotEmpty) ...[
            const Text('Incluye:', style: TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 8),
            if (_planShower) _previewFeature('Regaderas'),
            if (_planLocker) _previewFeature('Locker'),
            if (_planParking) _previewFeature('Estacionamiento'),
            if (_planTrainer) _previewFeature('Entrenador Personal'),
            ..._planFeatures.map((f) => _previewFeature(f)),
          ],
        ],
      ),
    );
  }

  Widget _previewFeature(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: QuantumColors.matrixCyan, size: 14),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  void _resetForm() {
    _planNameCtrl.clear();
    _planDescCtrl.clear();
    _planPriceCtrl.clear();
    _planDuration = PlanDuration.monthly;
    _planLocker = false;
    _planShower = true;
    _planParking = false;
    _planTrainer = false;
    _planFeatures.clear();
    _featureCtrl.clear();
  }

  Future<void> _createPlan() async {
    if (_planNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del plan es requerido'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    final price = double.tryParse(_planPriceCtrl.text) ?? 0;
    final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
    if (gymId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo resolver el gimnasio actual'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final plan =
        _editingPlan?.updateInfo(
          name: _planNameCtrl.text.trim(),
          description: _planDescCtrl.text.trim().isEmpty ? null : _planDescCtrl.text.trim(),
          price: price,
          duration: _planDuration,
          maxClasses: _planMaxClasses,
          includesLocker: _planLocker,
          includesShower: _planShower,
          includesParking: _planParking,
          includesPersonalTrainer: _planTrainer,
          features: List.from(_planFeatures),
        ) ??
        MembershipPlan.create(
          gymId: GymId(gymId),
          name: _planNameCtrl.text.trim(),
          description: _planDescCtrl.text.trim().isEmpty ? null : _planDescCtrl.text.trim(),
          price: price,
          duration: _planDuration,
          maxClasses: _planMaxClasses,
          includesLocker: _planLocker,
          includesShower: _planShower,
          includesParking: _planParking,
          includesPersonalTrainer: _planTrainer,
          features: List.from(_planFeatures),
        );

    try {
      await FirebaseFirestore.instance
          .collection('membership_plans')
          .doc(plan.id.value)
          .set(_planToFirestore(plan), SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _showCreateForm = false;
        _editingPlan = null;
      });
      await _loadPlans();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan "${plan.name}" guardado exitosamente'), backgroundColor: const Color(0xFF10B981)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el plan: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _editPlan(MembershipPlan plan) {
    setState(() {
      _editingPlan = plan;
      _planNameCtrl.text = plan.name;
      _planDescCtrl.text = plan.description ?? '';
      _planPriceCtrl.text = plan.price.toStringAsFixed(0);
      _planDuration = plan.duration;
      _planLocker = plan.includesLocker;
      _planShower = plan.includesShower;
      _planParking = plan.includesParking;
      _planTrainer = plan.includesPersonalTrainer;
      _planFeatures.clear();
      _planFeatures.addAll(plan.features);
      _showCreateForm = true;
    });
  }

  Future<void> _togglePlanStatus(MembershipPlan plan) async {
    final updatedPlan = plan.isActive ? plan.deactivate() : plan.activate();

    try {
      await FirebaseFirestore.instance
          .collection('membership_plans')
          .doc(updatedPlan.id.value)
          .set(_planToFirestore(updatedPlan), SetOptions(merge: true));

      await _loadPlans();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan "${updatedPlan.name}" ${updatedPlan.isActive ? 'activado' : 'desactivado'}'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el plan: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }
}
