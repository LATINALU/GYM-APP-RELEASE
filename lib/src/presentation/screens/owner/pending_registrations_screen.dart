import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../domain/entities/pending_registration.dart';
import '../../../infrastructure/config/di.dart';
import '../../../domain/ports/output/pending_registration_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../../application/use_cases/review_registration_usecase.dart';

/// Screen for gym owners to manage pending registration requests
/// This is the "pre-approval queue" where users wait to be accepted into a gym
class PendingRegistrationsScreen extends StatefulWidget {
  final String gymId;
  final String currentUserId;

  const PendingRegistrationsScreen({
    super.key,
    required this.gymId,
    required this.currentUserId,
  });

  @override
  State<PendingRegistrationsScreen> createState() =>
      _PendingRegistrationsScreenState();
}

class _PendingRegistrationsScreenState
    extends State<PendingRegistrationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PendingRegistrationRepositoryPort _registrationRepo;
  late ReviewRegistrationUseCase _reviewUseCase;

  List<PendingRegistration> _pendingList = [];
  List<PendingRegistration> _processedList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _registrationRepo = getIt<PendingRegistrationRepositoryPort>();
    _reviewUseCase = getIt<ReviewRegistrationUseCase>();
    _loadRegistrations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRegistrations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final gymId = GymId(widget.gymId);
      final result = await _registrationRepo.findByGymId(gymId);

      result.fold(
        (failure) => setState(() => _error = failure.message),
        (registrations) {
          setState(() {
            _pendingList = registrations
                .where((r) => r.status == RegistrationStatus.pendingReview)
                .toList();
            _processedList = registrations
                .where((r) => r.status != RegistrationStatus.pendingReview)
                .toList();
          });
        },
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRegistration(PendingRegistration registration) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmationDialog(
        title: '¿Aprobar solicitud?',
        message:
            '${registration.userName} será agregado como miembro de tu gimnasio.',
        confirmText: 'Aprobar',
        confirmColor: const Color(0xFF10B981),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final result = await _reviewUseCase.approve(
      registrationId: registration.id,
      reviewedBy: UserId(widget.currentUserId),
      gymId: GymId(widget.gymId),
    );

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${failure.message}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${registration.userName} ha sido aprobado ✓'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      },
    );

    _loadRegistrations();
  }

  Future<void> _rejectRegistration(PendingRegistration registration) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _RejectionDialog(
        userName: registration.userName,
        reasonController: reasonController,
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final result = await _reviewUseCase.reject(
      registrationId: registration.id,
      rejectedBy: UserId(widget.currentUserId),
      reason: reasonController.text.isNotEmpty
          ? reasonController.text
          : null,
    );

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${failure.message}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud rechazada'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      },
    );

    reasonController.dispose();
    _loadRegistrations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A21),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solicitudes de Registro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            if (_pendingList.isNotEmpty)
              Text(
                '${_pendingList.length} pendiente${_pendingList.length != 1 ? "s" : ""}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF00E0FF),
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00E0FF)),
            onPressed: _loadRegistrations,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E0FF),
          labelColor: const Color(0xFF00E0FF),
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pending_actions, size: 18),
                  const SizedBox(width: 6),
                  const Text('Pendientes'),
                  if (_pendingList.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingList.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 18),
                  SizedBox(width: 6),
                  Text('Historial'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00E0FF),
              ),
            )
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPendingTab(),
                    _buildHistoryTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRegistrations,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E0FF),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: const Color(0xFF00FFE0).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay solicitudes pendientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Las nuevas solicitudes aparecerán aquí',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white38,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRegistrations,
      color: const Color(0xFF00E0FF),
      backgroundColor: const Color(0xFF1A1A21),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingList.length,
        itemBuilder: (context, index) {
          final reg = _pendingList[index];
          return _RegistrationCard(
            registration: reg,
            onApprove: () => _approveRegistration(reg),
            onReject: () => _rejectRegistration(reg),
          ).animate(delay: (index * 80).ms).fadeIn().slideX(
                begin: 0.05,
                end: 0,
                duration: 300.ms,
              );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_processedList.isEmpty) {
      return const Center(
        child: Text(
          'Sin historial de solicitudes',
          style: TextStyle(color: Colors.white38, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _processedList.length,
      itemBuilder: (context, index) {
        final reg = _processedList[index];
        return _HistoryCard(registration: reg);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _RegistrationCard extends StatelessWidget {
  final PendingRegistration registration;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RegistrationCard({
    required this.registration,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E0FF).withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E0FF).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E0FF), Color(0xFF00FFE0)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      registration.userName.isNotEmpty
                          ? registration.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F0F12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registration.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        registration.userEmail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Source badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSourceColor(registration.source)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getSourceIcon(registration.source),
                        size: 14,
                        color: _getSourceColor(registration.source),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        registration.source.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: _getSourceColor(registration.source),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details section
          if (registration.message != null ||
              registration.fitnessGoal != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (registration.message != null) ...[
                      const Text(
                        'Mensaje:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        registration.message!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    if (registration.fitnessGoal != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.flag, size: 14,
                              color: Color(0xFF00FFE0)),
                          const SizedBox(width: 6),
                          Text(
                            'Meta: ${registration.fitnessGoal}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF00FFE0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Footer with time and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Time info
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimeAgo(registration.timeSinceCreated),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),

                if (registration.daysRemaining != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: registration.daysRemaining! <= 5
                        ? const Color(0xFFEF4444)
                        : Colors.white38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expira en ${registration.daysRemaining} días',
                    style: TextStyle(
                      fontSize: 12,
                      color: registration.daysRemaining! <= 5
                          ? const Color(0xFFEF4444)
                          : Colors.white38,
                    ),
                  ),
                ],

                const Spacer(),

                // Reject button
                TextButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Rechazar'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                ),

                const SizedBox(width: 8),

                // Approve button
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Aprobar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSourceColor(RegistrationSource source) {
    switch (source) {
      case RegistrationSource.qrScan:
        return const Color(0xFF00E0FF);
      case RegistrationSource.manualCode:
        return const Color(0xFF8B5CF6);
      case RegistrationSource.invitation:
        return const Color(0xFF10B981);
      case RegistrationSource.appSearch:
        return const Color(0xFFF59E0B);
      case RegistrationSource.transfer:
        return const Color(0xFFEC4899);
    }
  }

  IconData _getSourceIcon(RegistrationSource source) {
    switch (source) {
      case RegistrationSource.qrScan:
        return Icons.qr_code_scanner;
      case RegistrationSource.manualCode:
        return Icons.keyboard;
      case RegistrationSource.invitation:
        return Icons.mail_outline;
      case RegistrationSource.appSearch:
        return Icons.search;
      case RegistrationSource.transfer:
        return Icons.swap_horiz;
    }
  }

  String _formatTimeAgo(Duration duration) {
    if (duration.inMinutes < 60) return 'Hace ${duration.inMinutes} min';
    if (duration.inHours < 24) return 'Hace ${duration.inHours} h';
    return 'Hace ${duration.inDays} días';
  }
}

class _HistoryCard extends StatelessWidget {
  final PendingRegistration registration;

  const _HistoryCard({required this.registration});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A21).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _getStatusIcon(),
              size: 18,
              color: _getStatusColor(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  registration.userName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  registration.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(),
                  ),
                ),
              ],
            ),
          ),
          if (registration.reviewedAt != null)
            Text(
              _formatDate(registration.reviewedAt!),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white30,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (registration.status) {
      case RegistrationStatus.approved:
        return const Color(0xFF10B981);
      case RegistrationStatus.rejected:
        return const Color(0xFFEF4444);
      case RegistrationStatus.expired:
        return const Color(0xFFF59E0B);
      case RegistrationStatus.cancelled:
        return Colors.white38;
      case RegistrationStatus.pendingReview:
        return const Color(0xFF00E0FF);
    }
  }

  IconData _getStatusIcon() {
    switch (registration.status) {
      case RegistrationStatus.approved:
        return Icons.check_circle;
      case RegistrationStatus.rejected:
        return Icons.cancel;
      case RegistrationStatus.expired:
        return Icons.schedule;
      case RegistrationStatus.cancelled:
        return Icons.block;
      case RegistrationStatus.pendingReview:
        return Icons.pending;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final Color confirmColor;

  const _ConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A21),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      content: Text(message,
          style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar',
              style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

class _RejectionDialog extends StatelessWidget {
  final String userName;
  final TextEditingController reasonController;

  const _RejectionDialog({
    required this.userName,
    required this.reasonController,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A21),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Rechazar Solicitud',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Deseas rechazar la solicitud de $userName?',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Razón de rechazo (opcional)',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar',
              style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          child: const Text('Rechazar'),
        ),
      ],
    );
  }
}
