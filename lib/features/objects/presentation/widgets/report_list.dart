import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../controllers/object_controller.dart';
import 'object_report_card.dart';

class ReportList extends StatelessWidget {
  const ReportList({required this.controller, this.compact = false, super.key});
  final ObjectController controller;
  final bool compact;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (controller.status == LoadStatus.loading) const LoadingSkeleton(),
        if (controller.status == LoadStatus.error)
          LoadFeedback(
              message: controller.message ?? AppStrings.unexpectedError,
              onRetry: () => controller.refresh()),
        if (controller.status == LoadStatus.empty)
          const LoadFeedback(message: AppStrings.noReports),
        if (controller.status != LoadStatus.loading)
          ...(compact
                  ? controller.items.take(AppSizes.homeRecentReports)
                  : controller.items)
              .map((report) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSizes.spacingMedium),
                  child: ObjectReportCard(report: report, compact: compact))),
        if (controller.hasMore && !compact)
          Padding(
              padding: const EdgeInsets.all(AppSizes.spacingRegular),
              child: OutlinedButton(
                  onPressed: controller.isLoadingMore
                      ? null
                      : () => controller.loadMore(),
                  child: controller.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const Text(AppStrings.loadMore))),
      ]);
}
