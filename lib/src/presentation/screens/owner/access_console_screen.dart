import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/auth/auth_state_notifier.dart';

class AccessConsoleScreen extends StatelessWidget {
  const AccessConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child:
              gymId == null
                  ? const _EmptyState(
                    message: 'No se pudo resolver el gimnasio actual',
                  )
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('check_ins')
                            .where('gymId', isEqualTo: gymId)
                            .orderBy('checkInTime', descending: true)
                            .limit(50)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const _EmptyState(
                          message: 'No se pudieron cargar los registros de acceso',
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const _EmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: docs.length,
                        itemBuilder:
                            (context, index) =>
                                _AccessLogTile(data: docs[index].data()),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Color(0xFF6366F1), size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Torre de Control de Accesos',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Monitoreando entradas activas (QR y Biometría)',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          _buildStatusBadge('SISTEMA ONLINE', Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AccessLogTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AccessLogTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final rawMethod =
        data['method']?.toString() ?? data['notes']?.toString() ?? 'registro';
    final method = rawMethod.toUpperCase();
    final timestamp = _parseDateTime(data['checkInTime'] ?? data['timestamp']);
    final timeStr = DateFormat('HH:mm:ss').format(timestamp);
    final checkOutTime = _parseNullableDateTime(data['checkOutTime']);
    final isActive = checkOutTime == null;
    final clientId =
        data['clientId']?.toString() ?? data['userId']?.toString() ?? '—';
    final gymId = data['gymId']?.toString() ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F3D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          // Icono según método
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (method == 'BIOMETRIC' ? Colors.orange : Colors.blue).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              method == 'BIOMETRIC' ? Icons.fingerprint : Icons.qr_code_scanner,
              color: method == 'BIOMETRIC' ? Colors.orange : Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          
          // Información de Usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente: $clientId',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Método: $method | Gimnasio: $gymId',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
              ],
            ),
          ),

          // Timestamp y Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeStr, style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                isActive ? 'ACTIVO' : 'CERRADO',
                style: TextStyle(
                  color: isActive ? Colors.green : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({this.message = 'No hay registros de acceso hoy'});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, color: Colors.white.withValues(alpha: 0.1), size: 100),
          const SizedBox(height: 24),
          Text(message, style: const TextStyle(color: Colors.white38, fontSize: 18)),
        ],
      ),
    );
  }
}
