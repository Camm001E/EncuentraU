import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/object_report.dart';
import 'report_photo.dart';
import 'report_badges.dart';

class ObjectReportCard extends StatelessWidget {
  const ObjectReportCard(
      {required this.report, this.compact = false, super.key});
  final ObjectReport report;
  final bool compact;
  @override
  Widget build(BuildContext context) => Card(
      child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          onTap: () => Navigator.pushNamed(context, AppRoutes.reportDetail,
              arguments: report.id),
          child: Padding(
              padding: const EdgeInsets.all(AppSizes.spacingMedium),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReportPhoto(
                              image: report.image,
                              height: AppSizes.reportCardPhoto,
                              thumbnail: true),
                          const SizedBox(width: AppSizes.spacingMedium),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(report.objectType,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: AppSizes.spacingTiny),
                                Text(report.category,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant)),
                                const SizedBox(height: AppSizes.spacingSmall),
                                Text([
                                  report.primaryColor ??
                                      AppStrings.notAvailable,
                                  ...report.secondaryColors
                                ].join(' · ')),
                              ])),
                          const Icon(Icons.arrow_outward_rounded,
                              size: AppSizes.iconSmall),
                        ]),
                    const SizedBox(height: AppSizes.spacingRegular),
                    Wrap(
                        spacing: AppSizes.spacingSmall,
                        runSpacing: AppSizes.spacingSmall,
                        children: [
                          ReportTypeBadge(report.reportType),
                          ReportStatusBadge(report.status)
                        ]),
                    if (!compact) ...[
                      const SizedBox(height: AppSizes.spacingRegular),
                      Text(report.description,
                          maxLines: 2, overflow: TextOverflow.ellipsis)
                    ],
                    const SizedBox(height: AppSizes.spacingRegular),
                    Row(children: [
                      Icon(Icons.place_outlined,
                          size: AppSizes.iconSmall,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppSizes.spacingTiny),
                      Expanded(child: Text(report.location))
                    ]),
                    const SizedBox(height: AppSizes.spacingTiny),
                    Row(children: [
                      Icon(Icons.calendar_today_outlined,
                          size: AppSizes.iconSmall,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppSizes.spacingTiny),
                      Expanded(child: Text(formatDate(report.eventDate)))
                    ]),
                  ]))));
}
