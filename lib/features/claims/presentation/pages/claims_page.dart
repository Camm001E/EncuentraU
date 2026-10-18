import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../controllers/claims_controller.dart';
import '../widgets/claim_widgets.dart';

class ClaimsPage extends StatefulWidget {
  const ClaimsPage({required this.controller, super.key});
  final ClaimsController controller;
  @override
  State<ClaimsPage> createState() => _ClaimsPageState();
}

class _ClaimsPageState extends State<ClaimsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.refresh();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text(AppStrings.myClaims)),
      body: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            return ContentWidth(
                child: RefreshIndicator(
                    onRefresh: c.refresh,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSizes.spacingLarge),
                        children: [
                          const SectionHeading(
                              title: AppStrings.myClaims,
                              subtitle: AppStrings.claimsSubtitle),
                          ClaimStatusFilter(
                              value: c.statusFilter, onChanged: c.setStatus),
                          const SizedBox(height: AppSizes.spacingLarge),
                          if (c.status == LoadStatus.loading ||
                              c.status == LoadStatus.initial)
                            const LoadingSkeleton(),
                          if (c.status == LoadStatus.error)
                            LoadFeedback(
                                message:
                                    c.message ?? AppStrings.unexpectedError,
                                onRetry: c.refresh),
                          if (c.status == LoadStatus.empty)
                            const LoadFeedback(message: AppStrings.noClaims),
                          for (final claim in c.items)
                            Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSizes.spacingMedium),
                                child: ClaimCard(claim: claim)),
                          if (c.hasMore)
                            SecondaryAction(
                                label: AppStrings.loadMore,
                                onPressed: c.isLoadingMore ? null : c.loadMore),
                        ])));
          }));
}
