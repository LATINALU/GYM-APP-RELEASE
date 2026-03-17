import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../theme/theme.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/value_objects/value_objects.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final user = authState.user;
      _firstNameController = TextEditingController(text: user.name.firstName);
      _lastNameController = TextEditingController(text: user.name.lastName);
      _phoneController = TextEditingController(text: user.phone?.value ?? '');
      _weightController = TextEditingController(text: user.weight?.toString() ?? '');
      _heightController = TextEditingController(text: user.height?.toString() ?? '');
      _goalController = TextEditingController(text: user.fitnessGoal ?? '');
    } else {
      _firstNameController = TextEditingController();
      _lastNameController = TextEditingController();
      _phoneController = TextEditingController();
      _weightController = TextEditingController();
      _heightController = TextEditingController();
      _goalController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _save(User user) {
    if (_formKey.currentState!.validate()) {
      final updatedUser = user.updateProfile(
        name: PersonName(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
        ),
        phone: _phoneController.text.isNotEmpty 
            ? PhoneNumber.tryParse(_phoneController.text) 
            : null,
        weight: double.tryParse(_weightController.text),
        height: double.tryParse(_heightController.text),
        fitnessGoal: _goalController.text.isNotEmpty ? _goalController.text : null,
      );

      context.read<AuthBloc>().add(UpdateProfileRequested(updatedUser));
      context.pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: QuantumColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) return const Scaffold();
        final user = state.user;

        return Scaffold(
          backgroundColor: QuantumTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Editar Perfil', style: QuantumTypography.h4),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('DATOS PERSONALES'),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: 'Nombre',
                    controller: _firstNameController,
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Apellido',
                    controller: _lastNameController,
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Teléfono',
                    controller: _phoneController,
                    icon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  
                  const SizedBox(height: 40),
                  _buildSectionTitle('FITNESS (BIOMETRÍA)'),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Peso (kg)',
                          controller: _weightController,
                          icon: Icons.monitor_weight_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          label: 'Altura (cm)',
                          controller: _heightController,
                          icon: Icons.height_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Objetivo Fitness',
                    controller: _goalController,
                    icon: Icons.track_changes_rounded,
                    hint: 'E.g. Perder peso, Ganar músculo...',
                  ),
                  
                  const SizedBox(height: 56),
                  Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: QuantumColors.minimalGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: QuantumColors.quantumBlue.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _save(user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'GUARDAR CAMBIOS', 
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1.2
                        )
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: QuantumTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: QuantumTypography.label.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label, 
            style: QuantumTypography.label.copyWith(
              color: Colors.white38,
              fontSize: 12,
            )
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: QuantumTypography.body.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            prefixIcon: Icon(icon, size: 20, color: QuantumTheme.primary.withValues(alpha: 0.5)),
            filled: true,
            fillColor: QuantumTheme.surface.withValues(alpha: 0.5),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: QuantumTheme.primary.withValues(alpha: 0.5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
          validator: (value) {
            if (label == 'Nombre' && (value == null || value.isEmpty)) {
              return 'Por favor ingresa tu nombre';
            }
            return null;
          },
        ),
      ],
    );
  }
}
