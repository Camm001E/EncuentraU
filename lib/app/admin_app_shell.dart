import 'package:flutter/material.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_strings.dart';
import '../core/presentation/widgets/design_system.dart';
import '../features/authentication/presentation/controllers/auth_controller.dart';
import '../features/authentication/presentation/pages/profile_page.dart';
import '../features/claims/presentation/controllers/admin_claims_controller.dart';
import '../features/claims/presentation/pages/admin_claims_page.dart';
import '../features/claims/presentation/pages/admin_dashboard_page.dart';

class AdminAppShell extends StatefulWidget {
  const AdminAppShell(
      {required this.auth,
      required this.claims,
      required this.summary,
      this.initialIndex = 0,
      super.key});
  final AuthController auth;
  final AdminClaimsController claims;
  final AdminSummaryController summary;
  final int initialIndex;
  @override
  State<AdminAppShell> createState() => _AdminAppShellState();
}

class _AdminAppShellState extends State<AdminAppShell> {
  late int _index = widget.initialIndex;
  static const labels = [
    AppStrings.adminHome,
    AppStrings.reviewQueue,
    AppStrings.navProfile
  ];
  static const icons = [
    Icons.dashboard_outlined,
    Icons.fact_check_outlined,
    Icons.person_outline_rounded
  ];
  void select(int index) {
    if (index != _index) setState(() => _index = index);
  }

  Widget page() => switch (_index) {
        0 => AdminDashboardPage(
            controller: widget.summary,
            onStatus: (status) {
              widget.claims.setStatus(status);
              select(1);
            }),
        1 => AdminClaimsPage(controller: widget.claims),
        _ => ProfilePage(controller: widget.auth)
      };
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppSizes.navigationBreakpoint;
        final extended =
            constraints.maxWidth >= AppSizes.extendedRailBreakpoint &&
                MediaQuery.textScalerOf(context).scale(1) <=
                    AppSizes.textScaleNavigationCutoff;
        return PopScope(
            canPop: _index == 0,
            onPopInvokedWithResult: (popped, result) {
              if (!popped) select(0);
            },
            child: Scaffold(
                body: Row(children: [
                  if (wide) ...[
                    SafeArea(
                        child: NavigationRail(
                            scrollable: true,
                            extended: extended,
                            selectedIndex: _index,
                            onDestinationSelected: select,
                            minWidth: AppSizes.navigationRailWidth,
                            minExtendedWidth: AppSizes.railExtendedWidth,
                            leading: const Padding(
                                padding: EdgeInsets.all(AppSizes.spacingMedium),
                                child: BrandMark()),
                            labelType: extended ||
                                    MediaQuery.textScalerOf(context).scale(1) >
                                        AppSizes.textScaleNavigationCutoff
                                ? NavigationRailLabelType.none
                                : NavigationRailLabelType.all,
                            destinations: [
                          for (var i = 0; i < labels.length; i++)
                            NavigationRailDestination(
                                icon: Tooltip(
                                    message: labels[i], child: Icon(icons[i])),
                                label: Text(labels[i]))
                        ])),
                    const VerticalDivider(width: 1)
                  ],
                  Expanded(
                      child:
                          KeyedSubtree(key: ValueKey(_index), child: page())),
                ]),
                bottomNavigationBar: wide
                    ? null
                    : NavigationBar(
                        selectedIndex: _index,
                        onDestinationSelected: select,
                        height: AppSizes.navigationHeight,
                        labelBehavior:
                            MediaQuery.textScalerOf(context).scale(1) >
                                    AppSizes.textScaleNavigationCutoff
                                ? NavigationDestinationLabelBehavior.alwaysHide
                                : NavigationDestinationLabelBehavior.alwaysShow,
                        destinations: [
                            for (var i = 0; i < labels.length; i++)
                              NavigationDestination(
                                  icon: Icon(icons[i]), label: labels[i])
                          ])));
      });
}
