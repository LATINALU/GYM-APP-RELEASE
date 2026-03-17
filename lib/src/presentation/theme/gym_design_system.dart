/// GYM COLORS - Sistema de colores profesional para app de gimnasio
import 'package:flutter/material.dart';

class GymColors {
  // === COLORES PRIMARIOS (Energía y Fuerza) ===
  static const Color primary = Color(0xFFE53935);       // Rojo gym energético
  static const Color primaryDark = Color(0xFFB71C1C);   // Rojo oscuro
  static const Color primaryLight = Color(0xFFFF6F60);  // Rojo claro
  
  // === COLORES SECUNDARIOS ===
  static const Color secondary = Color(0xFF1E88E5);     // Azul profesional
  static const Color secondaryDark = Color(0xFF1565C0);
  static const Color secondaryLight = Color(0xFF64B5F6);
  
  // === COLORES DE ACENTO ===
  static const Color accent = Color(0xFFFF6D00);        // Naranja energético
  static const Color accentAlt = Color(0xFF7C4DFF);     // Púrpura premium
  
  // === FONDOS (Dark Theme - Quantum Fit) ===
  static const Color background = Color(0xFF0D0D1A);
  static const Color backgroundDark = Color(0xFF0A0A14);
  static const Color surface = Color(0xFF16162A);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardBackground = Color(0xFF16162A);
  static const Color cardBackgroundDark = Color(0xFF252525);
  
  // === DIVIDERS Y BORDES ===
  static const Color divider = Color(0xFF2A2A3D);
  static const Color dividerDark = Color(0xFF424242);
  static const Color border = Color(0xFF2A2A3D);
  
  // === ESTADOS ===
  static const Color success = Color(0xFF43A047);       // Verde éxito
  static const Color successLight = Color(0xFF1B3A1B);  // Dark green bg
  static const Color warning = Color(0xFFFB8C00);       // Naranja advertencia
  static const Color warningLight = Color(0xFF3A2E1B);  // Dark orange bg
  static const Color error = Color(0xFFE53935);         // Rojo error
  static const Color errorLight = Color(0xFF3A1B1B);    // Dark red bg
  static const Color info = Color(0xFF1E88E5);          // Azul info
  static const Color infoLight = Color(0xFF1B2A3A);     // Dark blue bg
  
  // === TEXTOS (Dark Theme) ===
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFF616161);
  static const Color textHint = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkSecondary = Color(0xB3FFFFFF); // 70%
  
  // === ESTADOS DE MEMBRESÍA ===
  static const Color membershipActive = Color(0xFF43A047);
  static const Color membershipPending = Color(0xFFFB8C00);
  static const Color membershipExpired = Color(0xFFE53935);
  static const Color membershipFrozen = Color(0xFF29B6F6);
  static const Color membershipCancelled = Color(0xFF757575);
  
  // === OCUPACIÓN DEL GYM ===
  static const Color occupancyLow = Color(0xFF43A047);      // 0-30% - Verde
  static const Color occupancyMedium = Color(0xFFFB8C00);   // 31-70% - Naranja
  static const Color occupancyHigh = Color(0xFFE53935);     // 71-100% - Rojo
  
  // === ZONAS DEL GYM ===
  static const Color zoneWeights = Color(0xFFE53935);
  static const Color zoneCardio = Color(0xFF1E88E5);
  static const Color zoneCrossfit = Color(0xFFFF6D00);
  static const Color zoneYoga = Color(0xFF7C4DFF);
  static const Color zoneSpa = Color(0xFF26A69A);
  static const Color zonePool = Color(0xFF00ACC1);
  
  // === TIERS DE MEMBRESÍA ===
  static const Color tierBasic = Color(0xFF78909C);
  static const Color tierStandard = Color(0xFF1E88E5);
  static const Color tierPremium = Color(0xFF7C4DFF);
  static const Color tierBlack = Color(0xFFFFD700);
  
  // === GRADIENTS ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE53935), Color(0xFFFF6F60)],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6D00), Color(0xFFFFAB40)],
  );
  
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
  );
  
  static const LinearGradient blackGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF212121), Color(0xFF424242)],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
  );
  
  // === HELPERS ===
  
  /// Obtiene el color de ocupación basado en porcentaje
  static Color getOccupancyColor(double percentage) {
    if (percentage <= 0.3) return occupancyLow;
    if (percentage <= 0.7) return occupancyMedium;
    return occupancyHigh;
  }
  
  /// Obtiene gradient de ocupación
  static LinearGradient getOccupancyGradient(double percentage) {
    final color = getOccupancyColor(percentage);
    return LinearGradient(
      colors: [color, color.withValues(alpha: 0.7)],
    );
  }
  
  /// Color para tier de membresía
  static Color getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'basic': return tierBasic;
      case 'standard': return tierStandard;
      case 'premium': return tierPremium;
      case 'black': return tierBlack;
      default: return tierBasic;
    }
  }
  
  /// Gradient para tier de membresía
  static LinearGradient getTierGradient(String tier) {
    switch (tier.toLowerCase()) {
      case 'basic':
        return LinearGradient(colors: [tierBasic, tierBasic.withValues(alpha: 0.7)]);
      case 'standard':
        return secondaryGradient;
      case 'premium':
        return premiumGradient;
      case 'black':
        return LinearGradient(
          colors: [const Color(0xFF212121), const Color(0xFFFFD700).withValues(alpha: 0.3)],
        );
      default:
        return primaryGradient;
    }
  }
}

/// Tipografía del sistema de diseño
class GymTypography {
  // === FONT FAMILIES ===
  static const String fontFamily = 'Roboto';
  static const String fontFamilyDisplay = 'Montserrat';
  
  // === TAMAÑOS ===
  static const double displayLarge = 40.0;
  static const double displayMedium = 32.0;
  static const double displaySmall = 28.0;
  
  static const double headlineLarge = 24.0;
  static const double headlineMedium = 20.0;
  static const double headlineSmall = 18.0;
  
  static const double titleLarge = 16.0;
  static const double titleMedium = 14.0;
  static const double titleSmall = 12.0;
  
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 10.0;
  
  // === PESOS ===
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  
  // === ESTILOS PREDEFINIDOS ===
  static TextStyle get displayLargeStyle => const TextStyle(
    fontSize: displayLarge,
    fontWeight: bold,
    letterSpacing: -0.5,
    color: GymColors.textPrimary,
  );
  
  static TextStyle get headlineLargeStyle => const TextStyle(
    fontSize: headlineLarge,
    fontWeight: semiBold,
    color: GymColors.textPrimary,
  );
  
  static TextStyle get headlineMediumStyle => const TextStyle(
    fontSize: headlineMedium,
    fontWeight: semiBold,
    color: GymColors.textPrimary,
  );
  
  static TextStyle get bodyLargeStyle => const TextStyle(
    fontSize: bodyLarge,
    fontWeight: regular,
    color: GymColors.textPrimary,
  );
  
  static TextStyle get bodyMediumStyle => const TextStyle(
    fontSize: bodyMedium,
    fontWeight: regular,
    color: GymColors.textSecondary,
  );
  
  static TextStyle get labelStyle => const TextStyle(
    fontSize: labelMedium,
    fontWeight: medium,
    letterSpacing: 0.5,
    color: GymColors.textSecondary,
  );
  
  static TextStyle get buttonStyle => const TextStyle(
    fontSize: labelLarge,
    fontWeight: semiBold,
    letterSpacing: 0.5,
  );
}

/// Espaciados del sistema
class GymSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16.0, 
    vertical: 12.0,
  );
}

/// Radios de borde
class GymRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 100.0;
  
  static BorderRadius get xsRadius => BorderRadius.circular(xs);
  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
}

/// Sombras del sistema
class GymShadows {
  static List<BoxShadow> get none => [];
  
  static List<BoxShadow> get sm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> get md => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get lg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get xl => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> colored(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Duraciones de animación
class GymDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration verySlow = Duration(milliseconds: 600);
}

/// Curves de animación
class GymCurves {
  static const Curve standard = Curves.easeInOut;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve bounce = Curves.elasticOut;
}
