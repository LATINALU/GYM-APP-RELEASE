/// Loyalty Rewards Screen - Sistema de puntos y recompensas
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/theme.dart';
import '../../bloc/app_bloc.dart';
import '../../../domain/entities/loyalty_program.dart';

class LoyaltyRewardsScreen extends StatefulWidget {
  const LoyaltyRewardsScreen({super.key});

  @override
  State<LoyaltyRewardsScreen> createState() => _LoyaltyRewardsScreenState();
}

class _LoyaltyRewardsScreenState extends State<LoyaltyRewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MemberLoyaltyStatus _loyaltyStatus;
  late List<Reward> _rewards;
  RewardCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loyaltyStatus = const MemberLoyaltyStatus(
      memberId: '',
      currentPoints: 0,
      totalEarnedPoints: 0,
      totalRedeemedPoints: 0,
      tier: LoyaltyTier.bronze,
    );
    _rewards = const [];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Reward> get _filteredRewards {
    if (_selectedCategory == null) return _rewards;
    return _rewards.where((r) => r.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final currentStreak = state is AppLoaded ? state.currentStreak : 0;
        final longestStreak = state is AppLoaded ? state.longestStreak : 0;
        final totalWorkouts = state is AppLoaded ? state.totalWorkouts : 0;
        final workoutsThisWeek = state is AppLoaded ? state.workoutsThisWeek : 0;

        return Scaffold(
          backgroundColor: QuantumColors.cosmicBlack,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Recompensas',
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
                      Icons.card_giftcard,
                      color: QuantumColors.quantumBlue,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Programa de recompensas no disponible',
                      style: QuantumTypography.h3.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tu actividad real ya se registra, pero los puntos, canjes y referidos todavía no están sincronizados con backend.',
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
                    child: _buildRealMetricCard(
                      'Racha actual',
                      '$currentStreak',
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRealMetricCard(
                      'Racha máxima',
                      '$longestStreak',
                      Icons.emoji_events,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildRealMetricCard(
                      'Entrenos',
                      '$totalWorkouts',
                      Icons.fitness_center,
                      QuantumColors.quantumBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRealMetricCard(
                      'Esta semana',
                      '$workoutsThisWeek',
                      Icons.calendar_today,
                      Colors.green,
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
                      'Sin recompensas para mostrar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cuando el sistema de loyalty esté conectado, aquí verás tu historial, catálogo y beneficios reales.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRealMetricCard(
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

  Widget _buildHeader() {
    final tier = _loyaltyStatus.tier;
    final tierColor = Color(int.parse(tier.colorHex.replaceFirst('#', '0xFF')));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tierColor.withValues(alpha: 0.3),
            QuantumColors.cosmicBlack,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tierColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tier.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'NIVEL ${tier.displayName.toUpperCase()}',
                      style: TextStyle(
                        color: tierColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              // Streak
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_loyaltyStatus.currentStreak} días',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Points Display
          Center(
            child: Column(
              children: [
                Text(
                  '${_loyaltyStatus.currentPoints}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const Text(
                  'PUNTOS DISPONIBLES',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Progress to Next Tier
          if (_loyaltyStatus.tier != LoyaltyTier.platinum) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Próximo nivel',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          Text(
                            '${_loyaltyStatus.pointsToNextTier} pts restantes',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _loyaltyStatus.tierProgress / 100,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: tierColor,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    return Column(
      children: [
        // Category Filter
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip(null, 'Todos'),
              ...RewardCategory.values.map((c) => _buildCategoryChip(c, c.displayName)),
            ],
          ),
        ),
        
        // Rewards Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _filteredRewards.length,
            itemBuilder: (context, index) => _RewardCard(
              reward: _filteredRewards[index],
              currentPoints: _loyaltyStatus.currentPoints,
              onRedeem: () => _redeemReward(_filteredRewards[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(RewardCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? QuantumColors.quantumBlue : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? QuantumColors.quantumBlue : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final transactions = _loyaltyStatus.recentTransactions;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QuantumColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Ganados', '${_loyaltyStatus.totalEarnedPoints}', Colors.green),
                Container(width: 1, height: 40, color: Colors.white12),
                _buildStatColumn('Canjeados', '${_loyaltyStatus.totalRedeemedPoints}', Colors.orange),
                Container(width: 1, height: 40, color: Colors.white12),
                _buildStatColumn('Racha Máx', '${_loyaltyStatus.longestStreak}', Colors.amber),
              ],
            ),
          );
        }
        
        final tx = transactions[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
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
                  color: tx.isRedemption
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(tx.reason.icon, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.reason.displayName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _formatDate(tx.timestamp),
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${tx.isRedemption ? '-' : '+'}${tx.points}',
                style: TextStyle(
                  color: tx.isRedemption ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildReferralsTab() {
    final referralCode = 'GYM001${_loyaltyStatus.memberId.substring(0, 4).toUpperCase()}';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Referral Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [QuantumColors.quantumBlue.withValues(alpha: 0.3), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: QuantumColors.quantumBlue.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.card_giftcard, color: QuantumColors.quantumBlue, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Invita amigos, gana puntos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gana 100 puntos por cada amigo que se registre con tu código. Tu amigo también recibe 7 días gratis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                
                // Code Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        referralCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.copy, color: QuantumColors.quantumBlue),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralCode));
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código copiado'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: QuantumColors.success,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Share Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.share),
                        label: const Text('COMPARTIR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: QuantumColors.quantumBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats
          Row(
            children: [
              Expanded(
                child: _buildReferralStat('Referidos', '3', Icons.people),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReferralStat('Puntos Ganados', '300', Icons.stars),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Benefits
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QuantumColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Beneficios de tu nivel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._loyaltyStatus.tier.benefits.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: QuantumColors.success, size: 18),
                      const SizedBox(width: 12),
                      Text(b, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: QuantumColors.quantumBlue, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  void _redeemReward(Reward reward) async {
    if (_loyaltyStatus.currentPoints < reward.pointsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes suficientes puntos'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QuantumColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Canjear Recompensa', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reward.icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              reward.name,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${reward.pointsCost} puntos',
              style: const TextStyle(color: QuantumColors.quantumBlue, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Confirmas el canje?',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: QuantumColors.quantumBlue,
            ),
            child: const Text('CANJEAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      setState(() {
        _loyaltyStatus = MemberLoyaltyStatus(
          memberId: _loyaltyStatus.memberId,
          currentPoints: _loyaltyStatus.currentPoints - reward.pointsCost,
          totalEarnedPoints: _loyaltyStatus.totalEarnedPoints,
          totalRedeemedPoints: _loyaltyStatus.totalRedeemedPoints + reward.pointsCost,
          tier: _loyaltyStatus.tier,
          currentStreak: _loyaltyStatus.currentStreak,
          longestStreak: _loyaltyStatus.longestStreak,
        );
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ ${reward.name} canjeado con éxito'),
          backgroundColor: QuantumColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _RewardCard extends StatelessWidget {
  final Reward reward;
  final int currentPoints;
  final VoidCallback onRedeem;

  const _RewardCard({
    required this.reward,
    required this.currentPoints,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = currentPoints >= reward.pointsCost;
    final categoryColor = _getCategoryColor(reward.category);

    return Container(
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canAfford ? categoryColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon & Category
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      reward.icon,
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reward.category.icon,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  if (reward.stockRemaining != null && reward.stockRemaining! <= 5)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '¡Quedan ${reward.stockRemaining}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${reward.pointsCost} pts',
                      style: TextStyle(
                        color: canAfford ? QuantumColors.quantumBlue : Colors.white38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: canAfford ? onRedeem : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: canAfford
                              ? QuantumColors.quantumBlue
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Canjear',
                          style: TextStyle(
                            color: canAfford ? Colors.white : Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Color _getCategoryColor(RewardCategory category) {
    switch (category) {
      case RewardCategory.product:
        return Colors.blue;
      case RewardCategory.service:
        return Colors.purple;
      case RewardCategory.membership:
        return Colors.green;
      case RewardCategory.discount:
        return Colors.orange;
      case RewardCategory.experience:
        return Colors.pink;
    }
  }
}
