import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/app_motion.dart';

class EvidenceMetric extends StatelessWidget {
  const EvidenceMetric(
      {required this.label, required this.value, this.color, super.key});
  final String label;
  final double value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Semantics(
      label: '$label: ${AppStrings.percentage(value)}',
      child: ExcludeSemantics(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label: ${AppStrings.percentage(value)}',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSizes.spacingSmall),
        TweenAnimationBuilder<double>(
            tween: Tween(
                begin: AppMotion.reduced(context) ? value : 0, end: value),
            duration: AppMotion.duration(context, AppDurations.scoreReveal),
            curve: Curves.easeOutCubic,
            builder: (context, progress, _) => ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                child: LinearProgressIndicator(
                    value: progress / ApiConstants.maxPercentage,
                    minHeight: AppSizes.progressHeight,
                    color: color ?? Theme.of(context).colorScheme.primary))),
      ])));
}
