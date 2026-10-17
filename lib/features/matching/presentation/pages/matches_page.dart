import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../domain/entities/object_match.dart';
import '../constants/match_labels.dart';
import '../controllers/match_controller.dart';
import '../widgets/match_card.dart';

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
            return RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSizes.spacingMLarge),
                    children: [
                      Wrap(
                          spacing: AppSizes.spacingMedium,
                          runSpacing: AppSizes.spacingSmall,
                          children: [
                            DropdownButton<MatchLevel?>(
                                value: controller.levelFilter,
                                items: [
                                  const DropdownMenuItem(
                                      value: null, child: Text(AppStrings.all)),
                                  ...MatchLevel.values.map((value) =>
                                      DropdownMenuItem(
                                          value: value,
                                          child: Text(value.label))),
                                ],
                                onChanged: (level) => controller.setFilters(
                                    level: level,
                                    status: controller.statusFilter)),
                            DropdownButton<MatchStatus?>(
                                value: controller.statusFilter,
                                items: [
                                  const DropdownMenuItem(
                                      value: null, child: Text(AppStrings.all)),
                                  ...MatchStatus.values.map((value) =>
                                      DropdownMenuItem(
                                          value: value,
                                          child: Text(value.label))),
                                ],
                                onChanged: (status) => controller.setFilters(
                                    level: controller.levelFilter,
                                    status: status)),
                          ]),
                      Text(AppStrings.resultCount(controller.total)),
                      if (controller.status == LoadStatus.loading)
                        const Center(child: CircularProgressIndicator()),
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
                    ]));
          }));
}
