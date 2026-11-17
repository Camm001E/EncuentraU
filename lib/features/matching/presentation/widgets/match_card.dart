import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../objects/presentation/widgets/report_photo.dart';
import '../../domain/entities/object_match.dart';
import '../constants/match_labels.dart';
import 'evidence_metric.dart';
import 'match_detail_content.dart';
import 'match_tones.dart';

class MatchCard extends StatelessWidget {
  const MatchCard(
      {required this.match,
      this.detail = false,
      this.visualReview,
      this.onReturn,
      super.key});
  final ObjectMatch match;
  final bool detail;
  final Widget? visualReview;
  final VoidCallback? onReturn;
  @override
  Widget build(BuildContext context) {
    if (detail)
      return MatchDetailContent(match: match, visualReview: visualReview);
    final tone = matchTone(context, match.level);
    return Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.spacingLarge),
        child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                      padding: const EdgeInsets.all(AppSizes.spacingSmall),
                      child: ReportPhoto(
                          image: match.candidateReport.image,
                          height: AppSizes.matchPhotoHeight,
                          label: AppStrings.candidatePhotoLabel)),
                  if (visualReview != null)
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spacingMedium),
                        child: visualReview),
                  Padding(
                      padding: const EdgeInsets.all(AppSizes.spacingMedium),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                                spacing: AppSizes.spacingSmall,
                                runSpacing: AppSizes.spacingSmall,
                                alignment: WrapAlignment.spaceBetween,
                                children: [
                                  StatusPill(
                                      label: match.level.label,
                                      icon: match.compatible
                                          ? Icons.join_inner_rounded
                                          : Icons.link_off_rounded,
                                      tone: tone),
                                  Text('${match.percentage}/100',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(color: tone.foreground)),
                                ]),
                            const SizedBox(height: AppSizes.spacingMedium),
                            Text('Tu reporte: ${match.myReport.objectType}'),
                            const Text('Coincide con este reporte:'),
                            Text(match.candidateReport.objectType,
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: AppSizes.spacingTiny),
                            Text(AppStrings.estimatedCompatibility,
                                style: Theme.of(context).textTheme.labelMedium),
                            const Text(
                                'Puntaje de búsqueda, no certeza visual.'),
                            const SizedBox(height: AppSizes.spacingRegular),
                            Wrap(
                                spacing: AppSizes.spacingSmall,
                                runSpacing: AppSizes.spacingSmall,
                                children: [
                                  Text(match.status.label),
                                  Text(match.compatible
                                      ? AppStrings.compatible
                                      : AppStrings.incompatible),
                                ]),
                            const SizedBox(height: AppSizes.spacingRegular),
                            Row(children: [
                              const Icon(Icons.place_outlined,
                                  size: AppSizes.iconSmall),
                              const SizedBox(width: AppSizes.spacingSmall),
                              Expanded(
                                  child: Text(match.candidateReport.location))
                            ]),
                            const SizedBox(height: AppSizes.spacingTiny),
                            Text(formatDate(match.candidateReport.eventDate),
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                            const SizedBox(height: AppSizes.spacingMedium),
                            EvidenceMetric(
                                label: AppStrings.evidenceCoverage,
                                value: match.evidenceCoverage,
                                color: tone.foreground),
                            const SizedBox(height: AppSizes.spacingLarge),
                            SecondaryAction(
                                label: AppStrings.openMatch,
                                onPressed: () async {
                                  await Navigator.pushNamed(
                                      context, AppRoutes.matchDetail,
                                      arguments: match.id);
                                  onReturn?.call();
                                }),
                          ])),
                ])));
  }
}
