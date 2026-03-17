import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../theme/gym_widgets.dart';
import '../../../../core/auth/auth_state_notifier.dart';

class OwnerCashReconciliationScreen extends StatefulWidget {
  const OwnerCashReconciliationScreen({super.key});

  @override
  State<OwnerCashReconciliationScreen> createState() =>
      _OwnerCashReconciliationScreenState();
}

class _OwnerCashReconciliationScreenState
    extends State<OwnerCashReconciliationScreen> {
  final _cashController = TextEditingController();
  final _cardController = TextEditingController();
  final _transferController = TextEditingController();

  // System values (In prod, these come from current day's collection)
  final double _expectedCash = 450.00;
  final double _expectedCard = 1200.50;
  final double _expectedTransfer = 300.25;

  bool _isReconciled = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        padding: const EdgeInsets.all(40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel Izquierdo: Entrada de Datos Blind
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conciliación Ciega',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ingresa los montos físicos contados. Los faltantes serán auditados automáticamente.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildInputGroup(
                    'Efectivo en Caja',
                    _cashController,
                    Icons.payments_outlined,
                  ),
                  const SizedBox(height: 24),
                  _buildInputGroup(
                    'Total Ventas Posnet',
                    _cardController,
                    Icons.credit_card_outlined,
                  ),
                  const SizedBox(height: 24),
                  _buildInputGroup(
                    'Comprobantes Bancarios',
                    _transferController,
                    Icons.account_balance_outlined,
                  ),
                  const Spacer(),
                  _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : GymButton(
                        text: 'Verificar Desajustes',
                        fullWidth: true,
                        onPressed: () => setState(() => _isReconciled = true),
                      ),
                ],
              ),
            ),
            const SizedBox(width: 80),
            // Panel Derecho: Resultados e IA
            Expanded(
              flex: 2,
              child:
                  _isReconciled ? _buildResultsPanel() : _buildWaitingPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputGroup(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.attach_money_rounded,
              color: Color(0xFF4D49FF),
            ),
            filled: true,
            fillColor: const Color(0xFF151725),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsPanel() {
    final double cash = double.tryParse(_cashController.text) ?? 0;
    final double card = double.tryParse(_cardController.text) ?? 0;
    final double transfer = double.tryParse(_transferController.text) ?? 0;

    final totalExpected = _expectedCash + _expectedCard + _expectedTransfer;
    final totalReal = cash + card + transfer;
    final totalDiff = totalReal - totalExpected;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF151725),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reporte de Cierre',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          _diffRow('Efectivo', cash, _expectedCash),
          _diffRow('Tarjeta', card, _expectedCard),
          _diffRow('Banco', transfer, _expectedTransfer),
          const Divider(color: Colors.white10, height: 48),
          _summaryRow('Auditado por Sistema', totalExpected),
          _summaryRow('Declarado por Usuario', totalReal, isBold: true),
          const SizedBox(height: 24),
          _buildStatusBadge(totalDiff),
          const Spacer(),
          GymButton(
            text: 'Cerrar y Firmar Digitalmente',
            fullWidth: true,
            onPressed: () => _finishCierre(totalReal, totalExpected, totalDiff),
          ),
        ],
      ),
    );
  }

  Widget _diffRow(String label, double actual, double expected) {
    final diff = actual - expected;
    final isMatch = diff.abs() < 0.01;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70)),
              Text(
                '\$${actual.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isMatch
                ? 'CUADRADO ✓'
                : (diff > 0
                    ? 'SOBRANTE: +\$${diff.toStringAsFixed(2)}'
                    : 'FALTANTE: -\$${diff.abs().toStringAsFixed(2)}'),
            style: TextStyle(
              color:
                  isMatch
                      ? const Color(0xFF00E676)
                      : (diff > 0 ? Colors.blue : const Color(0xFFFF3366)),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 20 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(double diff) {
    final bool isMatch = diff.abs() < 0.01;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isMatch ? const Color(0xFF00E676) : const Color(0xFFFF3366))
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          isMatch
              ? 'CIERRE EXITOSO - SIN DISCREPANCIAS'
              : 'DISCREPANCIA DETECTADA - REQUIERE REVISIÓN',
          style: TextStyle(
            color: isMatch ? const Color(0xFF00E676) : const Color(0xFFFF3366),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151725),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_clock_rounded,
              color: Colors.white.withValues(alpha: 0.05),
              size: 120,
            ),
            const SizedBox(height: 24),
            const Text(
              'Ingresa los montos para auditar',
              style: TextStyle(color: Colors.white12, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finishCierre(double real, double expected, double diff) async {
    setState(() => _isSaving = true);
    final auth = AuthStateNotifier.instance;
    final gymId = auth.profile?.gymId?.value;

    try {
      if (gymId == null || gymId.trim().isEmpty) {
        throw Exception('gymId no disponible para cerrar caja');
      }

      await FirebaseFirestore.instance.collection('daily_closings').add({
        'gymId': gymId,
        'expected_amount': expected,
        'real_amount': real,
        'discrepancy': diff,
        'closed_by': auth.profile?.uid,
        'staff_name': auth.profile?.displayName,
        'timestamp': FieldValue.serverTimestamp(),
        'status': diff.abs() < 0.01 ? 'MATCH' : 'MISMATCH',
      });

      // Auditoría Inmutable
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'gymId': gymId,
        'who': auth.profile?.displayName ?? 'Staff',
        'action': 'CIERRE_CAJA',
        'details':
            diff.abs() < 0.01
                ? 'Caja cerrada cuadrada'
                : 'Cierre con desajuste de \$${diff.toStringAsFixed(2)}',
        'timestamp': FieldValue.serverTimestamp(),
        'module': 'FINANZAS',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00E676),
            content: Text('¡Caja cerrada y auditada!'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFFF3366),
            content: Text('Error: $e'),
          ),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
