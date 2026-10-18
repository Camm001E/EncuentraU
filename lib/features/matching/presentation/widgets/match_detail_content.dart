import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/object_match.dart';
import '../constants/match_labels.dart';
import 'score_ring.dart';
import 'evidence_metric.dart';
import 'match_comparison_scene.dart';
import 'match_evidence.dart';
import 'match_tones.dart';

class MatchDetailContent extends StatefulWidget {
  const MatchDetailContent({required this.match, super.key});
  final ObjectMatch match;
  @override
  State<MatchDetailContent> createState() => _MatchDetailContentState();
}

class _MatchDetailContentState extends State<MatchDetailContent> {
  final _scoreKey = GlobalKey();
  ObjectMatch get match => widget.match;
  @override
  Widget build(BuildContext context) {
    final tone = matchTone(context, match.level);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionHeading(
          title: AppStrings.comparisonTitle,
          eyebrow: AppStrings.comparisonEyebrow),
      MatchComparisonScene(key: ValueKey('photos-${match.id}'), match: match),
      const SizedBox(height: AppSizes.spacingXLarge),
      LayoutBuilder(builder: (context, constraints) {
        final score = Column(mainAxisSize: MainAxisSize.min, children: [
          ScoreRing(
              key: _scoreKey,
              percentage: match.percentage,
              color: tone.foreground),
          const SizedBox(height: AppSizes.spacingMedium),
          Text(AppStrings.estimatedCompatibility,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center),
        ]);
        final summary =
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(
              spacing: AppSizes.spacingSmall,
              runSpacing: AppSizes.spacingSmall,
              children: [
                StatusPill(
                    label: match.level.label,
                    icon: match.compatible
                        ? Icons.verified_outlined
                        : Icons.link_off_rounded,
                    tone: tone),
                StatusPill(
                    label: match.status.label,
                    icon: Icons.schedule_rounded,
                    tone: AppSemanticColors.of(context).information),
              ]),
          const SizedBox(height: AppSizes.spacingMedium),
          Text(match.compatible
              ? AppStrings.compatible
              : AppStrings.incompatible),
          const SizedBox(height: AppSizes.spacingLarge),
          EvidenceMetric(
              label: AppStrings.evidenceCoverage,
              value: match.evidenceCoverage),
          const SizedBox(height: AppSizes.spacingLarge),
          const InformationPanel(
              icon: Icons.shield_outlined,
              child: Text(AppStrings.ownershipNotice)),
        ]);
        return constraints.maxWidth >= AppSizes.photoComparisonBreakpoint &&
                MediaQuery.textScalerOf(context).scale(1) <=
                    AppSizes.textScaleNavigationCutoff
            ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                score,
                const SizedBox(width: AppSizes.spacingXLarge),
                Expanded(child: summary)
              ])
            : Column(children: [
                score,
                const SizedBox(height: AppSizes.spacingLarge),
                summary
              ]);
      }),
      const SizedBox(height: AppSizes.spacingXLarge),
      MatchEvidence(match: match),
      if (match.warnings.isNotEmpty) ...[
        const SizedBox(height: AppSizes.spacingLarge),
        InformationPanel(
            tone: AppSemanticColors.of(context).warning,
            icon: Icons.info_outline,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppStrings.warnings,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSizes.spacingSmall),
              const Text(AppStrings.warningHelp),
              for (final warning in match.warnings)
                Padding(
                    padding:
                        const EdgeInsets.only(top: AppSizes.spacingRegular),
                    child: Text(warning)),
            ])),
      ],
      const SizedBox(height: AppSizes.spacingXLarge),
      _ReportSummary(label: AppStrings.myReport, report: match.myReport),
      const Divider(height: AppSizes.spacingXLarge),
      _ReportSummary(
          label: AppStrings.candidatePhotoLabel, report: match.candidateReport),
      const SizedBox(height: AppSizes.spacingLarge),
      Text('${AppStrings.updatedAtLabel}: ${formatDate(match.updatedAt)}',
          style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: AppSizes.spacingLarge),
    ]);
  }
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.label, required this.report});
  final String label;
  final MatchReportSummary report;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: AppSizes.spacingSmall),
        Text(report.objectType, style: Theme.of(context).textTheme.titleMedium),
        Text(report.description),
        const SizedBox(height: AppSizes.spacingSmall),
        Text([
          report.category,
          report.primaryColor ?? AppStrings.notAvailable,
          ...report.secondaryColors,
          if (report.brand != null) report.brand!
        ].join(' · ')),
        Text(report.location),
        Text(formatDate(report.eventDate)),
      ]);
}
