import 'report_photo.dart';
import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/object_report.dart';
import '../constants/report_labels.dart';

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
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ReportPhoto(
                    image: report.image,
                    height: AppSizes.reportPhotoThumbnail,
                    thumbnail: true),
                const SizedBox(width: AppSizes.spacingRegular),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(report.objectType,
                          style: Theme.of(context).textTheme.titleMedium),
                      Wrap(spacing: AppSizes.spacingSmall, children: [
                        Chip(label: Text(report.reportType.label)),
                        Chip(label: Text(report.status.label)),
                      ]),
                      Text(report.category),
                      Text(report.description,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppSizes.spacingSmall),
                      Text([
                        report.primaryColor ?? AppStrings.notAvailable,
                        ...report.secondaryColors
                      ].join(' · ')),
                      Text(report.location),
                      Text(formatDate(report.eventDate)),
                    ])),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ]))));
}
