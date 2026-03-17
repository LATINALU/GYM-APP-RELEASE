import 'package:flutter/material.dart';
import '../../../domain/entities/exercise.dart';

/// Widget que renderiza un mapa de calor muscular basado en la intensidad
class MuscleHeatmapView extends StatelessWidget {
  final MuscleHeatmap heatmap;
  final double size;

  const MuscleHeatmapView({
    super.key,
    required this.heatmap,
    this.size = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomPaint(
        painter: _MusclePainter(heatmap),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'MAPA DE ACTIVACIÓN',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _MusclePainter extends CustomPainter {
  final MuscleHeatmap heatmap;
  _MusclePainter(this.heatmap);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Simplificación de coordenadas para el ejemplo (en prod se usarían paths de SVG)
    final Map<String, Rect> muscleRects = {
      'pectorals': Rect.fromLTWH(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.1),
      'abs': Rect.fromLTWH(size.width * 0.35, size.height * 0.35, size.width * 0.3, size.height * 0.15),
      'quads': Rect.fromLTWH(size.width * 0.25, size.height * 0.6, size.width * 0.2, size.height * 0.2),
      'biceps': Rect.fromLTWH(size.width * 0.15, size.height * 0.25, size.width * 0.1, size.height * 0.1),
      'triceps': Rect.fromLTWH(size.width * 0.75, size.height * 0.25, size.width * 0.1, size.height * 0.1),
    };

    // Dibujar base (Silueta simple)
    paint.color = Colors.white.withValues(alpha: 0.1);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.3, size.height * 0.1, size.width * 0.4, size.height * 0.8), const Radius.circular(50)), paint);

    // Dibujar intensidades
    heatmap.intensities.forEach((muscle, intensity) {
      if (muscleRects.containsKey(muscle)) {
        // Escala de color: de azul suave a naranja/rojo intenso
        paint.color = Color.lerp(
          const Color(0xFF6366F1).withValues(alpha: 0.2), 
          const Color(0xFFF87171), 
          intensity
        )!;
        
        canvas.drawOval(muscleRects[muscle]!, paint);
      }
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
