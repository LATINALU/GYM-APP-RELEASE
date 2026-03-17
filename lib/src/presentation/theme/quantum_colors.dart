import 'package:flutter/material.dart';
export 'quantum_typography.dart';

/// QUANTUM FIT - Sistema de colores futurista minimalista
/// Filosofía: Menos es más, pero cada elemento cuenta
class QuantumColors {
  QuantumColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // BASE ULTRA MINIMALISTA
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Negro cósmico profundo - Color de fondo principal
  static const Color cosmicBlack = Color(0xFF0F0F12);
  
  /// Gris vacío - Para tarjetas y contenedores
  static const Color voidGray = Color(0xFF1A1A21);
  
  /// Gris oscuro elevado - Para elementos secundarios
  static const Color elevatedGray = Color(0xFF252530);
  
  /// Blanco nebulosa - Color de texto principal
  static const Color nebulaWhite = Color(0xFFF5F5F7);

  // ═══════════════════════════════════════════════════════════════════════════
  // ACENTOS MONOCROMÁTICOS - Variaciones sutiles de cian/azul
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Azul cuántico brillante - Acento principal
  static const Color quantumBlue = Color(0xFF00E0FF);
  
  /// Azul espacio profundo - Acento secundario
  static const Color deepSpaceBlue = Color(0xFF0066FF);
  
  /// Cian matriz - Para estados activos y éxito
  static const Color matrixCyan = Color(0xFF00FFE0);
  
  /// Púrpura holográfico - Acento terciario
  static const Color holoPurple = Color(0xFF8B5CF6);

  // ═══════════════════════════════════════════════════════════════════════════
  // ESTADOS SEMÁNTICOS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Estado de éxito
  static const Color success = matrixCyan;
  
  /// Estado de advertencia
  static const Color warning = Color(0xFFFFD600);
  
  /// Estado de error
  static const Color error = Color(0xFFFF3860);
  
  /// Estado inactivo/deshabilitado
  static Color get disabled => nebulaWhite.withValues(alpha: 0.3);

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENTES
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Gradiente principal minimalista
  static const LinearGradient minimalGradient = LinearGradient(
    colors: [quantumBlue, deepSpaceBlue],
    stops: [0.0, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Gradiente de fondo cósmico
  static const LinearGradient cosmicGradient = LinearGradient(
    colors: [cosmicBlack, voidGray, cosmicBlack],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  /// Gradiente holográfico sutil
  static LinearGradient get holoGradient => LinearGradient(
    colors: [
      quantumBlue.withValues(alpha: 0.8),
      matrixCyan.withValues(alpha: 0.6),
      deepSpaceBlue.withValues(alpha: 0.8),
    ],
    stops: const [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Gradiente para bordes brillantes
  static LinearGradient get glowBorderGradient => LinearGradient(
    colors: [
      quantumBlue.withValues(alpha: 0.5),
      Colors.transparent,
      matrixCyan.withValues(alpha: 0.5),
    ],
    stops: const [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SOMBRAS Y BRILLOS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Sombra de tarjeta estándar
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: -10,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: quantumBlue.withValues(alpha: 0.03),
      blurRadius: 30,
      spreadRadius: 1,
    ),
  ];
  
  /// Brillo cuántico para elementos interactivos
  static List<BoxShadow> get quantumGlow => [
    BoxShadow(
      color: quantumBlue.withValues(alpha: 0.4),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: quantumBlue.withValues(alpha: 0.2),
      blurRadius: 40,
      spreadRadius: 5,
    ),
  ];
  
  /// Brillo de éxito
  static List<BoxShadow> get successGlow => [
    BoxShadow(
      color: matrixCyan.withValues(alpha: 0.5),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Color de superficie con opacidad
  static Color surface({double opacity = 0.4}) => 
      voidGray.withOpacity(opacity);
  
  /// Color de borde sutil
  static Color get subtleBorder => Colors.white.withValues(alpha: 0.05);
  
  /// Color de texto secundario
  static Color get textSecondary => nebulaWhite.withValues(alpha: 0.6);
  
  /// Color de texto terciario
  static Color get textTertiary => nebulaWhite.withValues(alpha: 0.4);

  // ═══════════════════════════════════════════════════════════════════════════
  // ALIASES FOR COMPATIBILITY
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Primary color alias
  static const Color primary = quantumBlue;
  
  /// Accent color alias
  static const Color accent = holoPurple;
  
  /// Background start color
  static const Color backgroundStart = cosmicBlack;
  
  /// Background end color
  static const Color backgroundEnd = voidGray;
  
  /// Card background color
  static const Color cardBackground = voidGray;
  
  /// Primary gradient alias
  static const LinearGradient primaryGradient = minimalGradient;
  
  /// Accent gradient
  static const LinearGradient accentGradient = LinearGradient(
    colors: [holoPurple, deepSpaceBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

