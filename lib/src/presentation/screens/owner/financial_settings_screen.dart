import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/theme.dart';

class FinancialSettingsScreen extends StatefulWidget {
  const FinancialSettingsScreen({super.key});

  @override
  State<FinancialSettingsScreen> createState() => _FinancialSettingsScreenState();
}

class _FinancialSettingsScreenState extends State<FinancialSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyPriceController = TextEditingController();
  final _annualDiscountController = TextEditingController();
  final _specialPromoController = TextEditingController();
  final _promoDescController = TextEditingController();
  bool _autoNotify = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _monthlyPriceController.dispose();
    _annualDiscountController.dispose();
    _specialPromoController.dispose();
    _promoDescController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      if (gymId == null) {
        throw Exception('No se pudo resolver el gimnasio actual');
      }

      final gymDoc =
          await FirebaseFirestore.instance.collection('gyms').doc(gymId).get();
      final financialSettings = Map<String, dynamic>.from(
        gymDoc.data()?['financialSettings'] as Map? ?? {},
      );
      final promotion = Map<String, dynamic>.from(
        financialSettings['promotion'] as Map? ?? {},
      );
      final notifications = Map<String, dynamic>.from(
        financialSettings['notifications'] as Map? ?? {},
      );

      if (!mounted) return;

      setState(() {
        _monthlyPriceController.text =
            ((financialSettings['monthlyPrice'] as num?)?.toDouble() ?? 0)
                .toStringAsFixed(0);
        _annualDiscountController.text =
            ((financialSettings['annualDiscount'] as num?)?.toDouble() ?? 0)
                .toStringAsFixed(0);
        _specialPromoController.text =
            ((promotion['discountPercent'] as num?)?.toDouble() ?? 0)
                .toStringAsFixed(0);
        _promoDescController.text = promotion['description']?.toString() ?? '';
        _autoNotify = notifications['autoRenewalReminder'] as bool? ?? true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'No se pudo cargar la configuración financiera.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      if (gymId == null) {
        throw Exception('No se pudo resolver el gimnasio actual');
      }

      setState(() => _isSaving = true);

      await FirebaseFirestore.instance.collection('gyms').doc(gymId).set({
        'financialSettings': {
          'monthlyPrice': double.tryParse(_monthlyPriceController.text) ?? 0,
          'annualDiscount':
              double.tryParse(_annualDiscountController.text) ?? 0,
          'promotion': {
            'discountPercent':
                double.tryParse(_specialPromoController.text) ?? 0,
            'description': _promoDescController.text.trim(),
          },
          'notifications': {
            'autoRenewalReminder': _autoNotify,
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada correctamente')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la configuración: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: GymAppBar(
          title: 'Configuración Financiera',
          showBackButton: true,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: const GymAppBar(
          title: 'Configuración Financiera',
          showBackButton: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadSettings,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const GymAppBar(
        title: 'Configuración Financiera',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('Precios de Membresía', Icons.payments_outlined),
              const SizedBox(height: 20),
              _buildModernField(
                label: 'Precio Mensual (USD)',
                prefix: Icons.attach_money,
                controller: _monthlyPriceController,
              ),
              const SizedBox(height: 16),
              _buildModernField(
                label: 'Descuento Anual (%)',
                prefix: Icons.percent,
                controller: _annualDiscountController,
                hint: 'Se aplica al pagar el año completo',
              ),
              
              const SizedBox(height: 40),
              _buildSectionHeader('Promociones Especiales', Icons.auto_awesome_outlined),
              const SizedBox(height: 20),
              _buildModernField(
                label: 'Descuento Promocional (%)',
                prefix: Icons.local_offer_outlined,
                controller: _specialPromoController,
              ),
              const SizedBox(height: 16),
              _buildModernField(
                label: 'Descripción de Promo',
                prefix: Icons.description_outlined,
                controller: _promoDescController,
                hint: 'Ej: Descuento por aniversario',
              ),
              
              const SizedBox(height: 40),
              _buildSectionHeader('Notificaciones Automáticas', Icons.notifications_active_outlined),
              const SizedBox(height: 20),
              _buildToggleCard(
                title: 'Recordatorio de Renovación',
                subtitle: 'Notificar automáticamente 5 días antes de vencer',
                value: _autoNotify,
                onChanged: (v) => setState(() => _autoNotify = v),
              ),

              const SizedBox(height: 60),
              GymButton(
                text: _isSaving ? 'Guardando...' : 'Guardar Configuración',
                fullWidth: true,
                onPressed: _isSaving ? null : _saveSettings,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: GymColors.primary, size: 24),
        const SizedBox(width: 12),
        Text(title, style: QuantumTypography.h3),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildModernField({
    required String label,
    required IconData prefix,
    required TextEditingController controller,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: QuantumTypography.label.copyWith(color: GymColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(prefix, color: GymColors.primary, size: 20),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            filled: true,
            fillColor: const Color(0xFF16162A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: GymColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return GymCard(
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: QuantumTypography.bodyLarge),
        subtitle: Text(subtitle, style: QuantumTypography.bodySmall.copyWith(color: GymColors.textSecondary)),
        activeThumbColor: GymColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
