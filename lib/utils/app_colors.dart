import 'package:flutter/material.dart';

class AppColors {
  // Banner greens
  static const Color bannerGreen1 = Color(0xFF008080);
  static const Color bannerGreen2 = Color(0xFF006D6D);

  // Unified primary green palette
  static const Color primaryGreen = Color(0xFF768E7F); // Tailwind green-600
  static const Color accentGreen = Color(0xFFD9F3E4); // Tailwind green-400 (lighter)
  static const Color background = Color(0xFFFFFFFF);

  // Helpers to produce translucent variants
  static Color primaryGreenWithOpacity(double o) => Color.fromRGBO(22, 163, 74, o);
  static Color accentGreenWithOpacity(double o) => Color.fromRGBO(74, 222, 128, o);
}
