import 'package:flutter/material.dart';
import 'package:gym_app/core/auth/auth_state_notifier.dart';
import '../../../application/services/churn_analysis_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/theme.dart';
import '../../theme/gym_widgets.dart';

class RetentionPanelScreen extends StatefulWidget {
  const RetentionPanelScreen({super.key});

  @override
  State<RetentionPanelScreen> createState() => _RetentionPanelScreenState();
}

class _RetentionPanelScreenState extends State<RetentionPanelScreen> {
  final _churnService = ChurnAnalysisService();
  List<Map<String, dynamic>> _atRiskUsers = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAtRiskUsers();
  }

  Future<void> _loadAtRiskUsers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      if (gymId == null || gymId.trim().isEmpty) {
        throw Exception('gymId no disponible para el análisis de retención');
      }
      final users = await _churnService.getHighRiskUsers(gymId: gymId);
      setState(() {
        _atRiskUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _atRiskUsers = [];
        _loadError =
            'No se pudieron cargar los datos de retención. Verifica tu conexión e intenta nuevamente.';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendWhatsApp(
    String phone,
    String userName,
    String message,
  ) async {
    final url =
        'https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 0),
          _buildKPIRow(),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4D49FF),
                      ),
                    )
                    : _atRiskUsers.isEmpty
                    ? _buildEmptyState()
                    : _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIRow() {
    final criticalCount =
        _atRiskUsers.where((u) => u['riskLevel'] == 'CRITICAL').length;
    final highCount =
        _atRiskUsers.where((u) => u['riskLevel'] == 'HIGH').length;
    final totalAtRisk = criticalCount + highCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          _buildKPIChip('En Riesgo Total', '$totalAtRisk', Colors.red),
          const SizedBox(width: 16),
          _buildKPIChip('Críticos', '$criticalCount', const Color(0xFFFF3366)),
          const SizedBox(width: 16),
          _buildKPIChip('Alerta Alta', '$highCount', Colors.amber),
          const SizedBox(width: 16),
          _buildKPIChip('Recuperados (Mes)', '7', Colors.green),
          const SizedBox(width: 16),
          _buildKPIChip('Tasa Éxito', '68%', const Color(0xFF4D49FF)),
        ],
      ),
    );
  }

  Widget _buildKPIChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Predictor de Abandono (IA)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4D49FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF4D49FF),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Motor de Predicción v2.1 Activo',
                  style: TextStyle(
                    color: const Color(0xFF4D49FF).withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasError = _loadError != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasError ? Icons.wifi_off_rounded : Icons.verified_rounded,
            color: (hasError ? Colors.redAccent : const Color(0xFF00E676))
                .withValues(alpha: 0.15),
            size: 120,
          ),
          const SizedBox(height: 24),
          Text(
            hasError
                ? 'No se pudo cargar la retención'
                : 'Métricas de retención saludables',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasError
                ? _loadError!
                : 'No se detectan usuarios con riesgo de deserción hoy.',
            style: const TextStyle(color: Colors.white24, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (hasError) ...[
            const SizedBox(height: 24),
            GymButton(
              text: 'Reintentar',
              icon: Icons.refresh_rounded,
              onPressed: _loadAtRiskUsers,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      itemCount: _atRiskUsers.length,
      itemBuilder: (context, index) {
        final user = _atRiskUsers[index];
        final riskLevel = user['riskLevel'] ?? 'HIGH';
        final isCritical = riskLevel == 'CRITICAL';
        final riskColor = isCritical ? const Color(0xFFFF3366) : Colors.amber;

        final lastVisit = user['lastCheckIn'] as DateTime?;
        final daysAbsent =
            lastVisit != null
                ? DateTime.now().difference(lastVisit).inDays
                : 30;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF151725),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Borde izquierdo de riesgo
                Container(width: 6, color: riskColor),
                const SizedBox(width: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      children: [
                        _buildUserAvatar(user['name'], riskColor),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'].toString().toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    color: Colors.white24,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Ausente por $daysAbsent días',
                                    style: const TextStyle(
                                      color: Colors.white24,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildRiskBadge(riskLevel, riskColor),
                        const SizedBox(width: 40),
                        GymButton(
                          text: 'Recuperar',
                          icon: Icons.chat_bubble_rounded,
                          style: GymButtonStyle.secondary,
                          onPressed: () {
                            final msg = _churnService.generateRecoveryMessage(
                              riskLevel,
                              user['name'],
                            );
                            _sendWhatsApp(
                              user['phone'] ?? '',
                              user['name'],
                              msg,
                            );
                          },
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(String name, Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRiskBadge(String level, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
