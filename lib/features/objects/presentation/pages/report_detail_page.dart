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
import '../constants/report_labels.dart';
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
              return const Center(child: CircularProgressIndicator());
            if (controller.detailStatus == LoadStatus.error)
              return Center(
                  child: LoadFeedback(
                      message: controller.detailMessage ??
                          AppStrings.unexpectedError,
                      onRetry: () => controller.loadDetail(widget.reportId)));
            final report = controller.detail;
            if (report == null || report.id != widget.reportId)
              return const LoadFeedback(message: AppStrings.apiNotFound);
            final active = report.status == ReportStatus.active;
            final busy = controller.isCancelling ||
                controller.isUpdating ||
                widget.matchController.isGenerating;
            return RefreshIndicator(
                onRefresh: () => controller.loadDetail(widget.reportId),
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSizes.spacingMLarge),
                    children: [
                      ReportPhoto(image: report.image),
                      const SizedBox(height: AppSizes.spacingMedium),
                      Text(report.objectType,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Wrap(spacing: AppSizes.spacingSmall, children: [
                        Chip(label: Text(report.reportType.label)),
                        Chip(label: Text(report.status.label))
                      ]),
                      Text('${AppStrings.categoryLabel}: ${report.category}'),
                      Text(
                          '${AppStrings.primaryColorLabel}: ${report.primaryColor ?? AppStrings.notAvailable}'),
                      Text(
                          '${AppStrings.secondaryColorsLabel}: ${report.secondaryColors.join(', ')}'),
                      Text(
                          '${AppStrings.detectedBrand}: ${report.brand ?? AppStrings.notAvailable}'),
                      Text(
                          '${AppStrings.shapeLabel}: ${report.shape ?? AppStrings.notAvailable}'),
                      const SizedBox(height: AppSizes.spacingMedium),
                      Text(report.description),
                      Text(report.location),
                      Text(formatDate(report.eventDate)),
                      const SizedBox(height: AppSizes.spacingMedium),
                      Text(
                          '${AppStrings.privateFeatureLabel}: ${report.privateFeature ?? AppStrings.notAvailable}'),
                      if (report.imageAnalysis != null)
                        const Chip(label: Text(AppStrings.imageAnalysisBadge)),
                      Text(
                          '${AppStrings.createdAtLabel}: ${formatDate(report.createdAt)}'),
                      Text(
                          '${AppStrings.updatedAtLabel}: ${formatDate(report.updatedAt)}'),
                      const SizedBox(height: AppSizes.spacingLarge),
                      if (!active) const Text(AppStrings.reportReadOnly),
                      FilledButton.tonalIcon(
                          onPressed: active && !busy
                              ? () => Navigator.pushNamed(
                                  context, AppRoutes.editReport,
                                  arguments: report.id)
                              : null,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text(AppStrings.editReport)),
                      OutlinedButton.icon(
                          onPressed: active && !busy ? cancel : null,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text(AppStrings.cancelReport)),
                      FilledButton.icon(
                          onPressed: active && !busy ? generate : null,
                          icon: const Icon(Icons.auto_awesome),
                          label: Text(widget.matchController.isGenerating
                              ? AppStrings.generatingMatches
                              : AppStrings.searchMatches)),
                      if (widget.matchController.generationMessage != null)
                        Text(widget.matchController.generationMessage!),
                    ]));
          }));
}
