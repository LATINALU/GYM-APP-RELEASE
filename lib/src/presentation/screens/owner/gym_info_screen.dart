import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/quantum_colors.dart';

/// Información del Gimnasio - Owner
/// El dueño puede editar foto, nombre, dirección, teléfono, horarios, etc.
class GymInfoScreen extends StatefulWidget {
  const GymInfoScreen({super.key});

  @override
  State<GymInfoScreen> createState() => _GymInfoScreenState();
}

class _GymInfoScreenState extends State<GymInfoScreen> {
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descController = TextEditingController();
  final _websiteController = TextEditingController();

  String _selectedOpenTime = '06:00';
  String _selectedCloseTime = '22:00';
  bool _openSunday = false;
  String? _logoUrl;
  String? _coverUrl;
  String _gymCode = '—';
  bool _isLoadingGym = true;
  String? _loadError;
  String _activeMembersLabel = '—';
  String _staffLabel = '—';
  String _activePlansLabel = '—';
  String _todayCheckinsLabel = '—';
  String _ratingLabel = '—';
  String _instagramHandle = '';
  String _facebookHandle = '';
  String _tiktokHandle = '';

  final List<String> _amenities = [];
  final List<String> _allAmenities = [
    'Estacionamiento', 'Regaderas', 'Lockers', 'Wifi', 'Tienda',
    'Sauna', 'Alberca', 'Cafetería', 'Área de Cardio', 'Zona de Peso Libre',
    'Clases Grupales', 'Entrenador Personal', 'Nutriólogo', 'Fisioterapeuta',
  ];

  @override
  void initState() {
    super.initState();
    _loadGymInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadGymInfo() async {
    setState(() {
      _isLoadingGym = true;
      _loadError = null;
    });

    try {
      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      if (gymId == null) {
        throw Exception('No se pudo resolver el gimnasio actual');
      }

      final firestore = FirebaseFirestore.instance;
      final gymDoc = await firestore.collection('gyms').doc(gymId).get();
      final plansSnapshot = await firestore
          .collection('membership_plans')
          .where('gymId', isEqualTo: gymId)
          .where('isActive', isEqualTo: true)
          .get();
      final membersSnapshot = await firestore
          .collection('users')
          .where('gymId', isEqualTo: gymId)
          .where('role.type', isEqualTo: 'client')
          .get();
      final staffSnapshot = await firestore
          .collection('users')
          .where('gymId', isEqualTo: gymId)
          .where('role.type', whereIn: ['owner', 'staff'])
          .get();

      final startOfDay = DateTime.now();
      final todayStart = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);
      final checkinsSnapshot = await firestore
          .collection('check_ins')
          .where('gymId', isEqualTo: gymId)
          .where('checkInTime', isGreaterThanOrEqualTo: todayStart.toIso8601String())
          .get();

      final data = gymDoc.data() ?? <String, dynamic>{};
      final schedule = Map<String, dynamic>.from(data['schedule'] as Map? ?? {});
      final socials = Map<String, dynamic>.from(data['socialLinks'] as Map? ?? {});
      final amenities = (data['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];

      if (!mounted) return;

      setState(() {
        _nameController.text = data['name']?.toString() ?? '';
        _addressController.text = data['address']?.toString() ?? '';
        _phoneController.text = data['phone']?.toString() ?? '';
        _emailController.text = data['email']?.toString() ?? '';
        _descController.text = data['description']?.toString() ?? '';
        _websiteController.text = data['website']?.toString() ?? '';
        _selectedOpenTime = schedule['openTime']?.toString() ?? '06:00';
        _selectedCloseTime = schedule['closeTime']?.toString() ?? '22:00';
        _openSunday = schedule['openSunday'] as bool? ?? false;
        _logoUrl = data['logoUrl']?.toString();
        _coverUrl = data['coverUrl']?.toString();
        _gymCode = data['code']?.toString() ?? '—';
        _amenities
          ..clear()
          ..addAll(amenities);
        _activeMembersLabel = '${membersSnapshot.docs.length}';
        _staffLabel = '${staffSnapshot.docs.length}';
        _activePlansLabel = '${plansSnapshot.docs.length}';
        _todayCheckinsLabel = '${checkinsSnapshot.docs.length}';
        _ratingLabel = data['rating'] != null ? '${data['rating']} ★' : '—';
        _instagramHandle = socials['instagram']?.toString() ?? '';
        _facebookHandle = socials['facebook']?.toString() ?? '';
        _tiktokHandle = socials['tiktok']?.toString() ?? '';
        _isLoadingGym = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'No se pudo cargar la información del gimnasio.';
        _isLoadingGym = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingGym) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadGymInfo,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QuantumColors.backgroundStart.withValues(alpha: 0.5), QuantumColors.cosmicBlack],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildMainInfo()),
                const SizedBox(width: 32),
                Expanded(child: _buildSideInfo()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MI GIMNASIO', style: QuantumTypography.h1.copyWith(fontSize: 32, letterSpacing: -1, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Información pública de tu gimnasio', style: TextStyle(color: Colors.white38)),
          ],
        ),
        Row(
          children: [
            if (_isEditing) ...[
              OutlinedButton(
                onPressed: () => setState(() => _isEditing = false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white60,
                  side: const BorderSide(color: Colors.white10),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _saveGymInfo,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Editar Información'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuantumColors.matrixCyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover Photo
        _buildCoverPhoto(),
        const SizedBox(height: 32),
        // Basic Info Card
        _buildInfoCard('Información Básica', [
          _buildEditableField('Nombre del Gimnasio', _nameController, Icons.fitness_center_rounded),
          _buildEditableField('Descripción', _descController, Icons.description_rounded, maxLines: 3),
          _buildEditableField('Dirección', _addressController, Icons.location_on_rounded),
          _buildEditableField('Teléfono', _phoneController, Icons.phone_rounded),
          _buildEditableField('Email', _emailController, Icons.email_rounded),
          _buildEditableField('Sitio Web', _websiteController, Icons.language_rounded),
        ]),
        const SizedBox(height: 24),
        // Schedule
        _buildScheduleCard(),
        const SizedBox(height: 24),
        // Amenities
        _buildAmenitiesCard(),
      ],
    );
  }

  Widget _buildCoverPhoto() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        image: _coverUrl != null
            ? DecorationImage(image: NetworkImage(_coverUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: Stack(
        children: [
          if (_coverUrl == null)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.panorama_rounded, color: Colors.white12, size: 48),
                  SizedBox(height: 8),
                  Text('Foto de portada del gimnasio', style: TextStyle(color: Colors.white24)),
                ],
              ),
            ),
          // Logo overlay
          Positioned(
            bottom: 16,
            left: 24,
            child: Row(
              children: [
                InkWell(
                  onTap: _isEditing ? _uploadLogo : null,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: QuantumColors.surface(),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: QuantumColors.matrixCyan.withValues(alpha: 0.3), width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)],
                    ),
                    child: _logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(_logoUrl!, fit: BoxFit.cover),
                          )
                        : Icon(Icons.add_a_photo_rounded, color: QuantumColors.matrixCyan.withValues(alpha: 0.5), size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_nameController.text, style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18, shadows: [const Shadow(color: Colors.black, blurRadius: 10)])),
                    Text(_addressController.text.length > 40 ? '${_addressController.text.substring(0, 40)}...' : _addressController.text, style: const TextStyle(color: Colors.white70, fontSize: 12, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
                  ],
                ),
              ],
            ),
          ),
          if (_isEditing)
            Positioned(
              top: 12,
              right: 12,
              child: ElevatedButton.icon(
                onPressed: _uploadCover,
                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                label: const Text('Cambiar Portada', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: QuantumColors.matrixCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: QuantumColors.matrixCyan, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _isEditing
                ? TextField(
                    controller: controller,
                    maxLines: maxLines,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: QuantumColors.matrixCyan)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(controller.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Horarios', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTimeSelector('Apertura', _selectedOpenTime, (v) => setState(() => _selectedOpenTime = v))),
              const SizedBox(width: 16),
              Expanded(child: _buildTimeSelector('Cierre', _selectedCloseTime, (v) => setState(() => _selectedCloseTime = v))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Lunes a Sábado: $_selectedOpenTime - $_selectedCloseTime', style: const TextStyle(color: Colors.white60, fontSize: 13)),
              const Spacer(),
              Row(
                children: [
                  const Text('Abierto Domingos', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  const SizedBox(width: 8),
                  Switch(
                    value: _openSunday,
                    onChanged: _isEditing ? (v) => setState(() => _openSunday = v) : null,
                    activeThumbColor: QuantumColors.matrixCyan,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(String label, String value, ValueChanged<String> onChanged) {
    final times = List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: QuantumColors.surface(),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: times.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: _isEditing ? (v) { if (v != null) onChanged(v); } : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amenidades', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allAmenities.map((a) {
              final isSelected = _amenities.contains(a);
              return FilterChip(
                label: Text(a),
                selected: isSelected,
                onSelected: _isEditing ? (selected) {
                  setState(() {
                    if (selected) { _amenities.add(a); } else { _amenities.remove(a); }
                  });
                } : null,
                selectedColor: QuantumColors.matrixCyan.withValues(alpha: 0.2),
                backgroundColor: QuantumColors.surface(),
                labelStyle: TextStyle(color: isSelected ? QuantumColors.matrixCyan : Colors.white38, fontSize: 12),
                side: BorderSide(color: isSelected ? QuantumColors.matrixCyan.withValues(alpha: 0.3) : Colors.white10),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSideInfo() {
    return Column(
      children: [
        // Quick Stats
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: QuantumColors.surface(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estadísticas', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 20),
              _buildStatRow('Miembros Activos', _activeMembersLabel, const Color(0xFF10B981)),
              _buildStatRow('Staff', _staffLabel, const Color(0xFF6366F1)),
              _buildStatRow('Planes Activos', _activePlansLabel, const Color(0xFFF59E0B)),
              _buildStatRow('Check-ins Hoy', _todayCheckinsLabel, QuantumColors.matrixCyan),
              _buildStatRow('Calificación', _ratingLabel, const Color(0xFFFF6B35)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Gym Code
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: QuantumColors.surface(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: QuantumColors.matrixCyan.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              const Icon(Icons.qr_code_2_rounded, color: QuantumColors.matrixCyan, size: 48),
              const SizedBox(height: 12),
              const Text('Código del Gym', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 4),
              Text(_gymCode, style: QuantumTypography.h2.copyWith(color: QuantumColors.matrixCyan, fontSize: 24, letterSpacing: 2)),
              const SizedBox(height: 8),
              const Text('Los clientes usan este código para unirse', style: TextStyle(color: Colors.white24, fontSize: 11), textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Social Links
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: QuantumColors.surface(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Redes Sociales', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 16),
              _buildSocialLink(Icons.camera_alt_rounded, 'Instagram', _instagramHandle),
              _buildSocialLink(Icons.facebook_rounded, 'Facebook', _facebookHandle),
              _buildSocialLink(Icons.play_circle_rounded, 'TikTok', _tiktokHandle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLink(IconData icon, String platform, String handle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(platform, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              Text(handle, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  void _uploadLogo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La carga de logo aún no está disponible en esta pantalla'),
        backgroundColor: Color(0xFFFF6B35),
      ),
    );
  }

  void _uploadCover() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La carga de portada aún no está disponible en esta pantalla'),
        backgroundColor: Color(0xFFFF6B35),
      ),
    );
  }

  Future<void> _saveGymInfo() async {
    try {
      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      if (gymId == null) {
        throw Exception('No se pudo resolver el gimnasio actual');
      }

      await FirebaseFirestore.instance.collection('gyms').doc(gymId).set({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'description': _descController.text.trim(),
        'website': _websiteController.text.trim(),
        'logoUrl': _logoUrl,
        'coverUrl': _coverUrl,
        'amenities': List<String>.from(_amenities),
        'socialLinks': {
          'instagram': _instagramHandle,
          'facebook': _facebookHandle,
          'tiktok': _tiktokHandle,
        },
        'schedule': {
          'openTime': _selectedOpenTime,
          'closeTime': _selectedCloseTime,
          'openSunday': _openSunday,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Información del gimnasio actualizada'), backgroundColor: Color(0xFF10B981)),
      );
      await _loadGymInfo();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la información: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }
}
