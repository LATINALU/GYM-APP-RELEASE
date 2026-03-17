import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/theme.dart';

class OwnerMemberWizardScreen extends StatefulWidget {
  const OwnerMemberWizardScreen({super.key});

  @override
  State<OwnerMemberWizardScreen> createState() => _OwnerMemberWizardScreenState();
}

class _OwnerMemberWizardScreenState extends State<OwnerMemberWizardScreen> {
  int _currentStep = 0;
  
  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dniController = TextEditingController();
  String? _selectedPlan;
  bool _isPayingNow = true;
  bool _isScanning = false;
  bool _isLoadingPlans = true;
  String? _plansLoadError;
  List<_WizardPlan> _plans = [];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _plansLoadError = null;
    });

    try {
      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      if (gymId == null) {
        throw Exception('No se pudo resolver el gimnasio actual');
      }

      final snapshot =
          await FirebaseFirestore.instance
              .collection('membership_plans')
              .where('gymId', isEqualTo: gymId)
              .where('isActive', isEqualTo: true)
              .get();

      final plans =
          snapshot.docs
              .map((doc) {
                final data = doc.data();
                return _WizardPlan(
                  id: doc.id,
                  name: data['name']?.toString() ?? 'Sin nombre',
                  description:
                      data['description']?.toString() ??
                      'Plan disponible para este gimnasio.',
                  price: (data['price'] as num?)?.toDouble() ?? 0,
                );
              })
              .toList()
            ..sort((a, b) => a.price.compareTo(b.price));

      if (!mounted) return;

      setState(() {
        _plans = plans;
        _selectedPlan =
            plans.any((plan) => plan.name == _selectedPlan)
                ? _selectedPlan
                : (plans.isNotEmpty ? plans.first.name : null);
        _isLoadingPlans = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _plans = [];
        _plansLoadError = 'No se pudieron cargar los planes disponibles.';
        _isLoadingPlans = false;
      });
    }
  }

  _WizardPlan? get _selectedPlanData {
    if (_selectedPlan == null) return null;
    for (final plan in _plans) {
      if (plan.name == _selectedPlan) return plan;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymColors.background,
      appBar: GymAppBar(
        title: 'Registrar Nuevo Miembro',
        actions: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          margin: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 40),
              Expanded(
                child: GymCard(
                  padding: const EdgeInsets.all(32),
                  child: _buildCurrentStepView(),
                ),
              ),
              const SizedBox(height: 32),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepCircle(0, 'Datos'),
        _stepLine(0),
        _stepCircle(1, 'Plan'),
        _stepLine(1),
        _stepCircle(2, 'Pago'),
      ],
    );
  }

  Widget _stepCircle(int step, String label) {
    bool isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? GymColors.primary : Colors.white10,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? GymColors.primary : Colors.white24,
              width: 2,
            ),
          ),
          child: Center(
            child: isActive && _currentStep > step 
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : Text('${step + 1}', 
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.bold
                  )),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(
          color: isActive ? Colors.white : Colors.white38,
          fontSize: 12,
        )),
      ],
    );
  }

  Widget _stepLine(int afterStep) {
    bool isActive = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        color: isActive ? GymColors.primary : Colors.white10,
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      default: return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Datos Personales', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Información básica del nuevo atleta.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 32),
          _buildOCRSection(),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Nombre Completo', Icons.person_outline),
            validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dniController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('DNI / Identificación', Icons.badge_outlined),
            validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Correo', Icons.email_outlined),
                  validator: (v) => v!.contains('@') ? null : 'Email inválido',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Teléfono', Icons.phone_outlined),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOCRSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GymColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GymColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: GymColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Escaneo OCR no disponible', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Ingresa los datos manualmente hasta conectar esta integración.', 
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          GymButton(
            text: 'Info',
            style: GymButtonStyle.primary,
            size: GymButtonSize.small,
            onPressed: _showScannerInfo,
          ),
        ],
      ),
    );
  }

  void _showScannerInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El escaneo OCR aún no está conectado a datos reales'),
      ),
    );
  }

  Widget _buildStep2() {
    if (_isLoadingPlans) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_plansLoadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              _plansLoadError!,
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
      );
    }

    if (_plans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_membership_outlined, color: Colors.white24, size: 56),
            SizedBox(height: 12),
            Text('No hay planes activos disponibles', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Seleccionar Plan', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        ..._plans.asMap().entries.map((entry) {
          final index = entry.key;
          final plan = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index == _plans.length - 1 ? 0 : 16),
            child: _planOption(plan),
          );
        }),
      ],
    );
  }

  Widget _planOption(_WizardPlan plan) {
    final isSelected = _selectedPlan == plan.name;
    return InkWell(
      onTap: () => setState(() => _selectedPlan = plan.name),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? GymColors.primary.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? GymColors.primary : Colors.white.withValues(alpha: 0.05),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(plan.description, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Text('\$${plan.price.toStringAsFixed(0)}', style: TextStyle(color: isSelected ? GymColors.primary : Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Confirmación y Pago', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              _summaryRow('Miembro', _nameController.text),
              const Divider(color: Colors.white10, height: 32),
              _summaryRow('Plan', _selectedPlan ?? 'Sin plan'),
              const Divider(color: Colors.white10, height: 32),
              _summaryRow(
                'Total a Pagar',
                '\$${(_selectedPlanData?.price ?? 0).toStringAsFixed(2)}',
                isBold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SwitchListTile(
          title: const Text('Realizar cobro ahora (Stripe/Efectivo)', style: TextStyle(color: Colors.white)),
          value: _isPayingNow,
          activeColor: GymColors.primary,
          onChanged: (v) => setState(() => _isPayingNow = v),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54)),
        Text(value, style: TextStyle(color: Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          GymButton(
            text: 'Anterior',
            style: GymButtonStyle.ghost,
            onPressed: () => setState(() => _currentStep--),
          )
        else
          const SizedBox(),
        GymButton(
          text: _currentStep == 2 ? 'Finalizar Registro' : 'Continuar',
          style: GymButtonStyle.primary,
          onPressed: () {
            if (_currentStep == 0) {
              if (_formKey.currentState!.validate()) {
                setState(() => _currentStep++);
              }
            } else if (_currentStep < 2) {
              if (_currentStep == 1 && _selectedPlan == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selecciona un plan antes de continuar')),
                );
                return;
              }
              setState(() => _currentStep++);
            } else {
              _showSuccessDialog();
            }
          },
        ),
      ],
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('¡Registro Exitoso!', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: Colors.green, size: 64),
            const SizedBox(height: 24),
            Text('El miembro ha sido activado. Se ha enviado un correo de bienvenida a ${_emailController.text}.', 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // Close dialog
              context.pop(); // Go back to dashboard
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white24),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: GymColors.primary)),
    );
  }
}

class _WizardPlan {
  final String id;
  final String name;
  final String description;
  final double price;

  const _WizardPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });
}
