/// Membership Status Screen - Estado actual de membresía con acciones
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';
import '../../../domain/entities/membership.dart';
import 'membership_plans_screen.dart';

class MembershipStatusScreen extends StatefulWidget {
  const MembershipStatusScreen({super.key});

  @override
  State<MembershipStatusScreen> createState() => _MembershipStatusScreenState();
}

class _MembershipStatusScreenState extends State<MembershipStatusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MemberMembership _membership;
  late MemberStatement _statement;
  late List<MemberCharge> _pendingCharges;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final neutralPlan = const MembershipPlan(
      id: '',
      name: 'Sin plan activo',
      description: '',
      tier: MembershipTier.basic,
      monthlyPrice: 0,
      features: [],
    );
    _membership = MemberMembership(
      id: '',
      memberId: '',
      planId: '',
      plan: neutralPlan,
      status: SubscriptionStatus.pending,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      billingCycle: BillingCycle.monthly,
      autoRenew: false,
    );
    _statement = MemberStatement(
      memberId: '',
      generatedAt: DateTime.now(),
      pendingCharges: const [],
      recentPayments: const [],
      currentBalance: 0,
    );
    _pendingCharges = const [];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Mi Membresía',
          style: QuantumTypography.h2.copyWith(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  QuantumColors.quantumBlue.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: QuantumColors.quantumBlue.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.card_membership,
                  color: QuantumColors.quantumBlue,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Membresía aún no sincronizada',
                  style: QuantumTypography.h3.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu estado, pagos y beneficios de membresía reales todavía no están conectados en esta vista.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildNeutralInfoCard(
                  'Estado',
                  'Pendiente',
                  Icons.pending_actions,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNeutralInfoCard(
                  'Balance',
                  '\$0.00',
                  Icons.account_balance_wallet,
                  QuantumColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNeutralInfoCard(
                  'Pagos',
                  '0',
                  Icons.receipt_long,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNeutralInfoCard(
                  'Beneficios',
                  '0',
                  Icons.stars,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: QuantumColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Column(
              children: [
                Icon(Icons.hourglass_top, color: Colors.white38, size: 40),
                SizedBox(height: 12),
                Text(
                  'Sin detalles de membresía para mostrar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Cuando esta sección se conecte al backend, aquí aparecerán tus pagos, vigencia y beneficios reales.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeutralInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard() {
    final tierColor = Color(int.parse(_membership.plan.tier.colorHex.replaceFirst('#', '0xFF')));
    final statusColor = Color(int.parse(_membership.status.colorHex.replaceFirst('#', '0xFF')));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tierColor.withValues(alpha: 0.4),
            QuantumColors.cosmicBlack,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_membership.status.icon, color: statusColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _membership.status.displayName.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (_membership.autoRenew)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.autorenew, color: Colors.blue, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Auto-renovar',
                        style: TextStyle(color: Colors.blue, fontSize: 10),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Plan Name
          Row(
            children: [
              Text(_membership.plan.tier.icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membresía ${_membership.plan.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_membership.billingCycle.displayName} • ${_membership.plan.formattedMonthlyPrice}/mes',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Expiry Progress
          _buildExpiryProgress(),
        ],
      ),
    );
  }

  Widget _buildExpiryProgress() {
    final totalDays = _membership.endDate.difference(_membership.startDate).inDays;
    final elapsedDays = DateTime.now().difference(_membership.startDate).inDays;
    final progress = (elapsedDays / totalDays).clamp(0.0, 1.0);
    final daysRemaining = _membership.daysRemaining;

    Color progressColor;
    if (daysRemaining <= 7) {
      progressColor = Colors.red;
    } else if (daysRemaining <= 14) {
      progressColor = Colors.orange;
    } else {
      progressColor = QuantumColors.success;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Período actual', style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text(
              daysRemaining > 0 
                  ? '$daysRemaining días restantes'
                  : 'Vencida',
              style: TextStyle(
                color: progressColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Inicio: ${_formatDate(_membership.startDate)}',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
            Text(
              'Vence: ${_formatDate(_membership.endDate)}',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Clases Usadas',
                  '${_membership.classBookingsUsed}/${_membership.plan.maxClassBookingsPerMonth > 100 ? "∞" : _membership.plan.maxClassBookingsPerMonth}',
                  Icons.fitness_center,
                  QuantumColors.quantumBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pases Invitado',
                  '${_membership.guestPassesUsed}/${_membership.plan.maxGuestPassesPerMonth}',
                  Icons.person_add,
                  Colors.purple,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Locker Info
          if (_membership.lockerNumber != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: QuantumColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock, color: Colors.amber),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Locker Asignado',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        Text(
                          _membership.lockerNumber!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.qr_code, color: Colors.white38),
                ],
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          const Text(
            'Acciones',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildActionTile(
            icon: Icons.rocket_launch,
            title: 'Mejorar Plan',
            subtitle: 'Accede a más beneficios',
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MembershipPlansScreen(
                  isUpgrade: true,
                  currentTier: _membership.plan.tier,
                ),
              ),
            ),
          ),
          
          _buildActionTile(
            icon: Icons.ac_unit,
            title: 'Congelar Membresía',
            subtitle: 'Pausar por vacaciones o enfermedad',
            color: Colors.cyan,
            onTap: () => _showFreezeDialog(),
          ),
          
          _buildActionTile(
            icon: Icons.person_add,
            title: 'Invitar Amigo',
            subtitle: 'Genera un pase de invitado',
            color: Colors.green,
            onTap: () => _showGuestPassDialog(),
          ),
          
          _buildActionTile(
            icon: Icons.autorenew,
            title: 'Configurar Renovación',
            subtitle: _membership.autoRenew ? 'Activada' : 'Desactivada',
            color: Colors.blue,
            onTap: () => _toggleAutoRenew(),
          ),
          
          _buildActionTile(
            icon: Icons.cancel,
            title: 'Cancelar Membresía',
            subtitle: 'Cancelar al final del período',
            color: Colors.red,
            onTap: () => _showCancelDialog(),
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: QuantumColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: isDanger ? Border.all(color: Colors.red.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDanger ? Colors.red : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Balance Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _statement.hasDebt
                    ? Colors.red.withValues(alpha: 0.2)
                    : QuantumColors.success.withValues(alpha: 0.2),
                QuantumColors.cardBackground,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'Balance Actual',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_statement.netBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: _statement.hasDebt ? Colors.red : QuantumColors.success,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_statement.hasDebt)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('PAGAR AHORA'),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Pending Charges
        if (_pendingCharges.isNotEmpty) ...[
          const Text(
            'Cargos Pendientes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._pendingCharges.map((charge) => _buildChargeItem(charge)),
          const SizedBox(height: 20),
        ],
        
        // Payment History
        const Text(
          'Historial de Pagos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._membership.paymentHistory.map((payment) => _buildPaymentItem(payment)),
      ],
    );
  }

  Widget _buildChargeItem(MemberCharge charge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(charge.type.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  charge.description,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Vence: ${_formatDate(charge.date)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            charge.formattedAmount,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(PaymentRecord payment) {
    final statusColor = Color(int.parse(payment.status.colorHex.replaceFirst('#', '0xFF')));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              payment.status == PaymentRecordStatus.completed
                  ? Icons.check_circle
                  : Icons.pending,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.description,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Text(
                      payment.formattedDate,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${payment.method.displayName}',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            payment.formattedAmount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsTab() {
    final plan = _membership.plan;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone Access
          const Text(
            'Acceso a Zonas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GymZoneAccess.values.map((zone) {
              final hasAccess = plan.zoneAccess.contains(zone);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: hasAccess
                      ? QuantumColors.success.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasAccess
                        ? QuantumColors.success.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(zone.icon),
                    const SizedBox(width: 6),
                    Text(
                      zone.displayName,
                      style: TextStyle(
                        color: hasAccess ? Colors.white : Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    if (!hasAccess) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.lock, size: 12, color: Colors.white38),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Features List
          const Text(
            'Beneficios Incluidos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...plan.features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: QuantumColors.success, size: 20),
                const SizedBox(width: 12),
                Text(feature, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          )),
          
          if (plan.restrictions.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Restricciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...plan.restrictions.map((restriction) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Text(restriction, style: const TextStyle(color: Colors.white54)),
                ],
              ),
            )),
          ],
          
          const SizedBox(height: 24),
          
          // Upgrade CTA
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.3),
                  Colors.blue.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Text('👑', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text(
                  '¿Quieres más beneficios?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mejora tu plan y accede a spa, entrenador personal y más.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MembershipPlansScreen(
                        isUpgrade: true,
                        currentTier: plan.tier,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: const Text('VER PLANES'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFreezeDialog() {
    FreezeReason? selectedReason;
    int freezeDays = 7;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: QuantumColors.cosmicBlack,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Congelar Membresía',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pausa tu membresía temporalmente. Los días se añadirán al final de tu período.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              const Text('Razón', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FreezeReason.values.map((reason) {
                  final isSelected = selectedReason == reason;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedReason = reason),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? QuantumColors.quantumBlue
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? QuantumColors.quantumBlue
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        reason.displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Días a congelar', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: freezeDays > 1
                        ? () => setModalState(() => freezeDays--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$freezeDays días',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: (selectedReason != null && freezeDays < selectedReason!.maxDaysAllowed)
                        ? () => setModalState(() => freezeDays++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white54),
                  ),
                ],
              ),
              if (selectedReason != null)
                Text(
                  'Máximo: ${selectedReason!.maxDaysAllowed} días para ${selectedReason!.displayName.toLowerCase()}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedReason != null
                      ? () {
                          Navigator.pop(context);
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Membresía congelada por $freezeDays días'),
                              backgroundColor: Colors.cyan,
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('CONFIRMAR CONGELAMIENTO'),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _showGuestPassDialog() {
    final remaining = _membership.guestPassesRemaining;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QuantumColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pase de Invitado', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_add, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text(
              'Tienes $remaining pases disponibles este mes',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            if (remaining > 0) ...[
              const SizedBox(height: 16),
              const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre del invitado',
                  labelStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (remaining > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pase generado. Presenta el QR en recepción.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('GENERAR PASE'),
            ),
        ],
      ),
    );
  }

  void _toggleAutoRenew() {
    setState(() {
      _membership = _membership.copyWith(autoRenew: !_membership.autoRenew);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _membership.autoRenew
              ? 'Renovación automática activada'
              : 'Renovación automática desactivada',
        ),
        backgroundColor: _membership.autoRenew ? Colors.green : Colors.orange,
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QuantumColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('Cancelar Membresía', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro que deseas cancelar tu membresía?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ Tu acceso seguirá activo hasta:',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                  Text(
                    _formatDate(_membership.endDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('MANTENER'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _membership = _membership.copyWith(
                  status: SubscriptionStatus.cancelled,
                  autoRenew: false,
                );
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Membresía cancelada. Acceso hasta ${_formatDate(_membership.endDate)}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SÍ, CANCELAR'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
