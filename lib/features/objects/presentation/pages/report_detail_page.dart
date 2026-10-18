import '../widgets/report_photo.dart';
import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../matching/presentation/controllers/match_controller.dart';
import '../../domain/entities/object_report.dart';
import '../widgets/report_badges.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../controllers/object_controller.dart';

class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage(
      {required this.reportId,
      required this.controller,
      required this.matchController,
      super.key});
  final String reportId;
  final ObjectController controller;
  final MatchController matchController;
  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  late final Listenable _changes;
  @override
  void initState() {
    super.initState();
    _changes = Listenable.merge([widget.controller, widget.matchController]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.loadDetail(widget.reportId);
    });
  }

  void message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> cancel() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: const Text(AppStrings.cancelReport),
                content: const Text(AppStrings.cancelConfirmation),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text(AppStrings.dismiss)),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text(AppStrings.confirm)),
                ]));
    if (!mounted || confirmed != true) return;
    final success = await widget.controller.cancel(widget.reportId);
    if (mounted)
      message(success
          ? AppStrings.reportCancelled
          : widget.controller.actionMessage ?? AppStrings.unexpectedError);
  }

  Future<void> generate() async {
    final result = await widget.matchController.generate(widget.reportId);
    if (!mounted) return;
    if (result == null) {
      message(widget.matchController.generationMessage ??
          AppStrings.unexpectedError);
      return;
    }
    widget.matchController.resetFilters();
    Navigator.pushNamed(context, AppRoutes.matches);
    message(AppStrings.generatedCount(result.items.length));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text(AppStrings.reportDetail)),
      body: AnimatedBuilder(
          animation: _changes,
          builder: (context, _) {
            final controller = widget.controller;
            if (controller.detailStatus == LoadStatus.loading ||
                controller.detailStatus == LoadStatus.initial)
              return const ContentWidth(
                  child: Padding(
                      padding: EdgeInsets.all(AppSizes.spacingLarge),
                      child: LoadingSkeleton()));
            if (controller.detailStatus == LoadStatus.error)
              return ContentWidth(
                  child: LoadFeedback(
                      message: controller.detailMessage ??
                          AppStrings.unexpectedError,
                      onRetry: () => controller.loadDetail(widget.reportId)));
            final report = controller.detail;
            if (report == null || report.id != widget.reportId)
              return const LoadFeedback(message: AppStrings.apiNotFound);
            final active = report.status == ReportStatus.active;
            final editable = active && !report.evidenceLocked;
            final busy = controller.isCancelling ||
                controller.isUpdating ||
                widget.matchController.isGenerating;
            return ContentWidth(
                maxWidth: AppSizes.detailMaxWidth,
                child: RefreshIndicator(
                    onRefresh: () => controller.loadDetail(widget.reportId),
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSizes.spacingLarge),
                        children: [
                          ReportPhoto(
                              image: report.image,
                              fit: BoxFit.contain,
                              height: AppSizes.comparisonPhotoHeight),
                          const SizedBox(height: AppSizes.spacingLarge),
                          Wrap(
                              spacing: AppSizes.spacingSmall,
                              runSpacing: AppSizes.spacingSmall,
                              children: [
                                ReportTypeBadge(report.reportType),
                                ReportStatusBadge(report.status)
                              ]),
                          const SizedBox(height: AppSizes.spacingMedium),
                          Text(report.objectType,
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: AppSizes.spacingMedium),
                          Text(report.description),
                          const SizedBox(height: AppSizes.spacingLarge),
                          if (!active)
                            const Padding(
                                padding: EdgeInsets.only(
                                    top: AppSizes.spacingMedium),
                                child: InformationPanel(
                                    child: Text(AppStrings.reportReadOnly))),
                          if (report.status == ReportStatus.resolved)
                            const InformationPanel(
                                child:
                                    Text(AppStrings.reportResolvedByDelivery)),
                          if (active && report.evidenceLocked)
                            const InformationPanel(
                                icon: Icons.lock_outline,
                                child: Text(AppStrings.evidenceProtected)),
                          PrimaryAction(
                              label: widget.matchController.isGenerating
                                  ? AppStrings.generatingMatches
                                  : AppStrings.searchMatches,
                              icon: Icons.join_inner_rounded,
                              onPressed: active && !busy ? generate : null,
                              busy: widget.matchController.isGenerating),
                          const SizedBox(height: AppSizes.spacingRegular),
                          SecondaryAction(
                              label: AppStrings.editReport,
                              icon: Icons.edit_outlined,
                              onPressed: editable && !busy
                                  ? () => Navigator.pushNamed(
                                      context, AppRoutes.editReport,
                                      arguments: report.id)
                                  : null),
                          const SizedBox(height: AppSizes.spacingRegular),
                          OutlinedButton.icon(
                              onPressed: editable && !busy ? cancel : null,
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: AppSemanticColors.of(context)
                                      .error
                                      .foreground),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text(AppStrings.cancelReport)),
                          const SizedBox(height: AppSizes.spacingLarge),
                          InformationPanel(
                              icon: Icons.place_outlined,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(report.location,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    Text(formatDate(report.eventDate)),
                                  ])),
                          const SizedBox(height: AppSizes.spacingLarge),
                          const SectionHeading(title: AppStrings.objectStep),
                          for (final field in [
                            (AppStrings.categoryLabel, report.category),
                            (
                              AppStrings.primaryColorLabel,
                              report.primaryColor ?? AppStrings.notAvailable
                            ),
                            (
                              AppStrings.secondaryColorsLabel,
                              report.secondaryColors.isEmpty
                                  ? AppStrings.notAvailable
                                  : report.secondaryColors.join(', ')
                            ),
                            (
                              AppStrings.detectedBrand,
                              report.brand ?? AppStrings.notAvailable
                            ),
                            (
                              AppStrings.shapeLabel,
                              report.shape ?? AppStrings.notAvailable
                            )
                          ])
                            Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSizes.spacingMedium),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(field.$1,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant)),
                                      const SizedBox(
                                          height: AppSizes.spacingTiny),
                                      Text(field.$2),
                                    ])),
                          const SizedBox(height: AppSizes.spacingMedium),
                          InformationPanel(
                              icon: Icons.lock_outline,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppStrings.privateFeatureLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    const SizedBox(
                                        height: AppSizes.spacingSmall),
                                    Text(report.privateFeature ??
                                        AppStrings.notAvailable),
                                    const SizedBox(
                                        height: AppSizes.spacingSmall),
                                    const Text(AppStrings.privateHelp),
                                  ])),
                          if (report.imageAnalysis != null)
                            const Padding(
                                padding: EdgeInsets.only(
                                    top: AppSizes.spacingMedium),
                                child: Chip(
                                    label:
                                        Text(AppStrings.imageAnalysisBadge))),
                          const SizedBox(height: AppSizes.spacingLarge),
                          Text(
                              '${AppStrings.createdAtLabel}: ${formatDate(report.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text(
                              '${AppStrings.updatedAtLabel}: ${formatDate(report.updatedAt)}',
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: AppSizes.spacingLarge),
                        ])));
          }));
}
