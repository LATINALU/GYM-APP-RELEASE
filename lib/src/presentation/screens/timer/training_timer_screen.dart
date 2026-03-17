import 'package:flutter/material.dart';
import 'dart:async';

/// Training Timer Screen - Stopwatch, HIIT timer, rest timer for workouts
class TrainingTimerScreen extends StatefulWidget {
  const TrainingTimerScreen({super.key});
  @override
  State<TrainingTimerScreen> createState() => _TrainingTimerScreenState();
}

class _TrainingTimerScreenState extends State<TrainingTimerScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0=Stopwatch, 1=Rest Timer, 2=HIIT
  final _tabs = ['Cronómetro', 'Descanso', 'HIIT'];

  // Stopwatch
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _swTimer;
  String _swDisplay = '00:00.00';

  // Rest timer
  int _restSeconds = 90;
  int _restRemaining = 0;
  Timer? _restTimer;
  bool _restRunning = false;

  // HIIT
  int _hiitWork = 30;
  int _hiitRest = 15;
  int _hiitRounds = 8;
  int _hiitCurrentRound = 0;
  int _hiitRemaining = 0;
  bool _hiitIsWork = true;
  bool _hiitRunning = false;
  Timer? _hiitTimer;

  @override
  void dispose() {
    _swTimer?.cancel(); _restTimer?.cancel(); _hiitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(slivers: [
        const SliverAppBar(backgroundColor: Color(0xFF0A0A0F), pinned: true,
          title: Text('Timer', style: TextStyle(fontWeight: FontWeight.w700))),
        SliverToBoxAdapter(child: _buildTabs()),
        SliverToBoxAdapter(child: _selectedTab == 0 ? _buildStopwatch() : _selectedTab == 1 ? _buildRestTimer() : _buildHiit()),
      ]),
    );
  }

  Widget _buildTabs() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), height: 44,
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(22)),
    child: Row(children: List.generate(3, (i) => Expanded(child: GestureDetector(
      onTap: () => setState(() => _selectedTab = i),
      child: Container(
        decoration: BoxDecoration(
          color: _selectedTab == i ? const Color(0xFF6C63FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(22)),
        alignment: Alignment.center,
        child: Text(_tabs[i], style: TextStyle(color: _selectedTab == i ? Colors.white : Colors.white54, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    )))),
  );

  // ===== STOPWATCH =====
  Widget _buildStopwatch() {
    return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      const SizedBox(height: 40),
      Container(
        width: 260, height: 260,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3), width: 4),
          boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.1), blurRadius: 40)]),
        child: Center(child: Text(_swDisplay, style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w300, fontFamily: 'monospace'))),
      ),
      const SizedBox(height: 48),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _timerButton(_stopwatch.isRunning ? Icons.pause : Icons.play_arrow,
          _stopwatch.isRunning ? 'Pausar' : 'Iniciar',
          _stopwatch.isRunning ? const Color(0xFFFFE66D) : const Color(0xFF4ECDC4),
          () { setState(() {
            if (_stopwatch.isRunning) { _stopwatch.stop(); _swTimer?.cancel(); }
            else { _stopwatch.start(); _swTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
              setState(() { final e = _stopwatch.elapsed; _swDisplay = '${e.inMinutes.toString().padLeft(2,'0')}:${(e.inSeconds%60).toString().padLeft(2,'0')}.${(e.inMilliseconds%1000~/10).toString().padLeft(2,'0')}'; });
            }); }
          }); }),
        const SizedBox(width: 20),
        _timerButton(Icons.refresh, 'Reset', const Color(0xFFFF6B6B), () {
          setState(() { _stopwatch.stop(); _stopwatch.reset(); _swTimer?.cancel(); _swDisplay = '00:00.00'; });
        }),
      ]),
    ]));
  }

  // ===== REST TIMER =====
  Widget _buildRestTimer() {
    return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      const SizedBox(height: 20),
      // Presets
      Wrap(spacing: 10, children: [30, 60, 90, 120, 180].map((s) => ChoiceChip(
        label: Text('${s}s'), selected: _restSeconds == s, selectedColor: const Color(0xFF6C63FF),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        labelStyle: TextStyle(color: _restSeconds == s ? Colors.white : Colors.white54),
        onSelected: (_) => setState(() { _restSeconds = s; _restRemaining = s; }),
      )).toList()),
      const SizedBox(height: 40),
      Container(
        width: 260, height: 260,
        decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: _restRunning ? const Color(0xFF4ECDC4) : Colors.white12, width: 4)),
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(width: 240, height: 240, child: CircularProgressIndicator(
            value: _restSeconds > 0 ? _restRemaining / _restSeconds : 0,
            strokeWidth: 8, backgroundColor: Colors.white10,
            color: const Color(0xFF4ECDC4), strokeCap: StrokeCap.round)),
          Text(_restRunning ? '${_restRemaining}s' : '${_restSeconds}s',
            style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w200, fontFamily: 'monospace')),
        ]),
      ),
      const SizedBox(height: 40),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _timerButton(_restRunning ? Icons.pause : Icons.play_arrow,
          _restRunning ? 'Pausar' : 'Iniciar', const Color(0xFF4ECDC4), () {
          if (_restRunning) { _restTimer?.cancel(); setState(() => _restRunning = false); }
          else { setState(() { _restRemaining = _restRemaining > 0 ? _restRemaining : _restSeconds; _restRunning = true; });
            _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
              setState(() { _restRemaining--;
                if (_restRemaining <= 0) { _restTimer?.cancel(); _restRunning = false; }
              });
            });
          }
        }),
        const SizedBox(width: 20),
        _timerButton(Icons.refresh, 'Reset', const Color(0xFFFF6B6B), () {
          _restTimer?.cancel(); setState(() { _restRunning = false; _restRemaining = _restSeconds; });
        }),
      ]),
    ]));
  }

  // ===== HIIT =====
  Widget _buildHiit() {
    final isWork = _hiitIsWork;
    final c = isWork ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4);
    return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _hiitParam('Trabajo', '${_hiitWork}s', () => setState(() => _hiitWork = (_hiitWork + 5).clamp(5, 120))),
        _hiitParam('Descanso', '${_hiitRest}s', () => setState(() => _hiitRest = (_hiitRest + 5).clamp(5, 120))),
        _hiitParam('Rondas', '$_hiitRounds', () => setState(() => _hiitRounds = (_hiitRounds + 1).clamp(1, 20))),
      ]),
      const SizedBox(height: 30),
      Container(
        width: 260, height: 260,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.withValues(alpha: 0.4), width: 4)),
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(width: 240, height: 240, child: CircularProgressIndicator(
            value: _hiitRunning ? _hiitRemaining / (isWork ? _hiitWork : _hiitRest) : 1, strokeWidth: 8,
            backgroundColor: Colors.white10, color: c, strokeCap: StrokeCap.round)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_hiitRunning ? (isWork ? 'TRABAJO' : 'DESCANSO') : 'LISTO', style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2)),
            Text(_hiitRunning ? '${_hiitRemaining}' : '${_hiitWork}',
              style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w200, fontFamily: 'monospace')),
            if (_hiitRunning) Text('Ronda $_hiitCurrentRound/$_hiitRounds', style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ]),
        ]),
      ),
      const SizedBox(height: 40),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _timerButton(_hiitRunning ? Icons.pause : Icons.play_arrow,
          _hiitRunning ? 'Pausar' : 'Iniciar', c, () {
          if (_hiitRunning) { _hiitTimer?.cancel(); setState(() => _hiitRunning = false); }
          else { setState(() { _hiitRunning = true; _hiitIsWork = true;
            _hiitCurrentRound = _hiitCurrentRound == 0 ? 1 : _hiitCurrentRound;
            _hiitRemaining = _hiitRemaining > 0 ? _hiitRemaining : _hiitWork; });
            _hiitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
              setState(() { _hiitRemaining--;
                if (_hiitRemaining <= 0) {
                  if (_hiitIsWork) { _hiitIsWork = false; _hiitRemaining = _hiitRest; }
                  else { _hiitCurrentRound++;
                    if (_hiitCurrentRound > _hiitRounds) { _hiitTimer?.cancel(); _hiitRunning = false; _hiitCurrentRound = 0; }
                    else { _hiitIsWork = true; _hiitRemaining = _hiitWork; }
                  }
                }
              });
            });
          }
        }),
        const SizedBox(width: 20),
        _timerButton(Icons.refresh, 'Reset', const Color(0xFFFF6B6B), () {
          _hiitTimer?.cancel(); setState(() { _hiitRunning = false; _hiitCurrentRound = 0; _hiitRemaining = 0; _hiitIsWork = true; });
        }),
      ]),
    ]));
  }

  Widget _timerButton(IconData ic, String label, Color c, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(color: c.withValues(alpha: 0.15), shape: BoxShape.circle,
        border: Border.all(color: c.withValues(alpha: 0.3))),
        child: Icon(ic, color: c, size: 28)),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(color: c, fontSize: 12)),
    ]),
  );

  Widget _hiitParam(String label, String val, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const Text('tap +', style: TextStyle(color: Colors.white12, fontSize: 9)),
      ]),
    ),
  );
}
