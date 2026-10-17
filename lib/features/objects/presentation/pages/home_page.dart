import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../controllers/object_controller.dart';
import '../widgets/report_action_card.dart';
import '../widgets/report_list.dart';

class HomePage extends StatefulWidget {
  const HomePage(
      {required this.controller, required this.authController, super.key});
  final ObjectController controller;
  final AuthController authController;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.appName), actions: [
          AnimatedBuilder(
              animation: widget.authController,
              builder: (context, _) => TextButton.icon(
                  onPressed: widget.authController.isBusy
                      ? null
                      : () => widget.authController.logout(),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(widget.authController.isBusy
                      ? AppStrings.signingOut
                      : AppStrings.signOut))),
          IconButton(
              tooltip: AppStrings.appVersion,
              onPressed: () => showAboutDialog(
                  context: context,
                  applicationName: AppStrings.appName,
                  applicationVersion: AppStrings.appVersion),
              icon: const Icon(Icons.info_outline)),
        ]),
        body: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) => RefreshIndicator(
                onRefresh: widget.controller.refresh,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSizes.spacingMLarge),
                    children: [
                      Container(
                          padding: const EdgeInsets.all(AppSizes.spacingLarge),
                          decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusXLarge)),
                          child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppStrings.welcome,
                                    style: TextStyle(
                                        color: AppColors.surface,
                                        fontWeight: FontWeight.w800)),
                                SizedBox(height: AppSizes.spacingSmall),
                                Text(AppStrings.welcomeDescription,
                                    style: TextStyle(color: AppColors.surface)),
                              ])),
                      const SizedBox(height: AppSizes.spacingLarge),
                      LayoutBuilder(builder: (context, constraints) {
                        final cards = [
                          ReportActionCard(
                              icon: Icons.search_off_rounded,
                              title: AppStrings.lostAction,
                              description: AppStrings.lostActionDescription,
                              color: AppColors.lost,
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.registerLost)),
                          ReportActionCard(
                              icon: Icons.volunteer_activism_rounded,
                              title: AppStrings.foundAction,
                              description: AppStrings.foundActionDescription,
                              color: AppColors.primary,
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.registerFound)),
                        ];
                        return constraints.maxWidth >= AppSizes.homeBreakpoint
                            ? Row(children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: AppSizes.spacingRegular),
                                Expanded(child: cards[1])
                              ])
                            : Column(children: cards);
                      }),
                      const SizedBox(height: AppSizes.spacingMedium),
                      Wrap(
                          spacing: AppSizes.spacingRegular,
                          runSpacing: AppSizes.spacingSmall,
                          children: [
                            OutlinedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                    context, AppRoutes.objects),
                                icon: const Icon(Icons.inventory_2_outlined),
                                label: const Text(AppStrings.viewReports)),
                            FilledButton.tonalIcon(
                                onPressed: () => Navigator.pushNamed(
                                    context, AppRoutes.matches),
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text(AppStrings.matchesTitle)),
                          ]),
                      const SizedBox(height: AppSizes.spacingLarge),
                      Text(AppStrings.myReports,
                          style: Theme.of(context).textTheme.titleLarge),
                      ReportList(controller: widget.controller, compact: true),
                    ]))),
      );
}
