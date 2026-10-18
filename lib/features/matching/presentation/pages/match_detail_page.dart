import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../controllers/match_controller.dart';
import '../widgets/match_card.dart';
import '../../../../core/presentation/widgets/design_system.dart';

class MatchDetailPage extends StatefulWidget {
  const MatchDetailPage(
      {required this.matchId, required this.controller, super.key});
  final String matchId;
  final MatchController controller;
  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.loadDetail(widget.matchId);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text(AppStrings.matchDetail)),
      body: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;
            if (controller.detailStatus == LoadStatus.loading ||
                controller.detailStatus == LoadStatus.initial)
              return const ContentWidth(
                  child: Padding(
                      padding: EdgeInsets.all(AppSizes.spacingLarge),
                      child: LoadingSkeleton()));
            if (controller.detailStatus == LoadStatus.error)
              return LoadFeedback(
                  message:
                      controller.detailMessage ?? AppStrings.unexpectedError,
                  onRetry: () => controller.loadDetail(widget.matchId));
            final match = controller.detail;
            if (match == null || match.id != widget.matchId)
              return const LoadFeedback(message: AppStrings.apiNotFound);
            return ContentWidth(
                child: RefreshIndicator(
                    onRefresh: () => controller.loadDetail(widget.matchId),
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSizes.spacingMLarge),
                        children: [
                          MatchCard(
                              key: ValueKey(match.id),
                              match: match,
                              detail: true)
                        ])));
          }));
}
