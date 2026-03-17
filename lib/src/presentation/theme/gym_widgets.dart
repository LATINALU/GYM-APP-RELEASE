/// GYM WIDGETS - Componentes reutilizables profesionales
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'gym_design_system.dart';
export '../widgets/quantum_buttons.dart';

// ============================================================================
// GYM CARD - Tarjeta elevada con sombras
// ============================================================================
class GymCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final bool elevated;
  final Color? backgroundColor;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final double borderRadius;
  final Border? border;

  const GymCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.elevated = true,
    this.backgroundColor,
    this.gradient,
    this.onTap,
    this.borderRadius = 12,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: GymDurations.fast,
        margin: margin ?? EdgeInsets.zero,
        padding: padding ?? GymSpacing.cardPadding,
        decoration: BoxDecoration(
          color: gradient == null ? (backgroundColor ?? GymColors.surface) : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
          boxShadow: elevated ? GymShadows.md : GymShadows.none,
        ),
        child: child,
      ),
    );
  }
}

// ============================================================================
// GYM BUTTON - Botón principal con estilos
// ============================================================================
enum GymButtonStyle { primary, secondary, outline, ghost, danger }
enum GymButtonSize { small, medium, large }

class GymButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final GymButtonStyle style;
  final GymButtonSize size;
  final bool fullWidth;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;

  const GymButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = GymButtonStyle.primary,
    this.size = GymButtonSize.medium,
    this.fullWidth = false,
    this.icon,
    this.trailingIcon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    final dimensions = _getDimensions();

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: dimensions['height'],
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors['background'],
          foregroundColor: colors['foreground'],
          disabledBackgroundColor: GymColors.textDisabled,
          elevation: style == GymButtonStyle.outline || style == GymButtonStyle.ghost ? 0 : 2,
          shadowColor: colors['background']?.withValues(alpha: 0.3),
          padding: EdgeInsets.symmetric(
            horizontal: dimensions['horizontalPadding']!,
            vertical: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dimensions['radius']!),
            side: style == GymButtonStyle.outline
                ? BorderSide(color: colors['border']!, width: 1.5)
                : BorderSide.none,
          ),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors['foreground']!),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: dimensions['iconSize']),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: dimensions['fontSize'],
                      fontWeight: GymTypography.semiBold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, size: dimensions['iconSize']),
                  ],
                ],
              ),
      ),
    );
  }

  Map<String, Color?> _getColors() {
    switch (style) {
      case GymButtonStyle.primary:
        return {
          'background': GymColors.primary,
          'foreground': GymColors.textOnPrimary,
          'border': GymColors.primary,
        };
      case GymButtonStyle.secondary:
        return {
          'background': GymColors.secondary,
          'foreground': GymColors.textOnPrimary,
          'border': GymColors.secondary,
        };
      case GymButtonStyle.outline:
        return {
          'background': Colors.transparent,
          'foreground': GymColors.primary,
          'border': GymColors.primary,
        };
      case GymButtonStyle.ghost:
        return {
          'background': Colors.transparent,
          'foreground': GymColors.primary,
          'border': Colors.transparent,
        };
      case GymButtonStyle.danger:
        return {
          'background': GymColors.error,
          'foreground': GymColors.textOnPrimary,
          'border': GymColors.error,
        };
    }
  }

  Map<String, double> _getDimensions() {
    switch (size) {
      case GymButtonSize.small:
        return {
          'height': 36,
          'horizontalPadding': 12,
          'fontSize': 12,
          'iconSize': 16,
          'radius': 6,
        };
      case GymButtonSize.medium:
        return {
          'height': 48,
          'horizontalPadding': 20,
          'fontSize': 14,
          'iconSize': 18,
          'radius': 8,
        };
      case GymButtonSize.large:
        return {
          'height': 56,
          'horizontalPadding': 28,
          'fontSize': 16,
          'iconSize': 20,
          'radius': 10,
        };
    }
  }
}

// ============================================================================
// STATUS BADGE - Badge de estado
// ============================================================================
enum StatusType { active, pending, expired, frozen, cancelled, available, occupied, info }

class StatusBadge extends StatelessWidget {
  final String text;
  final StatusType type;
  final bool showIcon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.type,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    var config = _getConfig();
    config ??= {
          'bgColor': const Color(0xFF2A2A3D),
          'textColor': GymColors.textSecondary,
          'icon': Icons.info
       };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config['bgColor'],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(config['icon'], color: config['textColor'], size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: config['textColor'],
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _getConfig() {
    switch (type) {
      case StatusType.active:
        return {
          'bgColor': GymColors.successLight,
          'textColor': GymColors.success,
          'icon': Icons.check_circle,
        };
      case StatusType.pending:
        return {
          'bgColor': GymColors.warningLight,
          'textColor': GymColors.warning,
          'icon': Icons.hourglass_top,
        };
      case StatusType.expired:
        return {
          'bgColor': GymColors.errorLight,
          'textColor': GymColors.error,
          'icon': Icons.cancel,
        };
      case StatusType.frozen:
        return {
          'bgColor': GymColors.infoLight,
          'textColor': GymColors.info,
          'icon': Icons.ac_unit,
        };
      case StatusType.cancelled:
        return {
          'bgColor': const Color(0xFF2A2A3D),
          'textColor': GymColors.textSecondary,
          'icon': Icons.block,
        };
      case StatusType.available:
        return {
          'bgColor': GymColors.successLight,
          'textColor': GymColors.success,
          'icon': Icons.event_available,
        };
      case StatusType.occupied:
        return {
          'bgColor': GymColors.errorLight,
          'textColor': GymColors.error,
          'icon': Icons.people,
        };
      case StatusType.info:
        return {
          'bgColor': GymColors.infoLight,
          'textColor': GymColors.info,
          'icon': Icons.info,
        };
    }
    return null;
  }
}

// ============================================================================
// QUICK ACTION CARD - Botón de acción rápida
// ============================================================================
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final String? badge;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: GymColors.surface,
          borderRadius: GymRadius.mdRadius,
          boxShadow: GymShadows.sm,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: GymRadius.mdRadius,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: GymColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: GymColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// OCCUPANCY INDICATOR - Indicador de ocupación
// ============================================================================
class OccupancyIndicator extends StatelessWidget {
  final double percentage;
  final String? label;
  final bool showPercentage;
  final double height;

  const OccupancyIndicator({
    super.key,
    required this.percentage,
    this.label,
    this.showPercentage = true,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final color = GymColors.getOccupancyColor(percentage);
    final percentInt = (percentage * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GymColors.textSecondary,
                  ),
                ),
                if (showPercentage)
                  Text(
                    '$percentInt%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
        Stack(
          children: [
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: GymColors.divider,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            AnimatedContainer(
              duration: GymDurations.slow,
              curve: GymCurves.standard,
              height: height,
              width: double.infinity,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage.clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// GYM APP BAR - AppBar personalizado
// ============================================================================
class GymAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showNotification;
  final int notificationCount;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final bool centerTitle;

  const GymAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showNotification = false,
    this.notificationCount = 0,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: GymTypography.headlineMedium,
          fontWeight: GymTypography.semiBold,
          color: GymColors.textPrimary,
        ),
      ),
      backgroundColor: backgroundColor ?? GymColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      leading: leading ??
          (showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: GymColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                )
              : null),
      actions: [
        ...?actions,
        if (showNotification)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: GymColors.textPrimary),
                onPressed: () {},
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: GymColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      notificationCount > 9 ? '9+' : '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ============================================================================
// GYM BOTTOM NAV - Navegación inferior
// ============================================================================
class GymBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GymBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GymColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Inicio'),
              _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_today, 'Clases'),
              _buildQRButton(),
              _buildNavItem(3, Icons.trending_up_outlined, Icons.trending_up, 'Progreso'),
              _buildNavItem(4, Icons.person_outline, Icons.person, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(index);
      },
      child: AnimatedContainer(
        duration: GymDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? GymColors.primary : GymColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? GymColors.primary : GymColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap(2);
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: GymColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: GymShadows.colored(GymColors.primary),
        ),
        child: const Icon(
          Icons.qr_code_scanner,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

// ============================================================================
// STAT CARD - Tarjeta de estadística
// ============================================================================
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final Widget? trailing;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GymCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? GymColors.primary).withValues(alpha: 0.1),
                    borderRadius: GymRadius.smRadius,
                  ),
                  child: Icon(icon, color: iconColor ?? GymColors.primary, size: 20),
                ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: valueColor ?? GymColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: GymColors.textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                color: GymColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// LIST TILE CARD - Elemento de lista con estilo de tarjeta
// ============================================================================
class GymListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const GymListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: GymSpacing.listItemPadding,
        decoration: BoxDecoration(
          color: backgroundColor ?? GymColors.surface,
          borderRadius: GymRadius.mdRadius,
          boxShadow: GymShadows.sm,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: GymColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: GymColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              const Icon(Icons.chevron_right, color: GymColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION HEADER - Encabezado de sección
// ============================================================================
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: GymTypography.headlineSmall,
              fontWeight: GymTypography.semiBold,
              color: GymColors.textPrimary,
            ),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: GymColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// AVATAR WITH BADGE - Avatar con badge de estado
// ============================================================================
class AvatarWithBadge extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final Color? badgeColor;
  final bool showBadge;

  const AvatarWithBadge({
    super.key,
    this.imageUrl,
    required this.initials,
    this.size = 48,
    this.badgeColor,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: GymColors.primaryGradient,
            shape: BoxShape.circle,
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null
              ? Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        ),
        if (showBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: badgeColor ?? GymColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// EMPTY STATE - Estado vacío
// ============================================================================
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: GymColors.divider.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: GymColors.textHint),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: GymColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: GymColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              GymButton(
                text: actionText!,
                onPressed: onAction,
                style: GymButtonStyle.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// LOADING OVERLAY - Overlay de carga
// ============================================================================
class GymLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const GymLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black38,
            child: Center(
              child: GymCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(GymColors.primary),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: const TextStyle(
                          color: GymColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
