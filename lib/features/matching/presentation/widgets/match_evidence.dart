import 'package:flutter/material.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/app_motion.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../domain/entities/object_match.dart';
import '../constants/match_labels.dart';
import 'evidence_metric.dart';
import 'match_tones.dart';

class MatchEvidence extends StatelessWidget {
  const MatchEvidence({required this.match, super.key});
  final ObjectMatch match;
  @override
  Widget build(BuildContext context) => ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: const Text(AppStrings.evidenceFactors),
          subtitle: const Text(AppStrings.pointsLegend),
          children: [
            for (final group in MatchFactorGroup.values)
              Padding(
                  padding: const EdgeInsets.only(top: AppSizes.spacingLarge),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EvidenceMetric(
                            label: group == MatchFactorGroup.identity
                                ? AppStrings.identityEvidence
                                : AppStrings.contextEvidence,
                            value: group == MatchFactorGroup.identity
                                ? match.identityPercentage
                                : match.contextPercentage),
                        const SizedBox(height: AppSizes.spacingMedium),
                        for (final factor in match.factors
                            .where((factor) => factor.group == group))
                          FactorEvidence(factor: factor),
                      ])),
          ]);
}

class FactorEvidence extends StatelessWidget {
  const FactorEvidence({required this.factor, super.key});
  final MatchFactor factor;
  @override
  Widget build(BuildContext context) {
    final tone = factorTone(context, factor.status);
    // Normalize a server-supplied factor solely for drawing its bar.
    final fraction = factor.evaluableWeight > 0
        ? factor.score / factor.evaluableWeight
        : 0.0;
    return Padding(
        key: ValueKey('factor-${factor.name}'),
        padding: const EdgeInsets.only(bottom: AppSizes.spacingLarge),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSizes.spacingSmall,
              runSpacing: AppSizes.spacingSmall,
              children: [
                Text(factor.label,
                    style: Theme.of(context).textTheme.titleSmall),
                StatusPill(
                    label: factor.status.label,
                    icon: factorIcon(factor.status),
                    tone: tone),
              ]),
          const SizedBox(height: AppSizes.spacingSmall),
          Semantics(
              label:
                  '${factor.label}: ${factor.status.label}. ${AppStrings.factorPoints(factor.score, factor.evaluableWeight)}',
              child: ExcludeSemantics(
                  child: TweenAnimationBuilder<double>(
                      tween: Tween(
                          begin: AppMotion.reduced(context) ? fraction : 0,
                          end: fraction),
                      duration:
                          AppMotion.duration(context, AppDurations.scoreReveal),
                      curve: Curves.easeOutCubic,
                      builder: (context, progress, _) => ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSmall),
                          child: LinearProgressIndicator(
                              value: progress,
                              color: tone.foreground,
                              minHeight: AppSizes.progressHeight))))),
          const SizedBox(height: AppSizes.spacingSmall),
          Text(AppStrings.factorPoints(factor.score, factor.evaluableWeight),
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSizes.spacingTiny),
          Text(factor.explanation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]));
  }
}
