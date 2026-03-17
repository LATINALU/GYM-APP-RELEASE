import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'quantum_colors.dart';

/// QUANTUM FIT - Tema principal de la aplicación
/// Combina colores, tipografía y estilos de componentes
class QuantumTheme {
  QuantumTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES RÁPIDOS
  // ═══════════════════════════════════════════════════════════════════════════
  static Color get background => QuantumColors.cosmicBlack;
  static Color get surface => QuantumColors.voidGray;
  static Color get primary => QuantumColors.quantumBlue;
  static Color get secondary => QuantumColors.matrixCyan;
  static Color get error => QuantumColors.error;

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMA PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════════
  
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      // Colores base
      scaffoldBackgroundColor: QuantumColors.cosmicBlack,
      primaryColor: QuantumColors.quantumBlue,
      
      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: QuantumColors.quantumBlue,
        secondary: QuantumColors.matrixCyan,
        surface: QuantumColors.voidGray,
        error: QuantumColors.error,
        onPrimary: QuantumColors.nebulaWhite,
        onSecondary: QuantumColors.cosmicBlack,
        onSurface: QuantumColors.nebulaWhite,
        onError: QuantumColors.nebulaWhite,
      ),
      
      /*
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: QuantumColors.nebulaWhite,
          size: 24,
        ),
        titleTextStyle: QuantumTypography.h4,
        systemOverlayStyle: systemOverlayStyle,
      ),
      
      // Iconos
      iconTheme: IconThemeData(
        color: QuantumColors.nebulaWhite,
        size: 24,
      ),
      */
      
      // Texto
      textTheme: TextTheme(
        displayLarge: QuantumTypography.displayLarge,
        displayMedium: QuantumTypography.displayMedium,
        headlineLarge: QuantumTypography.h1,
        headlineMedium: QuantumTypography.h2,
        headlineSmall: QuantumTypography.h3,
        titleLarge: QuantumTypography.h4,
        titleMedium: QuantumTypography.bodyLarge,
        bodyLarge: QuantumTypography.bodyLarge,
        bodyMedium: QuantumTypography.body,
        bodySmall: QuantumTypography.bodySmall,
        labelLarge: QuantumTypography.buttonLarge,
        labelMedium: QuantumTypography.button,
        labelSmall: QuantumTypography.caption,
      ),
      
      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: QuantumColors.quantumBlue,
          foregroundColor: QuantumColors.nebulaWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: QuantumTypography.button,
        ),
      ),
      
      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: QuantumColors.quantumBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: QuantumTypography.button,
        ),
      ),
      
      // Botones con borde
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: QuantumColors.quantumBlue,
          side: const BorderSide(color: QuantumColors.quantumBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: QuantumTypography.button,
        ),
      ),
      
      // Campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: QuantumColors.voidGray.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: QuantumColors.subtleBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: QuantumColors.subtleBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: QuantumColors.quantumBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: QuantumColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: QuantumColors.error, width: 2),
        ),
        labelStyle: QuantumTypography.label,
        hintStyle: QuantumTypography.body.copyWith(
          color: QuantumColors.nebulaWhite.withValues(alpha: 0.3),
        ),
        errorStyle: QuantumTypography.caption.copyWith(
          color: QuantumColors.error,
        ),
        prefixIconColor: QuantumColors.textSecondary,
        suffixIconColor: QuantumColors.textSecondary,
      ),
      
      /*
      // Cards
      cardTheme: CardTheme(
        color: QuantumColors.voidGray.withValues(alpha: 0.4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: QuantumColors.subtleBorder),
        ),
        margin: const EdgeInsets.all(8),
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: QuantumColors.quantumBlue.withValues(alpha: 0.15),
        labelStyle: QuantumTypography.bodySmall,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: QuantumColors.subtleBorder),
        ),
      ),
      */
      
      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: QuantumColors.voidGray.withValues(alpha: 0.95),
        selectedItemColor: QuantumColors.quantumBlue,
        unselectedItemColor: QuantumColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: QuantumTypography.caption.copyWith(
          color: QuantumColors.quantumBlue,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: QuantumTypography.caption,
      ),
      
      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: QuantumColors.quantumBlue,
        foregroundColor: QuantumColors.nebulaWhite,
        elevation: 8,
        shape: CircleBorder(),
      ),
      
      // Dividers
      dividerTheme: DividerThemeData(
        color: QuantumColors.subtleBorder,
        thickness: 1,
        space: 32,
      ),
      
      /*
      // Dialogs
      dialogTheme: DialogTheme(
        backgroundColor: QuantumColors.voidGray,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: QuantumTypography.h3,
        contentTextStyle: QuantumTypography.body,
      ),
      */
      
      // Snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: QuantumColors.elevatedGray,
        contentTextStyle: QuantumTypography.body,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: QuantumColors.quantumBlue,
        linearTrackColor: QuantumColors.voidGray,
        circularTrackColor: QuantumColors.voidGray,
      ),
      
      // Sliders
      sliderTheme: SliderThemeData(
        activeTrackColor: QuantumColors.quantumBlue,
        inactiveTrackColor: QuantumColors.voidGray,
        thumbColor: QuantumColors.quantumBlue,
        overlayColor: QuantumColors.quantumBlue.withValues(alpha: 0.2),
        trackHeight: 4,
      ),
      
      // Switches
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return QuantumColors.quantumBlue;
          }
          return QuantumColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return QuantumColors.quantumBlue.withValues(alpha: 0.3);
          }
          return QuantumColors.voidGray;
        }),
      ),
      
      // Tooltips
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: QuantumColors.elevatedGray,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: QuantumTypography.caption.copyWith(
          color: QuantumColors.nebulaWhite,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYSTEM UI OVERLAY
  // ═══════════════════════════════════════════════════════════════════════════
  
  static SystemUiOverlayStyle get systemOverlayStyle {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: QuantumColors.cosmicBlack,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }
  
  /// Aplicar el estilo de sistema
  static void applySystemUI() {
    SystemChrome.setSystemUIOverlayStyle(systemOverlayStyle);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING SYSTEM - Escala consistente
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;
  static const double spacingHuge = 64;

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;
  static const double radiusRound = 100;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATION DURATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationVerySlow = Duration(milliseconds: 800);

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATION CURVES
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const Curve curveDefault = Curves.easeInOutCubic;
  static const Curve curveElastic = Curves.elasticOut;
  static const Curve curveBounce = Curves.bounceOut;
}
