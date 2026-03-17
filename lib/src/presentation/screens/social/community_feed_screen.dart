import 'package:flutter/material.dart';
import '../../../domain/entities/social_post.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});
  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final List<SocialPost> _posts = [];
  String _filter = 'Todo';
  final _filters = ['Todo', 'Entrenos', 'PRs', 'Logros', 'Rachas'];

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'Todo' ? _posts : _posts.where((p) {
      if (_filter == 'Entrenos') return p.type == SocialPostType.workout;
      if (_filter == 'PRs') return p.type == SocialPostType.pr;
      if (_filter == 'Logros') return p.type == SocialPostType.achievement;
      if (_filter == 'Rachas') return p.type == SocialPostType.streak;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(slivers: [
        SliverAppBar(backgroundColor: const Color(0xFF0A0A0F), pinned: true,
          title: const Text('Comunidad', style: TextStyle(fontWeight: FontWeight.w700)),
          actions: [IconButton(icon: const Icon(Icons.edit_square, color: Color(0xFF6C63FF)), onPressed: _showCreatePost)]),
        SliverToBoxAdapter(child: SizedBox(height: 44, child: ListView.builder(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length, itemBuilder: (_, i) {
            final f = _filters[i]; final sel = f == _filter;
            return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
              label: Text(f), selected: sel, selectedColor: const Color(0xFF6C63FF),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              labelStyle: TextStyle(color: sel ? Colors.white : Colors.white54, fontSize: 12),
              onSelected: (_) => setState(() => _filter = f)));
          }))),
        // Weekly challenge card
        SliverToBoxAdapter(child: Container(
          margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFFFF6B6B).withValues(alpha: 0.15), const Color(0xFF12121A)]),
            borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.2))),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Text('⚔️', style: TextStyle(fontSize: 24)))),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Desafío Semanal', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 12, fontWeight: FontWeight.w600)),
              Text('100 km de cardio en 7 días', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              Text('43 participantes · 500 XP', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ])),
            ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Unirse', style: TextStyle(fontSize: 12))),
          ]),
        )),
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF12121A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.forum_outlined, color: Colors.white24, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Aún no hay publicaciones en la comunidad',
                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Cuando existan publicaciones reales de miembros, aparecerán aquí.',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(delegate: SliverChildBuilderDelegate((_, i) => _postCard(filtered[i]), childCount: filtered.length)),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ]),
    );
  }

  Widget _postCard(SocialPost p) {
    final typeColors = {SocialPostType.workout: const Color(0xFF6C63FF), SocialPostType.achievement: const Color(0xFFFFE66D),
      SocialPostType.pr: const Color(0xFF4ECDC4), SocialPostType.streak: const Color(0xFFFF6B6B)};
    final c = typeColors[p.type] ?? Colors.white38;
    final ago = DateTime.now().difference(p.createdAt);
    final timeStr = ago.inHours < 1 ? '${ago.inMinutes}m' : ago.inHours < 24 ? '${ago.inHours}h' : '${ago.inDays}d';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF12121A), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 18, backgroundColor: c.withValues(alpha: 0.15),
            child: Text(p.userName[0], style: TextStyle(color: c, fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            Row(children: [
              Text('${p.type.emoji} ${p.type.displayName}', style: TextStyle(color: c, fontSize: 11)),
              Text(' · $timeStr', style: const TextStyle(color: Colors.white24, fontSize: 11)),
            ]),
          ])),
          const Icon(Icons.more_horiz, color: Colors.white24, size: 20),
        ]),
        const SizedBox(height: 12),
        Text(p.content, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
        const SizedBox(height: 12),
        Row(children: [
          Icon(p.isLiked ? Icons.favorite : Icons.favorite_border, color: p.isLiked ? const Color(0xFFFF6B6B) : Colors.white24, size: 20),
          const SizedBox(width: 4),
          Text('${p.likes}', style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(width: 20),
          const Icon(Icons.chat_bubble_outline, color: Colors.white24, size: 18),
          const SizedBox(width: 4),
          Text('${p.comments}', style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const Spacer(),
          const Icon(Icons.share_outlined, color: Colors.white24, size: 18),
        ]),
      ]),
    );
  }

  void _showCreatePost() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Compartir con la Comunidad', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(maxLines: 3, style: const TextStyle(color: Colors.white), decoration: InputDecoration(
            hintText: '¿Qué lograste hoy?', hintStyle: const TextStyle(color: Colors.white24),
            filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: SocialPostType.values.map((t) => Chip(
            avatar: Text(t.emoji), label: Text(t.displayName),
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            labelStyle: const TextStyle(color: Colors.white54, fontSize: 12))).toList()),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
            onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Publicado ✓'), backgroundColor: Color(0xFF4ECDC4))); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Publicar'))),
        ]),
      ));
  }
}
