import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../application/services/admin_metrics_service.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/gym_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../theme/theme.dart';

const _platformPlanStatuses = ['active', 'trial', 'suspended', 'cancelled'];

String _planStatusLabel(String status) => switch (status) {
      'active' => 'Activo',
      'trial' => 'Prueba',
      'suspended' => 'Suspendido',
      'cancelled' => 'Cancelado',
      _ => status,
    };

class AdminGymsLiveScreen extends StatefulWidget {
  const AdminGymsLiveScreen({super.key});

  @override
  State<AdminGymsLiveScreen> createState() => _AdminGymsLiveScreenState();
}

class _AdminGymsLiveScreenState extends State<AdminGymsLiveScreen> {
  final FirebaseFirestore _firestore = GetIt.I<FirebaseFirestore>();
  final GymRepositoryPort _gymRepository = GetIt.I<GymRepositoryPort>();
  final AdminMetricsService _metricsService = GetIt.I<AdminMetricsService>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _gymNameController = TextEditingController();
  final TextEditingController _gymAddressController = TextEditingController();
  final TextEditingController _gymPhoneController = TextEditingController();

  String _filter = 'Todos';
  bool _isCreating = false;
  bool _isUpdatingStatus = false;
  bool _isAssigningPlan = false;
  List<PlatformPlan> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    await _metricsService.ensureDefaultPlans();
    final plans = await _metricsService.getPlans(onlyActive: true);
    if (mounted) setState(() => _plans = plans);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gymNameController.dispose();
    _gymAddressController.dispose();
    _gymPhoneController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterGyms(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    return docs.where((doc) {
      final data = doc.data();
      final isActive = (data['isActive'] as bool?) ?? true;
      final statusMatches = switch (_filter) {
        'Activos' => isActive,
        'Suspendidos' => !isActive,
        _ => true,
      };

      if (!statusMatches) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final name = data['name']?.toString().toLowerCase() ?? '';
      final code = data['code']?.toString().toLowerCase() ?? '';
      final address = data['address']?.toString().toLowerCase() ?? '';
      return name.contains(query) || code.contains(query) || address.contains(query);
    }).toList();
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

  Future<void> _toggleGymStatus({
    required String gymId,
    required bool isActive,
  }) async {
    if (_isUpdatingStatus) return;

    setState(() => _isUpdatingStatus = true);
    try {
      if (isActive) {
        final result = await _gymRepository.deactivate(GymId(gymId));
        result.fold(
          (failure) => _showError(failure.message),
          (_) => _showSuccess('Gimnasio suspendido correctamente'),
        );
      } else {
        await _firestore.collection('gyms').doc(gymId).update({'isActive': true});
        _showSuccess('Gimnasio activado correctamente');
      }
    } catch (e) {
      _showError('No se pudo actualizar el gimnasio: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<void> _createGym(BuildContext dialogContext) async {
    final name = _gymNameController.text.trim();
    final address = _gymAddressController.text.trim();
    final phoneText = _gymPhoneController.text.trim();

    if (name.isEmpty) {
      _showError('El nombre del gimnasio es obligatorio');
      return;
    }

    final phone = phoneText.isEmpty ? null : PhoneNumber.tryParse(phoneText);
    if (phoneText.isNotEmpty && phone == null) {
      _showError('El teléfono del gimnasio no es válido');
      return;
    }

    setState(() => _isCreating = true);
    try {
      final gym = Gym.create(
        name: name,
        address: address.isEmpty ? null : address,
        phone: phone,
      );

      final result = await _gymRepository.save(gym);
      result.fold(
        (failure) => _showError(failure.message),
        (_) {
          Navigator.of(dialogContext).pop();
          _showSuccess('Gimnasio creado. Código: ${gym.code.value}');
        },
      );
    } catch (e) {
      _showError('No se pudo crear el gimnasio: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _openCreateGymDialog() {
    _gymNameController.clear();
    _gymAddressController.clear();
    _gymPhoneController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: QuantumColors.surface(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear gimnasio',
                  style: QuantumTypography.h2.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDialogField(
                  controller: _gymNameController,
                  label: 'Nombre del gimnasio',
                  hint: 'Ej: QUANTUM CENTER',
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  controller: _gymAddressController,
                  label: 'Dirección',
                  hint: 'Dirección principal',
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  controller: _gymPhoneController,
                  label: 'Teléfono',
                  hint: '+52 55 1234 5678',
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
                      onPressed: _isCreating ? null : () => _createGym(dialogContext),
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
                          : const Text('Guardar gimnasio'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
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

  Future<void> _assignPlan({
    required String gymId,
    required String planId,
    required String status,
  }) async {
    setState(() => _isAssigningPlan = true);
    try {
      await _firestore.collection('gyms').doc(gymId).update({
        'platformPlanId': planId,
        'platformPlanStatus': status,
      });
      _showSuccess('Plan de plataforma actualizado');
    } catch (e) {
      _showError('No se pudo asignar el plan: $e');
    } finally {
      if (mounted) setState(() => _isAssigningPlan = false);
    }
  }

  void _openAssignPlanDialog({
    required String gymId,
    required String gymName,
    required String? currentPlanId,
    required String? currentStatus,
  }) {
    if (_plans.isEmpty) {
      _showError('No hay planes de plataforma cargados todavía');
      return;
    }
    String selectedPlanId =
        _plans.any((p) => p.id == currentPlanId) ? currentPlanId! : _plans.first.id;
    String selectedStatus =
        _platformPlanStatuses.contains(currentStatus) ? currentStatus! : 'trial';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: QuantumColors.surface(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Plan de plataforma — $gymName', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Plan', style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedPlanId,
                isExpanded: true,
                dropdownColor: QuantumColors.surface(),
                style: const TextStyle(color: Colors.white),
                items: _plans
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} (\$${p.price.toStringAsFixed(0)})'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedPlanId = v);
                },
              ),
              const SizedBox(height: 16),
              const Text('Estado', style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                dropdownColor: QuantumColors.surface(),
                style: const TextStyle(color: Colors.white),
                items: _platformPlanStatuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(_planStatusLabel(s))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedStatus = v);
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Solo el plan con estado "Activo" cuenta en el MRR del panel de facturación.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: _isAssigningPlan
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _assignPlan(gymId: gymId, planId: selectedPlanId, status: selectedStatus);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: QuantumColors.primary),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
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
        stream: _firestore.collection('gyms').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No se pudieron cargar los gimnasios',
                style: QuantumTypography.bodyLarge.copyWith(color: Colors.white),
              ),
            );
          }

          final gyms = _filterGyms(snapshot.data?.docs ?? const []);

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
                          'GESTIÓN DE GIMNASIOS',
                          style: QuantumTypography.h1.copyWith(
                            fontSize: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Solo el admin puede crear y administrar gimnasios.',
                          style: QuantumTypography.bodyMedium.copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _openCreateGymDialog,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nuevo gimnasio'),
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
                    ...['Todos', 'Activos', 'Suspendidos'].map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(item),
                          selected: _filter == item,
                          onSelected: (_) => setState(() => _filter = item),
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, código o dirección',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.search, color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (gyms.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: QuantumColors.surface(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'No hay gimnasios para mostrar.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: gyms.map((doc) {
                      final data = doc.data();
                      final isActive = (data['isActive'] as bool?) ?? true;
                      return SizedBox(
                        width: 320,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: QuantumColors.surface(),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['name']?.toString() ?? 'Sin nombre',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                      isActive ? 'Activo' : 'Suspendido',
                                      style: TextStyle(
                                        color: isActive ? Colors.greenAccent : Colors.redAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Código: ${data['code'] ?? 'N/D'}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['address']?.toString().trim().isNotEmpty == true
                                    ? data['address'].toString()
                                    : 'Sin dirección registrada',
                                style: const TextStyle(color: Colors.white54),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Creado: ${_formatDate(data['createdAt']?.toString())}',
                                style: const TextStyle(color: Colors.white38),
                              ),
                              const SizedBox(height: 8),
                              Builder(builder: (context) {
                                final planId = data['platformPlanId']?.toString();
                                final planStatus = data['platformPlanStatus']?.toString();
                                final plan = _plans.where((p) => p.id == planId).firstOrNull;
                                final label = plan != null
                                    ? '${plan.name} · ${_planStatusLabel(planStatus ?? 'trial')}'
                                    : 'Sin plan de plataforma asignado';
                                return Text(
                                  label,
                                  style: TextStyle(
                                    color: plan != null ? Colors.white70 : Colors.orangeAccent,
                                    fontSize: 12,
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => _openAssignPlanDialog(
                                    gymId: doc.id,
                                    gymName: data['name']?.toString() ?? 'Sin nombre',
                                    currentPlanId: data['platformPlanId']?.toString(),
                                    currentStatus: data['platformPlanStatus']?.toString(),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white24),
                                  ),
                                  child: const Text('Asignar plan de plataforma'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isUpdatingStatus
                                      ? null
                                      : () => _toggleGymStatus(
                                            gymId: doc.id,
                                            isActive: isActive,
                                          ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color: isActive ? Colors.redAccent : Colors.green,
                                    ),
                                  ),
                                  child: Text(isActive ? 'Suspender gimnasio' : 'Activar gimnasio'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
