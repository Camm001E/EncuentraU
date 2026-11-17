import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../controllers/admin_claims_controller.dart';
import '../widgets/claim_widgets.dart';

class AdminClaimsPage extends StatefulWidget {
  const AdminClaimsPage({required this.controller, super.key});
  final AdminClaimsController controller;
  @override
  State<AdminClaimsPage> createState() => _AdminClaimsPageState();
}

class _AdminClaimsPageState extends State<AdminClaimsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text(AppStrings.reviewQueue)),
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
                              title: AppStrings.reviewClaim,
                              subtitle: AppStrings.adminDashboardHelp),
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
                                child: ClaimCard(claim: claim, admin: true)),
                          if (c.hasMore)
                            SecondaryAction(
                                label: AppStrings.loadMore,
                                onPressed: c.isLoadingMore ? null : c.loadMore),
                        ])));
          }));
}
