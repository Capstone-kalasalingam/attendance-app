import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? surfaceColor;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 12,
    this.surfaceColor,
    this.borderColor,
    this.borderWidth = 1,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.shadows,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor ?? Colors.white,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: borderWidth,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: content,
        ),
      );
    }

    Widget glass = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );

    glass = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ?? const [AppColors.cardShadow],
      ),
      child: glass,
    );

    return glass;
  }
}
