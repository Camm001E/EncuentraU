import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

@immutable
class SemanticTone {
  const SemanticTone(this.foreground, this.background, this.accent);
  final Color foreground, background, accent;
  static SemanticTone lerp(SemanticTone a, SemanticTone b, double t) =>
      SemanticTone(
          Color.lerp(a.foreground, b.foreground, t)!,
          Color.lerp(a.background, b.background, t)!,
          Color.lerp(a.accent, b.accent, t)!);
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors(
      {required this.lost,
      required this.found,
      required this.high,
      required this.possible,
      required this.low,
      required this.information,
      required this.warning,
      required this.success,
      required this.error});
  final SemanticTone lost,
      found,
      high,
      possible,
      low,
      information,
      warning,
      success,
      error;
  static const light = AppSemanticColors(
    lost: SemanticTone(
        AppColors.textPrimary, AppColors.lostBackground, AppColors.lost),
    found: SemanticTone(
        AppColors.primary, AppColors.foundBackground, AppColors.found),
    high:
        SemanticTone(AppColors.primary, AppColors.greenSurface, AppColors.high),
    possible: SemanticTone(
        AppColors.textPrimary, AppColors.peachSurface, AppColors.possible),
    low: SemanticTone(
        AppColors.textPrimary, AppColors.background, AppColors.low),
    information: SemanticTone(
        AppColors.textPrimary, AppColors.lavenderSurface, AppColors.lavender),
    warning: SemanticTone(
        AppColors.textPrimary, AppColors.peachSurface, AppColors.amber),
    success: SemanticTone(
        AppColors.primary, AppColors.greenSurface, AppColors.found),
    error: SemanticTone(
        AppColors.textPrimary, AppColors.errorBackground, AppColors.error),
  );
  static AppSemanticColors of(BuildContext context) =>
      Theme.of(context).extension<AppSemanticColors>() ?? light;
  @override
  AppSemanticColors copyWith(
          {SemanticTone? lost,
          SemanticTone? found,
          SemanticTone? high,
          SemanticTone? possible,
          SemanticTone? low,
          SemanticTone? information,
          SemanticTone? warning,
          SemanticTone? success,
          SemanticTone? error}) =>
      AppSemanticColors(
          lost: lost ?? this.lost,
          found: found ?? this.found,
          high: high ?? this.high,
          possible: possible ?? this.possible,
          low: low ?? this.low,
          information: information ?? this.information,
          warning: warning ?? this.warning,
          success: success ?? this.success,
          error: error ?? this.error);
  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) =>
      other == null
          ? this
          : AppSemanticColors(
              lost: SemanticTone.lerp(lost, other.lost, t),
              found: SemanticTone.lerp(found, other.found, t),
              high: SemanticTone.lerp(high, other.high, t),
              possible: SemanticTone.lerp(possible, other.possible, t),
              low: SemanticTone.lerp(low, other.low, t),
              information: SemanticTone.lerp(information, other.information, t),
              warning: SemanticTone.lerp(warning, other.warning, t),
              success: SemanticTone.lerp(success, other.success, t),
              error: SemanticTone.lerp(error, other.error, t));
}
