/// Membership Plans Screen - Selección de membresía con comparación
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../theme/theme.dart';
import '../../../domain/entities/membership.dart';
import '../../../../core/auth/auth_state_notifier.dart';

class MembershipPlansScreen extends StatefulWidget {
  final bool isUpgrade;
  final MembershipTier? currentTier;

  const MembershipPlansScreen({
    super.key,
    this.isUpgrade = false,
    this.currentTier,
  });

  @override
  State<MembershipPlansScreen> createState() => _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends State<MembershipPlansScreen> {
  late List<MembershipPlan> _plans;
  BillingCycle _selectedCycle = BillingCycle.monthly;
  MembershipPlan? _selectedPlan;
  bool _showComparison = false;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _plans = const [];
    _loadPlansFromFirestore();
  }

  Future<void> _loadPlansFromFirestore() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final auth = AuthStateNotifier.instance;
      final gymId = auth.profile?.gymId?.value;
      final currentUid = fb.FirebaseAuth.instance.currentUser?.uid;

      if (gymId == null || currentUid == null) {
        setState(() {
          _isLoading = false;
          _loadError = 'No se pudo determinar el gimnasio. Inicia sesión nuevamente.';
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('membership_plans')
          .where('gymId', isEqualTo: gymId)
          .where('isActive', isEqualTo: true)
          .get();

      final plans = snapshot.docs.map((doc) {
        final data = doc.data();
        return MembershipPlan(
          id: doc.id,
          name: data['name'] ?? 'Plan',
          description: data['description'] ?? '',
          tier: MembershipTier.values.firstWhere(
            (t) => t.name == (data['tier'] ?? 'basic'),
            orElse: () => MembershipTier.basic,
          ),
          monthlyPrice: (data['monthlyPrice'] ?? 0).toDouble(),
          features: List<String>.from(data['features'] ?? []),
          restrictions: List<String>.from(data['restrictions'] ?? []),
          maxClassBookingsPerMonth: data['maxClassBookingsPerMonth'] ?? 0,
          maxGuestPassesPerMonth: data['maxGuestPassesPerMonth'] ?? 0,
          includesLocker: data['includesLocker'] ?? false,
          includesTowelService: data['includesTowelService'] ?? false,
          includesPersonalTrainer: data['includesPersonalTrainer'] ?? false,
          personalTrainerSessionsPerMonth: data['personalTrainerSessionsPerMonth'] ?? 0,
          accessSchedule: data['accessSchedule']?.toString(),
          isActive: data['isActive'] ?? true,
          isPopular: data['isPopular'] ?? false,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Error al cargar planes: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: QuantumColors.cosmicBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.isUpgrade ? 'Mejorar Plan' : 'Elige tu Membresía',
            style: QuantumTypography.h3.copyWith(color: Colors.white),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: QuantumColors.quantumBlue),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: QuantumColors.cosmicBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.isUpgrade ? 'Mejorar Plan' : 'Elige tu Membresía',
            style: QuantumTypography.h3.copyWith(color: Colors.white),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: QuantumColors.error),
                const SizedBox(height: 16),
                Text(
                  _loadError!,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadPlansFromFirestore,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QuantumColors.quantumBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_plans.isEmpty) {
      return Scaffold(
        backgroundColor: QuantumColors.cosmicBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.isUpgrade ? 'Mejorar Plan' : 'Elige tu Membresía',
            style: QuantumTypography.h3.copyWith(color: Colors.white),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: QuantumColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_membership, size: 48, color: Colors.white38),
                  SizedBox(height: 16),
                  Text(
                    'No hay planes disponibles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Los planes de membresía reales aún no están sincronizados en esta vista.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isUpgrade ? 'Mejorar Plan' : 'Elige tu Membresía',
          style: QuantumTypography.h3.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showComparison = !_showComparison),
            icon: Icon(
              _showComparison ? Icons.view_agenda : Icons.compare,
              color: QuantumColors.quantumBlue,
            ),
            label: Text(
              _showComparison ? 'Tarjetas' : 'Comparar',
              style: const TextStyle(color: QuantumColors.quantumBlue),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCycleSelector(),
          if (_selectedCycle != BillingCycle.monthly) _buildSavingsBanner(),
          Expanded(
            child: _showComparison
                ? _buildComparisonTable()
                : _buildPlanCards(),
          ),
        ],
      ),
      bottomNavigationBar: _selectedPlan != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildCycleSelector() {
    final cycles = [
      BillingCycle.monthly,
      BillingCycle.quarterly,
      BillingCycle.semiannual,
      BillingCycle.annual,
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: cycles.map((cycle) {
          final isSelected = _selectedCycle == cycle;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCycle = cycle),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? QuantumColors.quantumBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cycle.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    if (cycle.discountPercent > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: isSelected ? 0.3 : 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${cycle.discountPercent}%',
                          style: TextStyle(
                            color: Colors.green[300],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSavingsBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.savings, color: Colors.green[400], size: 20),
          const SizedBox(width: 10),
          Text(
            '¡Ahorra ${_selectedCycle.discountPercent}% pagando ${_selectedCycle.displayName.toLowerCase()}!',
            style: TextStyle(color: Colors.green[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCards() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];
        final isSelected = _selectedPlan?.id == plan.id;
        final isCurrent = widget.currentTier == plan.tier;
        
        return _PlanCard(
          plan: plan,
          billingCycle: _selectedCycle,
          isSelected: isSelected,
          isCurrent: isCurrent,
          onSelect: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedPlan = isSelected ? null : plan);
          },
        );
      },
    );
  }

  Widget _buildComparisonTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Row
          Container(
            decoration: const BoxDecoration(
              color: QuantumColors.cardBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Característica',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                ..._plans.map((plan) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(int.parse(plan.tier.colorHex.replaceFirst('#', '0xFF')))
                          .withValues(alpha: 0.2),
                    ),
                    child: Column(
                      children: [
                        Text(plan.tier.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          plan.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${plan.formattedMonthlyPrice}/mes',
                          style: const TextStyle(color: Colors.white70, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
          // Feature Rows
          _buildComparisonRow('Acceso zona pesas', 
              _plans.map((p) => p.zoneAccess.contains(GymZoneAccess.weightsArea)).toList()),
          _buildComparisonRow('Zona cardio', 
              _plans.map((p) => p.zoneAccess.contains(GymZoneAccess.cardioZone)).toList()),
          _buildComparisonRow('Clases grupales', 
              _plans.map((p) => p.maxClassBookingsPerMonth > 0 
                  ? (p.maxClassBookingsPerMonth > 100 ? '∞' : '${p.maxClassBookingsPerMonth}/mes')
                  : false).toList()),
          _buildComparisonRow('Box CrossFit', 
              _plans.map((p) => p.zoneAccess.contains(GymZoneAccess.crossfitBox)).toList()),
          _buildComparisonRow('Locker incluido', 
              _plans.map((p) => p.includesLocker).toList()),
          _buildComparisonRow('Towel service', 
              _plans.map((p) => p.includesTowelService).toList()),
          _buildComparisonRow('Entrenador personal', 
              _plans.map((p) => p.includesPersonalTrainer 
                  ? '${p.personalTrainerSessionsPerMonth}/mes' : false).toList()),
          _buildComparisonRow('Spa & Sauna', 
              _plans.map((p) => p.zoneAccess.contains(GymZoneAccess.spa)).toList()),
          _buildComparisonRow('Pases invitado', 
              _plans.map((p) => p.maxGuestPassesPerMonth > 0 
                  ? '${p.maxGuestPassesPerMonth}/mes' : false).toList()),
          _buildComparisonRow('Acceso 24/7', 
              _plans.map((p) => p.accessSchedule == '24/7').toList()),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String feature, List<dynamic> values) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                feature,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
          ...values.map((value) => Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              alignment: Alignment.center,
              child: value is bool
                  ? Icon(
                      value ? Icons.check_circle : Icons.cancel,
                      color: value ? Colors.green : Colors.red.withValues(alpha: 0.3),
                      size: 20,
                    )
                  : Text(
                      value.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final price = _selectedPlan!.getPriceForCycle(_selectedCycle);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedPlan!.tier.icon} ${_selectedPlan!.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _selectedCycle.displayName,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedCycle != BillingCycle.monthly)
                      Text(
                        'Ahorras \$${(_selectedPlan!.monthlyPrice * (_selectedCycle.durationDays / 30) - price).toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.green, fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _proceedToCheckout(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuantumColors.quantumBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  widget.isUpgrade ? 'MEJORAR AHORA' : 'CONTINUAR',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToCheckout() {
    // Navigate to checkout/payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MembershipCheckoutScreen(
          plan: _selectedPlan!,
          billingCycle: _selectedCycle,
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final MembershipPlan plan;
  final BillingCycle billingCycle;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.billingCycle,
    required this.isSelected,
    required this.isCurrent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = Color(int.parse(plan.tier.colorHex.replaceFirst('#', '0xFF')));
    final price = plan.getPriceForCycle(billingCycle);

    return GestureDetector(
      onTap: isCurrent ? null : onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [tierColor.withValues(alpha: 0.3), tierColor.withValues(alpha: 0.1)]
                : [QuantumColors.cardBackground, QuantumColors.cardBackground],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? tierColor
                : isCurrent
                    ? Colors.green
                    : Colors.white.withValues(alpha: 0.05),
            width: isSelected || isCurrent ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tierColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(plan.tier.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (plan.isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'POPULAR',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'ACTUAL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        plan.description,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: tierColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      billingCycle == BillingCycle.monthly 
                          ? '/mes' 
                          : '/${billingCycle.displayName.toLowerCase()}',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Features
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plan.features.take(5).map((feature) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      feature,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              )).toList(),
            ),
            
            if (plan.features.length > 5) ...[
              const SizedBox(height: 8),
              Text(
                '+${plan.features.length - 5} más...',
                style: TextStyle(color: tierColor, fontSize: 12),
              ),
            ],

            // Restrictions
            if (plan.restrictions.isNotEmpty && isSelected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plan.restrictions.join(' • '),
                        style: const TextStyle(color: Colors.orange, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Access Schedule
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                Text(
                  plan.accessSchedule == '24/7' 
                      ? 'Acceso 24/7' 
                      : 'Horario: ${plan.accessSchedule}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const Spacer(),
                if (plan.maxClassBookingsPerMonth > 0)
                  Row(
                    children: [
                      const Icon(Icons.fitness_center, color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        plan.maxClassBookingsPerMonth > 100 
                            ? 'Clases: ∞' 
                            : 'Clases: ${plan.maxClassBookingsPerMonth}/mes',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
              ],
            ),
            
            // Selected Indicator
            if (isSelected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: tierColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'SELECCIONADO',
                      style: TextStyle(
                        color: tierColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Checkout Screen
class MembershipCheckoutScreen extends StatefulWidget {
  final MembershipPlan plan;
  final BillingCycle billingCycle;

  const MembershipCheckoutScreen({
    super.key,
    required this.plan,
    required this.billingCycle,
  });

  @override
  State<MembershipCheckoutScreen> createState() => _MembershipCheckoutScreenState();
}

class _MembershipCheckoutScreenState extends State<MembershipCheckoutScreen> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.creditCard;
  bool _autoRenew = true;
  bool _acceptTerms = false;
  bool _isProcessing = false;
  String? _promoCode;
  double _discount = 0;

  double get subtotal => widget.plan.getPriceForCycle(widget.billingCycle);
  double get total => subtotal - _discount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Checkout', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            _buildOrderSummary(),
            
            const SizedBox(height: 24),
            
            // Promo Code
            _buildPromoCodeSection(),
            
            const SizedBox(height: 24),
            
            // Payment Method
            _buildPaymentMethodSection(),
            
            const SizedBox(height: 24),
            
            // Auto Renew
            _buildAutoRenewOption(),
            
            const SizedBox(height: 24),
            
            // Terms
            _buildTermsSection(),
            
            const SizedBox(height: 24),
            
            // Total
            _buildTotalSection(),
            
            const SizedBox(height: 24),
            
            // Pay Button
            _buildPayButton(),
            
            const SizedBox(height: 16),
            
            // Security Note
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: Colors.white38, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Pago seguro con encriptación SSL',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final tierColor = Color(int.parse(widget.plan.tier.colorHex.replaceFirst('#', '0xFF')));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del Pedido',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(widget.plan.tier.icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membresía ${widget.plan.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plan ${widget.billingCycle.displayName}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          _buildSummaryRow('Precio base', '\$${widget.plan.monthlyPrice.toStringAsFixed(2)}/mes'),
          if (widget.billingCycle != BillingCycle.monthly) ...[
            _buildSummaryRow(
              'Duración',
              '${widget.billingCycle.durationDays} días',
            ),
            _buildSummaryRow(
              'Descuento ${widget.billingCycle.displayName.toLowerCase()}',
              '-${widget.billingCycle.discountPercent}%',
              isDiscount: true,
            ),
          ],
          if (_discount > 0)
            _buildSummaryRow(
              'Código promocional',
              '-\$${_discount.toStringAsFixed(2)}',
              isDiscount: true,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: TextStyle(
              color: isDiscount ? Colors.green : Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer, color: QuantumColors.quantumBlue),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Código promocional',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
              onChanged: (value) => _promoCode = value,
            ),
          ),
          TextButton(
            onPressed: () => _applyPromoCode(),
            child: const Text('APLICAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de Pago',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...PaymentMethod.values.take(4).map((method) => _buildPaymentOption(method)),
      ],
    );
  }

  Widget _buildPaymentOption(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: QuantumColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? QuantumColors.quantumBlue : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(method.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method.displayName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: QuantumColors.quantumBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoRenewOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Renovación automática',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Tu membresía se renovará automáticamente',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoRenew,
            onChanged: (value) => setState(() => _autoRenew = value),
            activeThumbColor: QuantumColors.quantumBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) => setState(() => _acceptTerms = value ?? false),
          activeColor: QuantumColors.quantumBlue,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.white70, fontSize: 13),
                children: [
                  TextSpan(text: 'Acepto los '),
                  TextSpan(
                    text: 'Términos y Condiciones',
                    style: TextStyle(
                      color: QuantumColors.quantumBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' y la '),
                  TextSpan(
                    text: 'Política de Privacidad',
                    style: TextStyle(
                      color: QuantumColors.quantumBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuantumColors.quantumBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuantumColors.quantumBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total a Pagar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _acceptTerms && !_isProcessing
            ? () => _processPayment()
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: QuantumColors.quantumBlue,
          disabledBackgroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'PAGAR \$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _applyPromoCode() async {
    final code = _promoCode?.trim().toUpperCase();
    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un código promocional'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('promo_codes')
          .where('code', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (!mounted) return;
        setState(() => _discount = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código inválido o expirado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final doc = query.docs.first.data();
      final expiresAt = doc['expiresAt'] as String?;
      if (expiresAt != null) {
        final expiry = DateTime.tryParse(expiresAt);
        if (expiry != null && expiry.isBefore(DateTime.now())) {
          if (!mounted) return;
          setState(() => _discount = 0);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Código expirado'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final maxUses = doc['maxUses'] as int?;
      final usedCount = doc['usedCount'] as int? ?? 0;
      if (maxUses != null && usedCount >= maxUses) {
        if (!mounted) return;
        setState(() => _discount = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código ha alcanzado el límite de usos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final discountPercent = (doc['discountPercent'] as num?)?.toDouble() ?? 0;
      final discountAmount = (doc['discountAmount'] as num?)?.toDouble() ?? 0;

      if (!mounted) return;
      setState(() {
        if (discountPercent > 0) {
          _discount = subtotal * (discountPercent / 100);
        } else {
          _discount = discountAmount;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Código aplicado! ${discountPercent > 0 ? '${discountPercent.toInt()}% de descuento' : '\$${_discount.toStringAsFixed(2)} de descuento'}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _discount = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al validar código: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final auth = AuthStateNotifier.instance;
      final gymId = auth.profile?.gymId?.value;
      final currentUid = fb.FirebaseAuth.instance.currentUser?.uid;

      if (gymId == null || currentUid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: no se pudo identificar al usuario.'),
              backgroundColor: QuantumColors.error,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      final now = DateTime.now();
      final endDate = now.add(Duration(days: widget.billingCycle.durationDays));

      await FirebaseFirestore.instance.collection('subscriptions').add({
        'userId': currentUid,
        'gymId': gymId,
        'planId': widget.plan.id,
        'planName': widget.plan.name,
        'tier': widget.plan.tier.name,
        'billingCycle': widget.billingCycle.name,
        'status': 'active',
        'startDate': now.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'amount': total,
        'paymentMethod': _selectedPaymentMethod.name,
        'autoRenew': _autoRenew,
        'promoCode': _promoCode,
        'discount': _discount,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isProcessing = false);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: QuantumColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                ),
                const SizedBox(height: 20),
                const Text(
                  '¡Pago Exitoso!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tu membresía ${widget.plan.name} está activa.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Válida por ${widget.billingCycle.durationDays} días',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QuantumColors.quantumBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('¡EMPEZAR A ENTRENAR!'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pago: $e'),
            backgroundColor: QuantumColors.error,
          ),
        );
      }
    }
  }
}
