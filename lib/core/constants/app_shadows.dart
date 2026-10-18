import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppShadows {
  static final soft = <BoxShadow>[
    BoxShadow(
        color: AppColors.textPrimary.withValues(alpha: 0.06),
        blurRadius: 28,
        offset: const Offset(0, 8)),
  ];
}
