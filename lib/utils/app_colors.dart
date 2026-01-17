import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryViolet = Color(0xFF7C3AED);
  static const Color accentViolet = Color(0xFF7C4DFF);
  static const Color bannerGreen1 = Color(0xFF008080);
  static const Color bannerGreen2 = Color(0xFF006D6D);
  static const Color background = Color(0xFFF9FAFB);

  static Color primaryVioletWithOpacity(double o) => Color.fromRGBO(124, 58, 237, o);
  static Color accentVioletWithOpacity(double o) => Color.fromRGBO(124, 77, 255, o);
}
