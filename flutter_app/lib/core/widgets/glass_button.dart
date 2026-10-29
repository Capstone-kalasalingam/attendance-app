import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'glass_panel.dart';

enum GlassButtonVariant { primary, secondary, success, danger, ghost }

class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final GlassButtonVariant variant;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = GlassButtonVariant.primary,
    this.width,
    this.height = 44,
    this.borderRadius = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Color surfaceColor;
    Color borderColor;
    Color textColor;
    Gradient? gradient;

    switch (variant) {
      case GlassButtonVariant.primary:
        gradient = AppColors.accentButtonGradient;
        surfaceColor = const Color(0xFF4F46E5);
        borderColor = const Color(0xFF4F46E5);
        textColor = Colors.white;
        break;
      case GlassButtonVariant.secondary:
        surfaceColor = Colors.white;
        borderColor = AppColors.glassBorderStrong;
        textColor = AppColors.textPrimary;
        break;
      case GlassButtonVariant.success:
        surfaceColor = AppColors.presentBg;
        borderColor = AppColors.presentBorder;
        textColor = AppColors.presentEmerald;
        break;
      case GlassButtonVariant.danger:
        surfaceColor = AppColors.absentBg;
        borderColor = AppColors.absentBorder;
        textColor = AppColors.absentRose;
        break;
      case GlassButtonVariant.ghost:
        surfaceColor = Colors.transparent;
        borderColor = Colors.transparent;
        textColor = AppColors.textSecondary;
        break;
    }

    final isEnabled = onPressed != null && !isLoading;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: GlassPanel(
        width: width,
        height: height,
        borderRadius: borderRadius,
        surfaceColor: gradient == null ? surfaceColor : null,
        gradient: gradient,
        borderColor: borderColor,
        shadows: variant == GlassButtonVariant.primary
            ? const [AppColors.softGlow]
            : const [AppColors.cardShadow],
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        onTap: isEnabled ? onPressed : null,
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      variant == GlassButtonVariant.primary ? Colors.white : const Color(0xFF4F46E5),
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: textColor),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
