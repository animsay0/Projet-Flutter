import 'package:flutter/material.dart';

class AppColors {
  // Banner greens (existing)
  static const Color bannerGreen1 = Color(0xFF008080);
  static const Color bannerGreen2 = Color(0xFF006D6D);

  // Unified primary green palette (use a lighter, friendly green for accents)
  static const Color primaryGreen = Color(0xFF16A34A); // Tailwind green-600
  static const Color accentGreen = Color(0xFF4ADE80); // Tailwind green-400 (lighter)
  static const Color background = Color(0xFFF9FAFB);

  // Helpers to produce translucent variants (avoid deprecated withOpacity)
  static Color primaryGreenWithOpacity(double o) => Color.fromRGBO(22, 163, 74, o);
  static Color accentGreenWithOpacity(double o) => Color.fromRGBO(74, 222, 128, o);
}
