import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../deliveries/presentation/widgets/delivery_scope.dart';
import '../../../deliveries/presentation/widgets/delivery_widgets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../domain/entities/ownership_claim.dart';
import '../controllers/admin_claims_controller.dart';
import '../widgets/claim_widgets.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage(
      {required this.controller, required this.onStatus, super.key});
  final AdminSummaryController controller;
  final ValueChanged<ClaimStatus> onStatus;
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const BrandWordmark(compact: true)),
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
                              title: AppStrings.adminDashboardTitle,
                              subtitle: AppStrings.adminDashboardHelp,
                              eyebrow: AppStrings.adminRole),
                          DeliveryTotals(
                              admin: true,
                              onStatus: (status) {
                                DeliveryScope.maybeOf(context)
                                    ?.admin
                                    .setStatus(status);
                                Navigator.pushNamed(
                                    context, AppRoutes.adminDeliveries);
                              }),
                          if (c.status == LoadStatus.loading ||
                              c.status == LoadStatus.initial)
                            const LoadingSkeleton(),
                          if (c.status == LoadStatus.error)
                            LoadFeedback(
                                message:
                                    c.message ?? AppStrings.unexpectedError,
                                onRetry: c.refresh),
                          if (c.totals case final totals?) ...[
                            for (final metric in [
                              (
                                ClaimStatus.pending,
                                AppStrings.pendingClaims,
                                totals.pending
                              ),
                              (
                                ClaimStatus.approved,
                                AppStrings.approvedClaims,
                                totals.approved
                              ),
                              (
                                ClaimStatus.rejected,
                                AppStrings.rejectedClaims,
                                totals.rejected
                              )
                            ])
                              Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSizes.spacingMedium),
                                  child: Card(
                                      child: ListTile(
                                          contentPadding: const EdgeInsets.all(
                                              AppSizes.spacingLarge),
                                          leading: Icon(claimIcon(metric.$1),
                                              color:
                                                  claimTone(context, metric.$1)
                                                      .foreground),
                                          title: Text(metric.$2),
                                          subtitle: Text('${metric.$3}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium),
                                          trailing: const Icon(
                                              Icons.arrow_forward_rounded),
                                          onTap: () =>
                                              widget.onStatus(metric.$1))))
                          ]
                        ])));
          }));
}
