import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';

// Note: In a real DDD app, this should call a UseCase, not access Firestore directly.
// For now, we maintain the functionality while upgrading the UI to Quantum standards.

class ManualLogScreen extends StatefulWidget {
  const ManualLogScreen({super.key});

  @override
  State<ManualLogScreen> createState() => _ManualLogScreenState();
}

class _ManualLogScreenState extends State<ManualLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final DateTime _selectedDate = DateTime.now();
  final TextEditingController _exerciseNameController = TextEditingController();
  String _selectedMuscleGroup = 'Pecho';
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  final List<String> _muscleGroups = [
    'Pecho', 'Espalda', 'Hombros', 'Bíceps', 'Tríceps', 'Piernas', 'Abs', 'Cuerpo Completo', 'Cardio'
  ];

  bool _isLoading = false;

  void _saveWorkoutData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Implementation logic placeholder - should call a repository
        await Future.delayed(const Duration(seconds: 1)); 
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro guardado correctamente')),
          );
          context.pop();
        }
      } catch (e) {
        debugPrint('Error saving: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      appBar: const GymAppBar(title: 'Manual Log'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [QuantumColors.backgroundStart.withValues(alpha: 0.5), QuantumColors.cosmicBlack],
          ),
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: QuantumColors.quantumBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                   _buildDateHeader(),
                   const SizedBox(height: 32),
                   _buildForm(),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: QuantumColors.quantumBlue),
          const SizedBox(width: 16),
          Text(
            DateFormat('EEEE, d MMMM', 'es_ES').format(_selectedDate).toUpperCase(),
            style: QuantumTypography.label.copyWith(color: Colors.white, letterSpacing: 1),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFieldLabel('EJERCICIO'),
          _buildGlassField(_exerciseNameController, 'Ej. Press de Banca', Icons.fitness_center_rounded),
          
          const SizedBox(height: 24),
          _buildFieldLabel('GRUPO MUSCULAR'),
          _buildMuscleDropdown(),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('SETS'),
                    _buildGlassField(_setsController, '0', Icons.layers_rounded, type: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('REPS'),
                    _buildGlassField(_repsController, '0', Icons.repeat_rounded, type: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildFieldLabel('PESO (KG)'),
          _buildGlassField(_weightController, '0.0', Icons.scale_rounded, type: TextInputType.number),

          const SizedBox(height: 48),
          QuantumButton(
            label: 'FINALIZAR REGISTRO',
            onPressed: _saveWorkoutData,
            icon: Icons.check_circle_rounded,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: QuantumTypography.label.copyWith(fontSize: 10, color: Colors.white24, letterSpacing: 2),
      ),
    );
  }

  Widget _buildGlassField(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white12),
          prefixIcon: Icon(icon, color: QuantumColors.quantumBlue.withValues(alpha: 0.5), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: (v) => v == null || v.isEmpty ? '' : null,
      ),
    );
  }

  Widget _buildMuscleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMuscleGroup,
          dropdownColor: QuantumColors.voidGray,
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white24),
          isExpanded: true,
          items: _muscleGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) => setState(() => _selectedMuscleGroup = v!),
        ),
      ),
    );
  }
}
