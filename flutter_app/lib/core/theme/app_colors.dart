import 'package:flutter/material.dart';

class AppColors {
  // Light background tones
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgCanvas = Color(0xFFF1F5F9);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgSurfaceSecondary = Color(0xFFF8FAFC);

  // Legacy aliases for backward compatibility
  static const Color bgDarkNavy = Color(0xFFF8FAFC);
  static const Color bgDeepBlue = Color(0xFFFFFFFF);
  static const Color bgSapphire = Color(0xFFEEF2F6);
  static const Color bgVioletDark = Color(0xFFE2E8F0);

  // Gradient definitions (light, clean, modern)
  static const LinearGradient mainBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8FAFC),
      Color(0xFFF1F5F9),
      Color(0xFFEEF2F6),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FAFC),
    ],
  );

  static const LinearGradient accentButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4F46E5),
      Color(0xFF6366F1),
    ],
  );

  // Surfaces & borders for white-based UI
  static const Color glassSurface = Color(0xFFFFFFFF);
  static const Color glassSurfaceHover = Color(0xFFF8FAFC);
  static const Color glassBorder = Color(0xFFE2E8F0);
  static const Color glassBorderStrong = Color(0xFFCBD5E1);
  static const Color glassHighlight = Color(0xFFFFFFFF);

  // Status colors with high contrast for white background
  static const Color presentEmerald = Color(0xFF059669);
  static const Color presentEmeraldLight = Color(0xFF10B981);
  static const Color presentBg = Color(0xFFECFDF5);
  static const Color presentBorder = Color(0xFFA7F3D0);
  static const Color presentGlow = Color(0x2210B981);

  static const Color absentRose = Color(0xFFDC2626);
  static const Color absentRoseLight = Color(0xFFEF4444);
  static const Color absentBg = Color(0xFFFEF2F2);
  static const Color absentBorder = Color(0xFFFECACA);
  static const Color absentGlow = Color(0x22EF4444);

  static const Color morningAmber = Color(0xFFD97706);
  static const Color morningAmberLight = Color(0xFFF59E0B);
  static const Color morningAmberBg = Color(0xFFFFFBEB);
  static const Color morningAmberBorder = Color(0xFFFDE68A);
  static const Color morningAmberGlow = Color(0x22D97706);

  static const Color nightViolet = Color(0xFF7C3AED);
  static const Color nightVioletLight = Color(0xFF8B5CF6);
  static const Color nightVioletBg = Color(0xFFF5F3FF);
  static const Color nightVioletBorder = Color(0xFFDDD6FE);
  static const Color nightVioletGlow = Color(0x227C3AED);

  // Neutral text & icons for crisp white background
  static const Color textPrimary = Color(0xFF0F172A); // Deep slate
  static const Color textSecondary = Color(0xFF334155); // Slate
  static const Color textMuted = Color(0xFF64748B); // Cool gray
  static const Color textSubtle = Color(0xFF94A3B8); // Light gray placeholder

  // Shadows
  static const BoxShadow glassShadow = BoxShadow(
    color: Color(0x0A0F172A),
    blurRadius: 14,
    spreadRadius: 0,
    offset: Offset(0, 4),
  );

  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x080F172A),
    blurRadius: 10,
    spreadRadius: 0,
    offset: Offset(0, 2),
  );

  static const BoxShadow softGlow = BoxShadow(
    color: Color(0x264F46E5),
    blurRadius: 16,
    spreadRadius: 1,
    offset: Offset(0, 3),
  );
}
