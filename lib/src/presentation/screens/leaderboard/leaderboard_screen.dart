import 'package:flutter/material.dart';
import '../../../application/services/gamification_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _svc = GamificationService();
  List<Map<String, dynamic>> _leaders = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _leaders = await _svc.getLeaderboard();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Color(0xFF0A0A0F), body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(slivers: [
        const SliverAppBar(expandedHeight: 80, backgroundColor: Color(0xFF0A0A0F), pinned: true,
          flexibleSpace: FlexibleSpaceBar(title: Text('Ranking', style: TextStyle(fontWeight: FontWeight.w700)))),
        // Top 3 podium
        if (_leaders.length >= 3) SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: _podium(_leaders[1], 2, const Color(0xFFC0C0C0), 120)),
            Expanded(child: _podium(_leaders[0], 1, const Color(0xFFFFD700), 150)),
            Expanded(child: _podium(_leaders[2], 3, const Color(0xFFCD7F32), 100)),
          ]),
        )),
        // Rest of the list
        SliverList(delegate: SliverChildBuilderDelegate((_, i) {
          if (i < 3) return const SizedBox.shrink();
          final leader = _leaders[i];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFF12121A), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              SizedBox(width: 30, child: Text('#${i + 1}', style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w700))),
              CircleAvatar(radius: 18, backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                child: Text((leader['name'] ?? '?')[0], style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w700))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(leader['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('Nivel ${leader['level']} · ${leader['rank']}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ])),
              Text('${leader['totalXp']} XP', style: const TextStyle(color: Color(0xFFFFE66D), fontWeight: FontWeight.w700)),
            ]),
          );
        }, childCount: _leaders.length)),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ]),
    );
  }

  Widget _podium(Map<String, dynamic> leader, int rank, Color medalColor, double height) {
    final medals = ['', '🥇', '🥈', '🥉'];
    return Column(children: [
      Text(medals[rank], style: const TextStyle(fontSize: 28)),
      const SizedBox(height: 8),
      CircleAvatar(radius: rank == 1 ? 32 : 24, backgroundColor: medalColor.withValues(alpha: 0.2),
        child: Text((leader['name'] ?? '?')[0], style: TextStyle(color: medalColor, fontWeight: FontWeight.w800, fontSize: rank == 1 ? 22 : 16))),
      const SizedBox(height: 8),
      Text(leader['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
      Text('${leader['totalXp']} XP', style: TextStyle(color: medalColor, fontWeight: FontWeight.w700, fontSize: 12)),
      const SizedBox(height: 8),
      Container(
        height: height, width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [medalColor.withValues(alpha: 0.3), medalColor.withValues(alpha: 0.05)]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
        child: Center(child: Text('#$rank', style: TextStyle(color: medalColor, fontSize: 24, fontWeight: FontWeight.w900))),
      ),
    ]);
  }
}
