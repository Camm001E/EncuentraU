import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../domain/entities/object_match.dart';
import '../constants/match_labels.dart';
import '../controllers/match_controller.dart';
import '../widgets/match_card.dart';
import '../../../../core/presentation/widgets/design_system.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({required this.controller, super.key});
  final MatchController controller;
  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.refresh();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text(AppStrings.matchesTitle)),
      body: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;
            return ContentWidth(
                child: RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSizes.spacingMLarge),
                        children: [
                          const SectionHeading(
                              title: AppStrings.matchListHeadline,
                              subtitle: AppStrings.matchListSubtitle),
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
                          Text(AppStrings.resultCount(controller.total)),
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
                            ...controller.items
                                .map((match) => MatchCard(match: match)),
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
