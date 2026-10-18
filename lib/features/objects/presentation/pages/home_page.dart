import 'package:flutter/material.dart';
import '../../../deliveries/presentation/widgets/delivery_widgets.dart';
import '../../../deliveries/presentation/widgets/delivery_scope.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/app_gradients.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../controllers/object_controller.dart';
import '../widgets/report_action_card.dart';
import '../widgets/report_list.dart';

class HomePage extends StatefulWidget {
  const HomePage(
      {required this.controller,
      required this.authController,
      this.dashboardController,
      this.onRefresh,
      super.key});
  final ObjectController controller;
  final AuthController authController;
  final DashboardController? dashboardController;
  final Future<void> Function()? onRefresh;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.controller.reportTypeFilter != null ||
          widget.controller.statusFilter != null) {
        widget.controller.setFilters();
      } else {
        widget.controller.ensureLoaded();
      }
      widget.dashboardController?.ensureLoaded();
    });
  }

  Future<void> refresh() async => Future.wait([
        if (DeliveryScope.maybeOf(context) case final scope?)
          scope.student.refreshCounts(),
        if (widget.onRefresh != null) widget.onRefresh!(),
        widget.controller.refresh(),
        if (widget.dashboardController != null)
          widget.dashboardController!.refresh(),
      ]);
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: MediaQuery.textScalerOf(context).scale(1) >
                  AppSizes.textScaleNavigationCutoff
              ? const BrandMark()
              : const BrandWordmark(compact: true),
          actions: [
            if (MediaQuery.textScalerOf(context).scale(1) >
                AppSizes.textScaleNavigationCutoff)
              IconButton(
                  tooltip: AppStrings.signOut,
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: widget.authController.isBusy
                      ? null
                      : () => widget.authController.logout())
            else
              TextButton.icon(
                  onPressed: widget.authController.isBusy
                      ? null
                      : () => widget.authController.logout(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(AppStrings.signOut)),
          ]),
      body: AnimatedBuilder(
          animation: Listenable.merge([
            widget.controller,
            widget.authController,
            if (widget.dashboardController != null) widget.dashboardController!
          ]),
          builder: (context, _) => ContentWidth(
              child: RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSizes.spacingLarge),
                      children: [
                        Container(
                            padding:
                                const EdgeInsets.all(AppSizes.spacingLarge),
                            decoration: BoxDecoration(
                                gradient: AppGradients.welcome,
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusXLarge)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppStrings.homeEyebrow,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                              letterSpacing: AppSizes
                                                  .eyebrowLetterSpacing)),
                                  const SizedBox(
                                      height: AppSizes.spacingMedium),
                                  Text(
                                      AppStrings.greeting(widget.authController
                                              .currentUser?.fullName ??
                                          AppStrings.studentRole),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium),
                                  const SizedBox(height: AppSizes.spacingSmall),
                                  Text(AppStrings.homeHeadline,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                  const SizedBox(height: AppSizes.spacingSmall),
                                  const Text(AppStrings.welcomeDescription),
                                ])),
                        const SizedBox(height: AppSizes.spacingLarge),
                        LayoutBuilder(builder: (context, constraints) {
                          final cards = [
                            ReportActionCard(
                                icon: Icons.search_rounded,
                                title: AppStrings.lostAction,
                                description: AppStrings.lostActionDescription,
                                tone: AppSemanticColors.of(context).lost,
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.registerLost)),
                            ReportActionCard(
                                icon: Icons.volunteer_activism_outlined,
                                title: AppStrings.foundAction,
                                description: AppStrings.foundActionDescription,
                                tone: AppSemanticColors.of(context).found,
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.registerFound)),
                          ];
                          return constraints.maxWidth >= AppSizes.homeBreakpoint
                              ? Row(children: [
                                  Expanded(child: cards[0]),
                                  const SizedBox(width: AppSizes.spacingMedium),
                                  Expanded(child: cards[1])
                                ])
                              : Column(children: [
                                  cards[0],
                                  const SizedBox(
                                      height: AppSizes.spacingRegular),
                                  cards[1]
                                ]);
                        }),
                        const SizedBox(height: AppSizes.spacingXLarge),
                        const DeliveryTotals(),
                        if (widget.dashboardController
                            case final dashboard?) ...[
                          const SectionHeading(title: AppStrings.summaryTitle),
                          if (dashboard.status == LoadStatus.initial ||
                              dashboard.status == LoadStatus.loading)
                            const LoadingSkeleton(count: 1),
                          if (dashboard.status == LoadStatus.error)
                            LoadFeedback(
                                message: dashboard.message ??
                                    AppStrings.unexpectedError,
                                onRetry: dashboard.refresh),
                          if (dashboard.summary case final summary?)
                            LayoutBuilder(builder: (context, constraints) {
                              final columns = constraints.maxWidth >=
                                      AppSizes.homeBreakpoint
                                  ? 4
                                  : 2;
                              final width = (constraints.maxWidth -
                                      AppSizes.spacingRegular * (columns - 1)) /
                                  columns;
                              return Wrap(
                                  spacing: AppSizes.spacingRegular,
                                  runSpacing: AppSizes.spacingRegular,
                                  children: [
                                    for (final metric in [
                                      (
                                        AppStrings.activeReports,
                                        summary.activeReports,
                                        Icons.inventory_2_outlined
                                      ),
                                      (
                                        AppStrings.lostReports,
                                        summary.lostReports,
                                        Icons.search_rounded
                                      ),
                                      (
                                        AppStrings.foundReports,
                                        summary.foundReports,
                                        Icons.volunteer_activism_outlined
                                      ),
                                      (
                                        AppStrings.availableMatches,
                                        summary.matches,
                                        Icons.join_inner_rounded
                                      )
                                    ])
                                      SizedBox(
                                          width: width,
                                          child: Container(
                                              padding: const EdgeInsets.all(
                                                  AppSizes.spacingMedium),
                                              decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surface,
                                                  border: Border.all(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .outlineVariant),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppSizes
                                                              .radiusLarge)),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(metric.$3,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary),
                                                    const SizedBox(
                                                        height: AppSizes
                                                            .spacingSmall),
                                                    Text(metric.$2.toString(),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .headlineMedium),
                                                    Text(metric.$1),
                                                  ]))),
                                  ]);
                            }),
                          const SizedBox(height: AppSizes.spacingXLarge),
                        ],
                        SectionHeading(
                            title: AppStrings.recentReports,
                            trailing: TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, AppRoutes.objects),
                                child: const Text(AppStrings.viewAll))),
                        ReportList(
                            controller: widget.controller, compact: true),
                        const SizedBox(height: AppSizes.spacingLarge),
                        SecondaryAction(
                            label: AppStrings.matchesTitle,
                            icon: Icons.join_inner_rounded,
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.matches)),
                        const SizedBox(height: AppSizes.spacingLarge),
                      ])))));
}
