import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../domain/entities/object_match.dart';
import '../constants/match_labels.dart';
import '../controllers/match_controller.dart';
import '../widgets/match_card.dart';
import '../widgets/visual_review_panel.dart';
import '../../../../core/presentation/widgets/design_system.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({required this.controller, this.reportId, super.key});
  final MatchController controller;
  final String? reportId;
  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  late final MatchController controller = widget.reportId == null
      ? widget.controller
      : widget.controller.forReport(widget.reportId!);
  @override
  void dispose() {
    if (widget.reportId != null) controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.refresh();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(widget.reportId == null
              ? AppStrings.matchesTitle
              : 'Candidatos de tu objeto')),
      body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final controller = this.controller;
            return ContentWidth(
                child: RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSizes.spacingMLarge),
                        children: [
                          SectionHeading(
                              title: widget.reportId == null
                                  ? AppStrings.matchListHeadline
                                  : 'Coincidencias de este reporte',
                              subtitle: widget.reportId == null
                                  ? AppStrings.matchListSubtitle
                                  : 'Solo se muestran resultados del objeto que seleccionaste.'),
                          if (widget.reportId != null &&
                              controller.items.isNotEmpty)
                            Text(
                                'Tu objeto: ${controller.items.first.myReport.objectType}'),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final entry in const {
                              MatchSection.candidates: 'Candidatos',
                              MatchSection.discarded: 'Descartados',
                              MatchSection.closed: 'Cerrados',
                            }.entries)
                              ChoiceChip(
                                  label: Text(
                                      '${entry.value} (${controller.sectionCount(entry.key)})'),
                                  selected: controller.section == entry.key,
                                  onSelected: (_) =>
                                      controller.selectSection(entry.key)),
                          ]),
                          const SizedBox(height: 12),
                          LayoutBuilder(builder: (context, constraints) {
                            final width = (constraints.maxWidth -
                                    AppSizes.spacingMedium) /
                                2;
                            return Wrap(
                                spacing: AppSizes.spacingMedium,
                                runSpacing: AppSizes.spacingSmall,
                                children: [
                                  SizedBox(
                                      width: width,
                                      child: DropdownButtonFormField<
                                              MatchLevel?>(
                                          key: ValueKey(controller.levelFilter),
                                          initialValue: controller.levelFilter,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                              labelText: AppStrings.levelLabel),
                                          items: [
                                            const DropdownMenuItem(
                                                value: null,
                                                child: Text(AppStrings.all)),
                                            for (final level
                                                in MatchLevel.values)
                                              DropdownMenuItem(
                                                  value: level,
                                                  child: Text(level.shortLabel))
                                          ],
                                          onChanged: (value) =>
                                              controller.setFilters(
                                                  level: value,
                                                  status: controller
                                                      .statusFilter))),
                                  SizedBox(
                                      width: width,
                                      child: DropdownButtonFormField<
                                              MatchStatus?>(
                                          key:
                                              ValueKey(controller.statusFilter),
                                          initialValue: controller.statusFilter,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                              labelText:
                                                  AppStrings.statusLabel),
                                          items: [
                                            const DropdownMenuItem(
                                                value: null,
                                                child: Text(AppStrings.all)),
                                            for (final status
                                                in MatchStatus.values)
                                              DropdownMenuItem(
                                                  value: status,
                                                  child: Text(status.label))
                                          ],
                                          onChanged: (value) =>
                                              controller.setFilters(
                                                  level: controller.levelFilter,
                                                  status: value))),
                                ]);
                          }),
                          const SizedBox(height: AppSizes.spacingLarge),
                          Text(
                              '${controller.visibleItems.length} resultados visibles'),
                          if (controller.canReview &&
                              controller.section == MatchSection.candidates &&
                              controller.visibleItems.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                                onPressed: controller.isReviewingBatch ||
                                        controller.reviewableCount == 0
                                    ? null
                                    : controller.reviewVisible,
                                icon: const Icon(Icons.compare_outlined),
                                label: Text(controller.isReviewingBatch
                                    ? 'Revisando ${controller.batchCompleted}/${controller.batchTotal}'
                                    : 'Comparar hasta 5 coincidencias')),
                            const Text(
                                'Las diferencias visibles se separan en Descartados. '
                                'Una comparación guardada se reutiliza si las fotos no cambiaron.'),
                            const SizedBox(height: 12),
                          ],
                          if (controller.status == LoadStatus.loading)
                            const LoadingSkeleton(),
                          if (controller.status == LoadStatus.error)
                            LoadFeedback(
                                message: controller.message ??
                                    AppStrings.unexpectedError,
                                onRetry: () => controller.refresh()),
                          if (controller.status == LoadStatus.empty)
                            const LoadFeedback(message: AppStrings.noMatches),
                          if (controller.status == LoadStatus.empty)
                            const Text(AppStrings.matchesHelp),
                          if (controller.status != LoadStatus.loading)
                            if (controller.status == LoadStatus.ready &&
                                controller.visibleItems.isEmpty)
                              const Text('No hay resultados en esta sección.'),
                          if (controller.status != LoadStatus.loading)
                            ...controller.visibleItems.map((match) => MatchCard(
                                onReturn: controller.refresh,
                                match: match,
                                visualReview: VisualReviewPanel(
                                    match: match,
                                    controller: controller,
                                    compact: true))),
                          if (controller.hasMore)
                            OutlinedButton(
                                onPressed: controller.isLoadingMore
                                    ? null
                                    : () => controller.loadMore(),
                                child: controller.isLoadingMore
                                    ? const CircularProgressIndicator()
                                    : const Text(AppStrings.loadMore)),
                        ])));
          }));
}
