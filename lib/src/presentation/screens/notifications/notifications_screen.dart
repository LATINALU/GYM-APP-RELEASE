import 'package:flutter/material.dart';
import '../../../application/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _svc = NotificationService();
  List<AppNotification> _notifs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _notifs = await _svc.getNotifications('current-user');
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Color(0xFF0A0A0F), body: Center(child: CircularProgressIndicator()));
    final unread = _notifs.where((n) => !n.isRead).length;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(slivers: [
        SliverAppBar(backgroundColor: const Color(0xFF0A0A0F), pinned: true,
          title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            if (unread > 0) TextButton(onPressed: () async {
              await _svc.markAllRead('current-user'); _load();
            }, child: const Text('Marcar todo leído', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 12))),
          ]),
        if (unread > 0) SliverToBoxAdapter(child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF6C63FF).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Text('$unread notificaciones sin leer', style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 13)))),
        SliverList(delegate: SliverChildBuilderDelegate((_, i) {
          final n = _notifs[i];
          final typeColors = {
            NotificationType.achievement: const Color(0xFFFFE66D),
            NotificationType.membership: const Color(0xFF6C63FF),
            NotificationType.classReminder: const Color(0xFF4ECDC4),
            NotificationType.payment: const Color(0xFF4ECDC4),
            NotificationType.promotion: const Color(0xFFFF6B6B),
            NotificationType.health: const Color(0xFFFF9F43),
          };
          final c = typeColors[n.type] ?? Colors.white38;
          final ago = DateTime.now().difference(n.createdAt);
          String timeStr;
          if (ago.inMinutes < 60) {
            timeStr = '${ago.inMinutes}m';
          } else if (ago.inHours < 24) {
            timeStr = '${ago.inHours}h';
          } else {
            timeStr = '${ago.inDays}d';
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            decoration: BoxDecoration(
              color: n.isRead ? const Color(0xFF12121A) : c.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: n.isRead ? Colors.white.withValues(alpha: 0.03) : c.withValues(alpha: 0.15))),
            child: ListTile(
              leading: Container(width: 40, height: 40, decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(n.type.icon, style: const TextStyle(fontSize: 20)))),
              title: Text(n.title, style: TextStyle(color: Colors.white, fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600, fontSize: 14)),
              subtitle: Text(n.body, style: const TextStyle(color: Colors.white38, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(timeStr, style: const TextStyle(color: Colors.white24, fontSize: 11)),
                if (!n.isRead) ...[const SizedBox(height: 4),
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle))],
              ]),
              onTap: () { _svc.markAsRead(n.id); _load(); },
            ),
          );
        }, childCount: _notifs.length)),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ]),
    );
  }
}
