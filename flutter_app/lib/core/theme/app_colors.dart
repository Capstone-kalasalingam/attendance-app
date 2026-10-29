import 'package:flutter/material.dart';

class AppColors {
  // Background gradient tones
  static const Color bgDarkNavy = Color(0xFF090D1A);
  static const Color bgDeepBlue = Color(0xFF0F172A);
  static const Color bgSapphire = Color(0xFF1E1B4B);
  static const Color bgVioletDark = Color(0xFF2E1065);

  // Gradient definitions
  static const LinearGradient mainBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF080B16),
      Color(0xFF0F172A),
      Color(0xFF1E1B4B),
      Color(0xFF161538),
    ],
    stops: [0.0, 0.35, 0.75, 1.0],
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x28FFFFFF),
      Color(0x0AFFFFFF),
    ],
  );

  static const LinearGradient accentButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4F46E5),
      Color(0xFF7C3AED),
    ],
  );

  // Glassmorphic surfaces
  static const Color glassSurface = Color(0x18FFFFFF);
  static const Color glassSurfaceHover = Color(0x26FFFFFF);
  static const Color glassBorder = Color(0x24FFFFFF);
  static const Color glassBorderStrong = Color(0x40FFFFFF);
  static const Color glassHighlight = Color(0x55FFFFFF);

  // Status colors with high accessibility & contrast
  static const Color presentEmerald = Color(0xFF10B981);
  static const Color presentEmeraldLight = Color(0xFF34D399);
  static const Color presentGlow = Color(0x3310B981);

  static const Color absentRose = Color(0xFFF43F5E);
  static const Color absentRoseLight = Color(0xFFFB7185);
  static const Color absentGlow = Color(0x33F43F5E);

  static const Color morningAmber = Color(0xFFF59E0B);
  static const Color morningAmberGlow = Color(0x33F59E0B);

  static const Color nightViolet = Color(0xFFA855F7);
  static const Color nightVioletGlow = Color(0x33A855F7);

  // Neutral text & icons
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);

  // Shadows
  static const BoxShadow glassShadow = BoxShadow(
    color: Color(0x40000000),
    blurRadius: 20,
    spreadRadius: -2,
    offset: Offset(0, 8),
  );

  static const BoxShadow softGlow = BoxShadow(
    color: Color(0x1A4F46E5),
    blurRadius: 24,
    spreadRadius: 2,
  );
}
