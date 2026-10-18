import 'package:flutter/material.dart';
import '../core/constants/app_durations.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_strings.dart';
import '../core/presentation/app_motion.dart';
import '../core/presentation/widgets/design_system.dart';
import '../features/authentication/presentation/controllers/auth_controller.dart';
import '../features/authentication/presentation/pages/profile_page.dart';
import '../features/dashboard/presentation/controllers/dashboard_controller.dart';
import '../features/matching/presentation/controllers/match_controller.dart';
import '../features/matching/presentation/pages/matches_page.dart';
import '../features/objects/presentation/controllers/object_controller.dart';
import '../features/objects/presentation/pages/home_page.dart';
import '../features/objects/presentation/pages/objects_page.dart';

class AppShell extends StatefulWidget {
  const AppShell(
      {required this.objects,
      required this.auth,
      required this.matches,
      required this.dashboard,
      this.initialIndex = 0,
      super.key});
  final ObjectController objects;
  final AuthController auth;
  final MatchController matches;
  final DashboardController dashboard;
  final int initialIndex;
  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;
  int get selectedIndex => _index;
  void selectTab(int index) {
    if (index != _index) setState(() => _index = index);
  }

  static const labels = [
    AppStrings.navHome,
    AppStrings.myReports,
    AppStrings.matchesTitle,
    AppStrings.navProfile
  ];
  static const icons = [
    Icons.home_outlined,
    Icons.inventory_2_outlined,
    Icons.join_inner_rounded,
    Icons.person_outline_rounded
  ];
  Widget page() => switch (_index) {
        0 => HomePage(
            controller: widget.objects,
            authController: widget.auth,
            dashboardController: widget.dashboard),
        1 => ObjectsPage(controller: widget.objects),
        2 => MatchesPage(controller: widget.matches),
        _ => ProfilePage(controller: widget.auth),
      };
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppSizes.navigationBreakpoint;
        final extended =
            constraints.maxWidth >= AppSizes.extendedRailBreakpoint &&
                MediaQuery.textScalerOf(context).scale(1) <=
                    AppSizes.textScaleNavigationCutoff;
        final content = AnimatedSwitcher(
            duration: AppMotion.duration(context, AppDurations.micro),
            child: KeyedSubtree(key: ValueKey(_index), child: page()));
        return PopScope(
            canPop: _index == 0,
            onPopInvokedWithResult: (popped, result) {
              if (!popped && _index != 0) selectTab(0);
            },
            child: Scaffold(
              body: Row(children: [
                if (wide) ...[
                  SafeArea(
                      child: NavigationRail(
                          scrollable: true,
                          selectedIndex: _index,
                          onDestinationSelected: selectTab,
                          extended: extended,
                          minWidth: AppSizes.navigationRailWidth,
                          minExtendedWidth: AppSizes.railExtendedWidth,
                          leading: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.spacingLarge),
                              child: extended
                                  ? const SizedBox(
                                      width: AppSizes.ringSize,
                                      child: BrandWordmark(compact: true))
                                  : const BrandMark()),
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
                  const VerticalDivider(width: 1),
                ],
                Expanded(child: content),
              ]),
              bottomNavigationBar: wide
                  ? null
                  : NavigationBar(
                      selectedIndex: _index,
                      onDestinationSelected: selectTab,
                      height: AppSizes.navigationHeight,
                      labelBehavior: constraints.maxWidth <
                                  AppSizes.minimumLabeledNavigationWidth ||
                              MediaQuery.textScalerOf(context).scale(1) >
                                  AppSizes.textScaleNavigationCutoff
                          ? NavigationDestinationLabelBehavior.alwaysHide
                          : NavigationDestinationLabelBehavior.alwaysShow,
                      destinations: [
                          for (var i = 0; i < labels.length; i++)
                            NavigationDestination(
                                icon: Icon(icons[i]), label: labels[i])
                        ]),
            ));
      });
}
