import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/app_motion.dart';

/// Only the visual stroke is interpolated. The announced value is the API value.
class ScoreRing extends StatelessWidget {
  const ScoreRing({required this.percentage, this.color, super.key});
  final int percentage;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final scheme = Theme.of(context).colorScheme;
    final enlarged = MediaQuery.textScalerOf(context).scale(1) >
        AppSizes.textScaleNavigationCutoff;
    final value = Text(AppStrings.percentage(percentage),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: AppSizes.scoreSize, fontWeight: FontWeight.w800));
    return Semantics(
        label: AppStrings.scoreSemantics(percentage),
        image: true,
        child: ExcludeSemantics(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          RepaintBoundary(
              child: TweenAnimationBuilder<double>(
                  tween: Tween(
                      begin: reduced ? percentage.toDouble() : 0,
                      end: percentage.toDouble()),
                  duration:
                      AppMotion.duration(context, AppDurations.scoreReveal),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, child) => CustomPaint(
                      painter: ScoreRingPainter(
                          progress: progress / ApiConstants.maxPercentage,
                          foreground: color ?? scheme.primary,
                          track: scheme.outlineVariant),
                      child: SizedBox.square(
                          dimension: AppSizes.ringSize,
                          child: Center(child: child))),
                  child: enlarged
                      ? Icon(Icons.join_inner_rounded,
                          size: AppSizes.iconLarge, color: scheme.primary)
                      : value)),
          if (enlarged)
            Padding(
                padding: const EdgeInsets.only(top: AppSizes.spacingSmall),
                child: value),
        ])));
  }
}

class ScoreRingPainter extends CustomPainter {
  const ScoreRingPainter(
      {required this.progress, required this.foreground, required this.track});
  final double progress;
  final Color foreground, track;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bounds = rect.deflate(AppSizes.ringStroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.ringStroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(bounds, 0, 2 * math.pi, false, paint..color = track);
    if (progress > 0)
      canvas.drawArc(bounds, -math.pi / 2, 2 * math.pi * progress, false,
          paint..color = foreground);
  }

  @override
  bool shouldRepaint(ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.foreground != foreground ||
      oldDelegate.track != track;
}
