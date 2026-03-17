import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quantum_colors.dart';

/// QUANTUM FIT - Sistema tipográfico geométrico minimalista
/// Tipografía limpia, moderna y de alta legibilidad
class QuantumTypography {
  QuantumTypography._();

  // ═══════════════════════════════════════════════════════════════════════════
  // FUENTES BASE - Usando Google Fonts
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Obtener TextStyle base de Inter
  static TextStyle get _interBase => GoogleFonts.inter();
  
  /// Obtener TextStyle base de JetBrains Mono para datos
  static TextStyle get _monoBase => GoogleFonts.jetBrainsMono();

  // ═══════════════════════════════════════════════════════════════════════════
  // ENCABEZADOS - Light weight para minimalismo
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Display Large - Títulos principales enormes
  static TextStyle get displayLarge => _interBase.copyWith(
    fontSize: 56,
    fontWeight: FontWeight.w200,
    letterSpacing: -2.0,
    height: 1.1,
    color: QuantumColors.nebulaWhite,
  );
  
  /// Display Medium - Números grandes de métricas
  static TextStyle get displayMedium => _interBase.copyWith(
    fontSize: 48,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.5,
    height: 1.2,
    color: QuantumColors.nebulaWhite,
  );
  
  /// H1 - Títulos de sección principales
  static TextStyle get h1 => _interBase.copyWith(
    fontSize: 40,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.5,
    height: 1.2,
    color: QuantumColors.nebulaWhite,
  );
  
  /// H2 - Subtítulos y nombres de pantallas
  static TextStyle get h2 => _interBase.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.5,
    height: 1.3,
    color: QuantumColors.nebulaWhite,
  );
  
  /// H3 - Encabezados de tarjetas
  static TextStyle get h3 => _interBase.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
    height: 1.3,
    color: QuantumColors.nebulaWhite,
  );
  
  /// H4 - Subtítulos de tarjetas
  static TextStyle get h4 => _interBase.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
    color: QuantumColors.nebulaWhite,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // CUERPO DE TEXTO
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Body Large - Texto principal
  static TextStyle get bodyLarge => _interBase.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.1,
    color: QuantumColors.nebulaWhite.withValues(alpha: 0.9),
  );
  
  /// Body - Texto estándar
  static TextStyle get body => _interBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.1,
    color: QuantumColors.nebulaWhite.withValues(alpha: 0.8),
  );
  
  /// Body Small - Texto secundario
  static TextStyle get bodySmall => _interBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
    color: QuantumColors.nebulaWhite.withValues(alpha: 0.6),
  );
  
  /// Body Medium - Alias for body (Material 3 compatibility)
  static TextStyle get bodyMedium => body;

  // ═══════════════════════════════════════════════════════════════════════════
  // DATOS Y ETIQUETAS TÉCNICAS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Data - Números y valores con estilo técnico
  static TextStyle get data => _monoBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: QuantumColors.quantumBlue,
  );
  
  /// Data Large - Métricas destacadas
  static TextStyle get dataLarge => _monoBase.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: QuantumColors.quantumBlue,
  );
  
  /// Label - Etiquetas de campos
  static TextStyle get label => _interBase.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: QuantumColors.nebulaWhite.withValues(alpha: 0.5),
  );
  
  /// Caption - Texto muy pequeño
  static TextStyle get caption => _interBase.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: QuantumColors.nebulaWhite.withValues(alpha: 0.4),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTONES Y ACCIONES
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Button Large - Botones principales
  static TextStyle get buttonLarge => _interBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: QuantumColors.nebulaWhite,
  );
  
  /// Button - Botones estándar
  static TextStyle get button => _interBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: QuantumColors.nebulaWhite,
  );
  
  /// Button Small - Botones compactos
  static TextStyle get buttonSmall => _interBase.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: QuantumColors.nebulaWhite,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS CON COLORES
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Estilo para valores numéricos de métricas
  static TextStyle metric({Color? color}) => displayMedium.copyWith(
    color: color ?? QuantumColors.nebulaWhite,
    fontWeight: FontWeight.w200,
  );
  
  /// Estilo para unidades de métricas
  static TextStyle unit({Color? color}) => body.copyWith(
    color: color ?? QuantumColors.quantumBlue,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  
  /// Estilo para títulos de sección con acento
  static TextStyle sectionTitle({Color? accentColor}) => h4.copyWith(
    color: accentColor ?? QuantumColors.nebulaWhite,
    letterSpacing: 0.5,
  );
  
  /// Estilo para estados de error
  static TextStyle get error => body.copyWith(
    color: QuantumColors.error,
    fontWeight: FontWeight.w500,
  );
  
  /// Estilo para estados de éxito
  static TextStyle get success => body.copyWith(
    color: QuantumColors.success,
    fontWeight: FontWeight.w500,
  );
}
