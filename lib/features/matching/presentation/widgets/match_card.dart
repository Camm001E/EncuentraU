import '../../../objects/presentation/widgets/report_photo.dart';
import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../objects/presentation/constants/report_labels.dart';
import '../../domain/entities/object_match.dart';
import '../constants/match_labels.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({required this.match, this.detail = false, super.key});
  final ObjectMatch match;
  final bool detail;
  @override
  Widget build(BuildContext context) {
    final color = switch (match.level) {
      MatchLevel.high => AppColors.success,
      MatchLevel.possible => AppColors.warning,
      MatchLevel.low => AppColors.textSecondary
    };
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacingMedium),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(match.level.label,
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w800)),
                      subtitle: Text(match.candidateReport.objectType),
                      trailing: Text(AppStrings.percentage(match.percentage),
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w800)),
                      onTap: detail
                          ? null
                          : () => Navigator.pushNamed(
                              context, AppRoutes.matchDetail,
                              arguments: match.id)),
                  if (detail)
                    _PhotoComparison(match: match)
                  else
                    ReportPhoto(
                        image: match.candidateReport.image,
                        height: AppSizes.matchPhotoHeight),
                  const SizedBox(height: AppSizes.spacingMedium),
                  Text(match.status.label),
                  Text(match.compatible
                      ? AppStrings.compatible
                      : AppStrings.incompatible),
                  const SizedBox(height: AppSizes.spacingRegular),
                  for (final metric in [
                    (AppStrings.identity, match.identityPercentage),
                    (AppStrings.context, match.contextPercentage),
                    (AppStrings.evidenceCoverage, match.evidenceCoverage),
                  ]) ...[
                    Text('${metric.$1}: ${AppStrings.percentage(metric.$2)}'),
                    LinearProgressIndicator(
                        value: metric.$2 / ApiConstants.maxPercentage,
                        color: color,
                        backgroundColor: AppColors.border,
                        minHeight: AppSizes.progressHeight),
                    const SizedBox(height: AppSizes.spacingSmall),
                  ],
                  _Summary(label: AppStrings.myReport, report: match.myReport),
                  const Divider(),
                  _Summary(
                      label: AppStrings.candidateReport,
                      report: match.candidateReport),
                  ExpansionTile(
                      title: const Text(AppStrings.evidenceFactors),
                      children: match.factors
                          .map((factor) => ListTile(
                                title: Text(
                                    '${factor.label} · ${factor.status.label}'),
                                subtitle: Text(
                                    '${factor.group.label}: ${factor.explanation}'),
                                trailing: Text(AppStrings.factorPoints(
                                    factor.score, factor.evaluableWeight)),
                              ))
                          .toList()),
                  if (match.warnings.isNotEmpty) ...[
                    const Text(AppStrings.warnings),
                    ...match.warnings.map((warning) => Text(warning))
                  ],
                  if (detail) ...[
                    Text(
                        '${AppStrings.createdAtLabel}: ${formatDate(match.createdAt)}'),
                    Text(
                        '${AppStrings.updatedAtLabel}: ${formatDate(match.updatedAt)}')
                  ],
                ])));
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.report});
  final String label;
  final MatchReportSummary report;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.primary)),
        Text('${report.reportType.label} · ${report.status.label}'),
        Text(report.objectType),
        Text(report.category),
        Text([
          report.primaryColor ?? AppStrings.notAvailable,
          ...report.secondaryColors
        ].join(' · ')),
        if (report.brand != null) Text(report.brand!),
        if (report.shape != null) Text(report.shape!),
        Text(report.description),
        Text(report.location),
        Text(formatDate(report.eventDate)),
      ]);
}

class _PhotoComparison extends StatelessWidget {
  const _PhotoComparison({required this.match});
  final ObjectMatch match;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final photos = [
          Column(children: [
            const Text(AppStrings.myReport),
            ReportPhoto(image: match.myReport.image)
          ]),
          Column(children: [
            const Text(AppStrings.candidateReport),
            ReportPhoto(image: match.candidateReport.image)
          ]),
        ];
        return constraints.maxWidth >= AppSizes.photoComparisonBreakpoint
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: photos[0]),
                const SizedBox(width: AppSizes.spacingMedium),
                Expanded(child: photos[1])
              ])
            : Column(children: [
                photos[0],
                const SizedBox(height: AppSizes.spacingMedium),
                photos[1]
              ]);
      });
}
