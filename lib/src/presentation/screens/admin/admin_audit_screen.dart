import 'package:flutter/material.dart';
import '../../theme/quantum_colors.dart';
import '../../utils/csv_exporter.dart';

/// Auditoría & Logs - Super Admin
class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  String _filterType = 'Todos';

  // Sin fuente de datos real todavía: no existe un pipeline de audit log
  // conectado a las acciones de la plataforma. Lista vacía a propósito en
  // vez de eventos inventados (nombres/IPs/horarios falsos que antes se
  // mostraban acá como si fueran reales).
  final List<Map<String, dynamic>> _logs = [];

  List<Map<String, dynamic>> get _filteredLogs {
    if (_filterType == 'Todos') return _logs;
    final typeMap = {'Seguridad': 'security', 'Auth': 'auth', 'Finanzas': 'finance', 'Miembros': 'member'};
    return _logs.where((l) => l['type'] == typeMap[_filterType]).toList();
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
            _buildNotImplementedNotice(),
            const SizedBox(height: 32),
            _buildLogsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final filters = ['Todos', 'Seguridad', 'Auth', 'Finanzas', 'Miembros'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AUDITORÍA & LOGS', style: QuantumTypography.h1.copyWith(fontSize: 32, letterSpacing: -1, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Registro de acciones en la plataforma (pendiente de conectar a datos reales)', style: TextStyle(color: Colors.white38)),
          ],
        ),
        Row(
          children: filters.map((f) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: _filterType == f,
              onSelected: (_) => setState(() => _filterType = f),
              selectedColor: const Color(0xFFFF6B35).withValues(alpha: 0.2),
              backgroundColor: QuantumColors.surface(),
              labelStyle: TextStyle(color: _filterType == f ? const Color(0xFFFF6B35) : Colors.white38, fontSize: 12),
              side: BorderSide(color: _filterType == f ? const Color(0xFFFF6B35).withValues(alpha: 0.3) : Colors.white10),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildNotImplementedNotice() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.info_outline_rounded, color: Colors.white38, size: 24),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registro de auditoría aún no conectado', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Esta plataforma todavía no escribe un log real de acciones (login, altas/bajas, cambios de plan, etc.). Esta pantalla queda a la espera de esa fuente de datos.', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTable() {
    final logs = _filteredLogs;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Registro de Actividad (${logs.length} eventos)', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
              ElevatedButton.icon(
                onPressed: () async {
                  final success = await CsvExporter.export(
                    headers: ['Acción', 'Usuario', 'Rol', 'Gimnasio', 'IP', 'Fecha/Hora', 'Tipo'],
                    rows: logs.map((l) => [
                      l['action'], l['user'], l['role'], l['gym'], l['ip'], l['time'], l['type'],
                    ]).toList(),
                    filename: 'audit_logs_${DateTime.now().toIso8601String().split('T').first}',
                  );
                  if (mounted) {
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
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  SizedBox(width: 32),
                  Expanded(flex: 3, child: Text('Acción', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Usuario', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Rol', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Gimnasio', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('IP', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Fecha/Hora', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            ...logs.map((log) => _buildLogRow(log)),
          ],
        ],
      ),
    );
  }

  Widget _buildLogRow(Map<String, dynamic> log) {
    final typeColor = {
      'auth': const Color(0xFF6366F1),
      'security': Colors.redAccent,
      'finance': const Color(0xFFF59E0B),
      'member': const Color(0xFF10B981),
      'routine': const Color(0xFF00E0FF),
      'settings': Colors.white38,
    };
    final typeIcon = {
      'auth': Icons.login_rounded,
      'security': Icons.shield_rounded,
      'finance': Icons.account_balance_wallet_rounded,
      'member': Icons.person_rounded,
      'routine': Icons.fitness_center_rounded,
      'settings': Icons.settings_rounded,
    };

    final color = typeColor[log['type']] ?? Colors.white38;
    final icon = typeIcon[log['type']] ?? Icons.info_rounded;

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
          Expanded(flex: 3, child: Text(log['action'], style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(log['user'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(log['role'], style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          ),
          Expanded(child: Text(log['gym'], style: const TextStyle(color: Colors.white38, fontSize: 12))),
          Expanded(child: Text(log['ip'], style: const TextStyle(color: Colors.white24, fontSize: 11, fontFamily: 'monospace'))),
          Expanded(child: Text(log['time'], style: const TextStyle(color: Colors.white30, fontSize: 11))),
        ],
      ),
    );
  }
}
