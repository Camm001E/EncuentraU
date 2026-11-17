import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppGradients {
  static const welcome = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.greenSurface,
        AppColors.background,
        AppColors.peachSurface
      ],
      stops: [
        0,
        .62,
        1
      ]);
  static const brand = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primary, Color(0xFF258F7E)]);
  static const comparison = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.greenSurface, AppColors.lavenderSurface]);
}
