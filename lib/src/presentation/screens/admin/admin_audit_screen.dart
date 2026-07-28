import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../theme/quantum_colors.dart';
import '../../utils/csv_exporter.dart';

/// Auditoría & Logs - Super Admin
///
/// Lee la colección real `audit_logs` (ya escrita desde StaffService,
/// FirebaseOwnerMemberRepository, cierre de caja, configuración global,
/// etc. — ver firestore.rules:673 para el permiso de lectura admin-wide).
/// Antes esta pantalla mostraba 10 eventos 100% inventados; el pipeline
/// real ya existía, solo no estaba conectado a la vista de super admin.
class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  final FirebaseFirestore _firestore = GetIt.I<FirebaseFirestore>();
  String _filterModule = 'Todos';
  Map<String, String> _gymNames = {};

  @override
  void initState() {
    super.initState();
    _loadGymNames();
  }

  Future<void> _loadGymNames() async {
    final snapshot = await _firestore.collection('gyms').get();
    if (!mounted) return;
    setState(() {
      _gymNames = {
        for (final doc in snapshot.docs)
          doc.id: doc.data()['name']?.toString() ?? doc.id,
      };
    });
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyModuleFilter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (_filterModule == 'Todos') return docs;
    return docs.where((doc) => doc.data()['module'] == _filterModule).toList();
  }

  String _formatTimestamp(dynamic value) {
    if (value is! Timestamp) return 'Sin fecha';
    final date = value.toDate();
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  @override
  Widget build(BuildContext context) {
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
            _buildLogsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const modules = ['Todos', 'SEGURIDAD', 'FINANZAS', 'MEMBRESÍA', 'REGISTRO', 'ROLES', 'RUTINAS', 'CONFIGURACIÓN'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AUDITORÍA & LOGS', style: QuantumTypography.h1.copyWith(fontSize: 32, letterSpacing: -1, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Registro de acciones en la plataforma', style: TextStyle(color: Colors.white38)),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: modules.map((m) => ChoiceChip(
            label: Text(m),
            selected: _filterModule == m,
            onSelected: (_) => setState(() => _filterModule = m),
            selectedColor: const Color(0xFFFF6B35).withValues(alpha: 0.2),
            backgroundColor: QuantumColors.surface(),
            labelStyle: TextStyle(color: _filterModule == m ? const Color(0xFFFF6B35) : Colors.white38, fontSize: 12),
            side: BorderSide(color: _filterModule == m ? const Color(0xFFFF6B35).withValues(alpha: 0.3) : Colors.white10),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildLogsTable() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('audit_logs')
            .orderBy('timestamp', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No se pudo cargar la auditoría.', style: TextStyle(color: Colors.white70)),
            );
          }

          final logs = _applyModuleFilter(snapshot.data?.docs ?? const []);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Registro de Actividad (${logs.length} eventos)', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final success = await CsvExporter.export(
                        headers: ['Acción', 'Quién', 'Módulo', 'Gimnasio', 'Fecha/Hora'],
                        rows: logs.map((doc) {
                          final data = doc.data();
                          final gymId = data['gymId']?.toString();
                          return [
                            data['action']?.toString() ?? '',
                            data['who']?.toString() ?? '',
                            data['module']?.toString() ?? '',
                            gymId == null ? 'Global' : (_gymNames[gymId] ?? gymId),
                            _formatTimestamp(data['timestamp']),
                          ];
                        }).toList(),
                        filename: 'audit_logs_${DateTime.now().toIso8601String().split('T').first}',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Logs exportados correctamente' : 'No se pudo exportar'),
                            backgroundColor: success ? Colors.green : Colors.redAccent,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text('Exportar CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      foregroundColor: Colors.white60,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (logs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No hay eventos para mostrar.',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    children: [
                      SizedBox(width: 32),
                      Expanded(flex: 3, child: Text('Acción', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Quién', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Módulo', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Gimnasio', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Fecha/Hora', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                ...logs.map((doc) => _buildLogRow(doc.data())),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogRow(Map<String, dynamic> data) {
    const moduleColor = {
      'SEGURIDAD': Colors.redAccent,
      'FINANZAS': Color(0xFFF59E0B),
      'MEMBRESÍA': Color(0xFF10B981),
      'REGISTRO': Color(0xFF6366F1),
      'ROLES': Color(0xFF6366F1),
      'RUTINAS': Color(0xFF00E0FF),
      'CONFIGURACIÓN': Colors.white38,
    };
    const moduleIcon = {
      'SEGURIDAD': Icons.shield_rounded,
      'FINANZAS': Icons.account_balance_wallet_rounded,
      'MEMBRESÍA': Icons.person_rounded,
      'REGISTRO': Icons.person_add_rounded,
      'ROLES': Icons.badge_rounded,
      'RUTINAS': Icons.fitness_center_rounded,
      'CONFIGURACIÓN': Icons.settings_rounded,
    };

    final module = data['module']?.toString() ?? '';
    final color = moduleColor[module] ?? Colors.white38;
    final icon = moduleIcon[module] ?? Icons.info_rounded;
    final gymId = data['gymId']?.toString();
    final gymLabel = gymId == null ? 'Global' : (_gymNames[gymId] ?? gymId);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03)))),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 4),
          Expanded(flex: 3, child: Text(data['action']?.toString() ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(data['who']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(module, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(child: Text(gymLabel, style: const TextStyle(color: Colors.white38, fontSize: 12), overflow: TextOverflow.ellipsis)),
          Expanded(child: Text(_formatTimestamp(data['timestamp']), style: const TextStyle(color: Colors.white30, fontSize: 11))),
        ],
      ),
    );
  }
}
