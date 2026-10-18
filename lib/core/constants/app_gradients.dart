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
      ]);
  static const brand = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.sage, AppColors.greenSurface]);
  static const comparison = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.greenSurface, AppColors.lavenderSurface]);
}
