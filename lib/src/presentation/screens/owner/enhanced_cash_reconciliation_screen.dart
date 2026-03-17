import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/quantum_colors.dart';

class EnhancedCashReconciliationScreen extends StatefulWidget {
  const EnhancedCashReconciliationScreen({super.key});

  @override
  State<EnhancedCashReconciliationScreen> createState() =>
      _EnhancedCashReconciliationScreenState();
}

class _EnhancedCashReconciliationScreenState
    extends State<EnhancedCashReconciliationScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _cashController = TextEditingController();
  final _cardController = TextEditingController();
  final _transferController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isReconciled = false;
  bool _isSaving = false;
  Map<String, dynamic>? _systemData;

  @override
  void initState() {
    super.initState();
    _loadSystemData();
  }

  Future<void> _loadSystemData() async {
    final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    if (gymId == null || gymId.trim().isEmpty) {
      setState(() {
        _systemData = {
          'cashSales': 0.0,
          'cardSales': 0.0,
          'transferSales': 0.0,
          'membershipRevenue': 0.0,
          'totalTransactions': 0,
          'totalExpected': 0.0,
        };
      });
      return;
    }

    try {
      // Obtener ventas del día
      final salesSnapshot =
          await _firestore
              .collection('pos_sales')
              .where('gymId', isEqualTo: gymId)
              .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
              .get();

      double cashSales = 0;
      double cardSales = 0;
      double transferSales = 0;
      int totalTransactions = salesSnapshot.docs.length;

      for (var doc in salesSnapshot.docs) {
        final data = doc.data();
        final total = (data['total'] as num).toDouble();
        final method = data['paymentMethod'] as String;

        switch (method) {
          case 'cash':
            cashSales += total;
            break;
          case 'card':
            cardSales += total;
            break;
          case 'transfer':
            transferSales += total;
            break;
        }
      }

      // Obtener membresías vendidas del día
      final membershipsSnapshot =
          await _firestore
              .collection('memberships')
              .where('gymId', isEqualTo: gymId)
              .where('purchaseDate', isGreaterThanOrEqualTo: startOfDay)
              .get();

      double membershipRevenue = 0;
      for (var doc in membershipsSnapshot.docs) {
        final data = doc.data();
        membershipRevenue += (data['price'] as num?)?.toDouble() ?? 0;
      }

      setState(() {
        _systemData = {
          'cashSales': cashSales,
          'cardSales': cardSales,
          'transferSales': transferSales,
          'membershipRevenue': membershipRevenue,
          'totalTransactions': totalTransactions,
          'totalExpected':
              cashSales + cardSales + transferSales + membershipRevenue,
        };
      });
    } catch (e) {
      print('Error loading system data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      body:
          _systemData == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildInputPanel()),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: _buildSystemPanel()),
                      ],
                    ),
                    if (_isReconciled) ...[
                      const SizedBox(height: 32),
                      _buildResultsPanel(),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            QuantumColors.quantumBlue.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QuantumColors.quantumBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: QuantumColors.quantumBlue,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CONCILIACIÓN DE CAJA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cierre del día ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: QuantumColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: QuantumColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: QuantumColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AuthStateNotifier.instance.profile?.displayName ?? 'Usuario',
                  style: const TextStyle(
                    color: QuantumColors.success,
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

  Widget _buildInputPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTEO FÍSICO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa los montos reales contados',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          _buildInputField(
            'Efectivo en Caja',
            _cashController,
            Icons.payments_outlined,
            QuantumColors.success,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            'Ventas con Tarjeta',
            _cardController,
            Icons.credit_card_outlined,
            QuantumColors.quantumBlue,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            'Transferencias',
            _transferController,
            Icons.account_balance_outlined,
            QuantumColors.matrixCyan,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Notas / Observaciones',
              labelStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(
                Icons.note_outlined,
                color: Colors.white54,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _cashController.clear();
                    _cardController.clear();
                    _transferController.clear();
                    _notesController.clear();
                    setState(() => _isReconciled = false);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  label: const Text(
                    'LIMPIAR',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isReconciled = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QuantumColors.quantumBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.calculate, color: Colors.black),
                  label: const Text(
                    'VERIFICAR',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color),
            prefixText: '\$ ',
            prefixStyle: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemPanel() {
    final data = _systemData!;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.computer_rounded,
                color: QuantumColors.quantumBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'DATOS DEL SISTEMA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSystemRow(
            'Ventas en Efectivo',
            data['cashSales'],
            QuantumColors.success,
          ),
          _buildSystemRow(
            'Ventas con Tarjeta',
            data['cardSales'],
            QuantumColors.quantumBlue,
          ),
          _buildSystemRow(
            'Transferencias',
            data['transferSales'],
            QuantumColors.matrixCyan,
          ),
          const Divider(color: Colors.white10, height: 32),
          _buildSystemRow(
            'Ingresos por Membresías',
            data['membershipRevenue'],
            QuantumColors.accent,
          ),
          const Divider(color: Colors.white10, height: 32),
          _buildSystemRow(
            'TOTAL ESPERADO',
            data['totalExpected'],
            Colors.white,
            isTotal: true,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QuantumColors.quantumBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: QuantumColors.quantumBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${data['totalTransactions']} transacciones',
                  style: const TextStyle(
                    color: QuantumColors.quantumBlue,
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

  Widget _buildSystemRow(
    String label,
    double value,
    Color color, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.white70,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    final cash = double.tryParse(_cashController.text) ?? 0;
    final card = double.tryParse(_cardController.text) ?? 0;
    final transfer = double.tryParse(_transferController.text) ?? 0;
    final totalReal = cash + card + transfer;
    final totalExpected = _systemData!['totalExpected'] as double;
    final diff = totalReal - totalExpected;
    final isMatch = diff.abs() < 0.01;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMatch ? QuantumColors.success : Colors.redAccent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMatch ? Icons.check_circle : Icons.warning_rounded,
                color: isMatch ? QuantumColors.success : Colors.redAccent,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMatch ? 'CAJA CUADRADA' : 'DISCREPANCIA DETECTADA',
                      style: TextStyle(
                        color:
                            isMatch ? QuantumColors.success : Colors.redAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isMatch)
                      Text(
                        diff > 0
                            ? 'Sobrante: \$${diff.toStringAsFixed(2)}'
                            : 'Faltante: \$${diff.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 40),
          _buildComparisonRow('Efectivo', cash, _systemData!['cashSales']),
          _buildComparisonRow('Tarjeta', card, _systemData!['cardSales']),
          _buildComparisonRow(
            'Transferencia',
            transfer,
            _systemData!['transferSales'],
          ),
          const Divider(color: Colors.white10, height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL DECLARADO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${totalReal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL ESPERADO',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '\$${totalExpected.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _isSaving
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                onPressed: () => _finishCierre(totalReal, totalExpected, diff),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isMatch ? QuantumColors.success : Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  minimumSize: const Size(double.infinity, 0),
                ),
                icon: const Icon(Icons.lock_rounded, color: Colors.black),
                label: const Text(
                  'CERRAR CAJA Y FIRMAR',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, double actual, double expected) {
    final diff = actual - expected;
    final isMatch = diff.abs() < 0.01;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                isMatch
                    ? '✓ Cuadrado'
                    : (diff > 0
                        ? '+\$${diff.toStringAsFixed(2)}'
                        : '-\$${diff.abs().toStringAsFixed(2)}'),
                style: TextStyle(
                  color:
                      isMatch
                          ? QuantumColors.success
                          : (diff > 0 ? Colors.blue : Colors.redAccent),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            '\$${actual.toStringAsFixed(2)}',
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

  Future<void> _finishCierre(double real, double expected, double diff) async {
    setState(() => _isSaving = true);
    final auth = AuthStateNotifier.instance;
    final gymId = auth.profile?.gymId?.value;

    try {
      if (gymId == null || gymId.trim().isEmpty) {
        throw Exception('gymId no disponible para cerrar caja');
      }

      await _firestore.collection('daily_closings').add({
        'gymId': gymId,
        'expected_amount': expected,
        'real_amount': real,
        'discrepancy': diff,
        'cash_declared': double.tryParse(_cashController.text) ?? 0,
        'card_declared': double.tryParse(_cardController.text) ?? 0,
        'transfer_declared': double.tryParse(_transferController.text) ?? 0,
        'cash_expected': _systemData!['cashSales'],
        'card_expected': _systemData!['cardSales'],
        'transfer_expected': _systemData!['transferSales'],
        'membership_revenue': _systemData!['membershipRevenue'],
        'total_transactions': _systemData!['totalTransactions'],
        'notes': _notesController.text,
        'closed_by': auth.profile?.uid,
        'staff_name': auth.profile?.displayName,
        'timestamp': FieldValue.serverTimestamp(),
        'status': diff.abs() < 0.01 ? 'MATCH' : 'MISMATCH',
      });

      await _firestore.collection('audit_logs').add({
        'gymId': gymId,
        'who': auth.profile?.displayName ?? 'Staff',
        'action': 'CIERRE_CAJA',
        'details':
            diff.abs() < 0.01
                ? 'Caja cerrada cuadrada - Total: \$${real.toStringAsFixed(2)}'
                : 'Cierre con ${diff > 0 ? "sobrante" : "faltante"} de \$${diff.abs().toStringAsFixed(2)}',
        'timestamp': FieldValue.serverTimestamp(),
        'module': 'FINANZAS',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Caja cerrada y auditada exitosamente'),
            backgroundColor: QuantumColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
