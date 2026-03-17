import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../domain/ports/output/auth_repository_port.dart';
import '../../../domain/ports/output/email_service_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../theme/theme.dart';

class AdminOwnersLiveScreen extends StatefulWidget {
  const AdminOwnersLiveScreen({super.key});

  @override
  State<AdminOwnersLiveScreen> createState() => _AdminOwnersLiveScreenState();
}

class _AdminOwnersLiveScreenState extends State<AdminOwnersLiveScreen> {
  final FirebaseFirestore _firestore = GetIt.I<FirebaseFirestore>();
  final AuthRepositoryPort _authRepository = GetIt.I<AuthRepositoryPort>();
  final EmailServicePort _emailService = GetIt.I<EmailServicePort>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isCreating = false;
  String? _selectedGymId;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _fullName(Map<String, dynamic> data) {
    final firstName = data['firstName']?.toString().trim() ?? '';
    final lastName = data['lastName']?.toString().trim() ?? '';
    return '$firstName $lastName'.trim().isEmpty
        ? 'Sin nombre'
        : '$firstName $lastName'.trim();
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) {
      return 'Sin fecha';
    }
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) {
      return isoDate;
    }
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }

  Future<void> _createOwner(
    BuildContext dialogContext,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> gyms,
  ) async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = Email.tryParse(_emailController.text.trim());
    final password = _passwordController.text.trim();
    final phone = PhoneNumber.tryParse(_phoneController.text.trim());

    if (firstName.isEmpty) {
      _showError('El nombre del dueño es obligatorio');
      return;
    }
    if (email == null) {
      _showError('El correo del dueño no es válido');
      return;
    }
    if (password.length < 8) {
      _showError('La contraseña temporal debe tener al menos 8 caracteres');
      return;
    }
    if (_phoneController.text.trim().isNotEmpty && phone == null) {
      _showError('El teléfono del dueño no es válido');
      return;
    }
    if (_selectedGymId == null || _selectedGymId!.isEmpty) {
      _showError('Selecciona un gimnasio para el dueño');
      return;
    }

    setState(() => _isCreating = true);
    try {
      final name = PersonName(firstName: firstName, lastName: lastName);
      final result = await _authRepository.provisionUser(
        email: email,
        password: password,
        name: name,
        role: const GymRole.owner(),
        gymId: GymId(_selectedGymId!),
        phone: phone,
      );

      await result.fold(
        (failure) async {
          _showError(failure.message);
        },
        (success) async {
          final selectedGym = gyms.firstWhere(
            (gym) => gym.id == _selectedGymId,
            orElse: () => gyms.first,
          );
          final gymName = selectedGym.data()['name']?.toString() ?? 'tu gimnasio';
          final emailResult = await _emailService.sendWelcomeEmail(
            to: email,
            userName: name.fullName,
            temporaryPassword: password,
            appDownloadLink: 'https://gym-app.com/dashboard',
          );

          if (!mounted || !dialogContext.mounted) return;
          Navigator.of(dialogContext).pop();

          if (emailResult.success) {
            _showSuccess('Dueño creado y vinculado a $gymName');
          } else {
            _showSuccess('Dueño creado y vinculado a $gymName. El email de bienvenida quedó pendiente.');
          }
        },
      );
    } catch (e) {
      _showError('No se pudo crear el dueño: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _openCreateOwnerDialog(List<QueryDocumentSnapshot<Map<String, dynamic>>> gyms) {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _selectedGymId = gyms.isNotEmpty ? gyms.first.id : null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: QuantumColors.surface(),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                width: 540,
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crear dueño de gimnasio',
                      style: QuantumTypography.h2.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDialogField(
                            controller: _firstNameController,
                            label: 'Nombre',
                            hint: 'Nombre del dueño',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDialogField(
                            controller: _lastNameController,
                            label: 'Apellido',
                            hint: 'Apellido del dueño',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDialogField(
                      controller: _emailController,
                      label: 'Correo',
                      hint: 'owner@quantumgym.com',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDialogField(
                            controller: _phoneController,
                            label: 'Teléfono',
                            hint: '+52 55 1234 5678',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDialogField(
                            controller: _passwordController,
                            label: 'Contraseña temporal',
                            hint: 'Mínimo 8 caracteres',
                            obscureText: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gimnasio asignado',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedGymId,
                        isExpanded: true,
                        dropdownColor: QuantumColors.surface(),
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white),
                        items: gyms
                            .map(
                              (gym) => DropdownMenuItem<String>(
                                value: gym.id,
                                child: Text(gym.data()['name']?.toString() ?? gym.id),
                              ),
                            )
                            .toList(),
                        onChanged: _isCreating
                            ? null
                            : (value) {
                                setDialogState(() => _selectedGymId = value);
                              },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isCreating ? null : () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isCreating ? null : () => _createOwner(dialogContext, gyms),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: QuantumColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: _isCreating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Crear dueño'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: QuantumColors.error, content: Text(message)),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.green, content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gymsStream = _firestore
        .collection('gyms')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots();
    final ownersStream = _firestore
        .collection('users')
        .where('role', isEqualTo: 'owner')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuantumColors.backgroundStart.withValues(alpha: 0.5),
            QuantumColors.cosmicBlack,
          ],
        ),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: gymsStream,
        builder: (context, gymsSnapshot) {
          if (gymsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gymsSnapshot.hasError) {
            return const Center(
              child: Text(
                'No se pudieron cargar los gimnasios.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final gyms = gymsSnapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final gymNames = {
            for (final gym in gyms)
              gym.id: gym.data()['name']?.toString() ?? gym.id,
          };

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ownersStream,
            builder: (context, ownersSnapshot) {
              if (ownersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (ownersSnapshot.hasError) {
                return const Center(
                  child: Text(
                    'No se pudieron cargar los dueños.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final owners = ownersSnapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final activeOwners = owners.where((owner) => (owner.data()['isActive'] as bool?) ?? true).length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GESTIÓN DE DUEÑOS',
                              style: QuantumTypography.h1.copyWith(
                                fontSize: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Solo el admin puede provisionar cuentas owner reales.',
                              style: QuantumTypography.bodyMedium.copyWith(color: Colors.white54),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: gyms.isEmpty ? null : () => _openCreateOwnerDialog(gyms),
                          icon: const Icon(Icons.person_add_rounded),
                          label: const Text('Crear dueño'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: QuantumColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildStatCard('Total', owners.length.toString(), QuantumColors.primary),
                        const SizedBox(width: 12),
                        _buildStatCard('Activos', activeOwners.toString(), Colors.green),
                        const SizedBox(width: 12),
                        _buildStatCard('Gyms activos', gyms.length.toString(), Colors.blueAccent),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (gyms.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: QuantumColors.surface(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Primero debes crear un gimnasio activo antes de crear un dueño.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (owners.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: QuantumColors.surface(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Aún no hay dueños registrados.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: QuantumColors.surface(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: owners.map((ownerDoc) {
                            final data = ownerDoc.data();
                            final isActive = (data['isActive'] as bool?) ?? true;
                            final gymId = data['gymId']?.toString();
                            final gymName = gymId == null ? 'Sin gym' : (gymNames[gymId] ?? gymId);
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _fullName(data),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data['email']?.toString() ?? 'Sin correo',
                                          style: const TextStyle(color: Colors.white54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      gymName,
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _formatDate(data['createdAt']?.toString()),
                                      style: const TextStyle(color: Colors.white54),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isActive ? Colors.green : Colors.redAccent)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isActive ? 'Activo' : 'Inactivo',
                                      style: TextStyle(
                                        color: isActive ? Colors.greenAccent : Colors.redAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}
