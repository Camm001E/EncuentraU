import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../domain/entities/app_user.dart';
import '../controllers/auth_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.controller, super.key});
  final AuthController controller;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navProfile)),
      body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final user = controller.currentUser;
            if (user == null) return const SizedBox.shrink();
            return ContentWidth(
                maxWidth: AppSizes.objectFormMaxWidth,
                child: ListView(
                    padding: const EdgeInsets.all(AppSizes.spacingLarge),
                    children: [
                      const Align(
                          alignment: Alignment.centerLeft,
                          child: BrandMark(size: AppSizes.brandMarkLarge)),
                      const SizedBox(height: AppSizes.spacingLarge),
                      const SectionHeading(
                          title: AppStrings.profileTitle,
                          subtitle: AppStrings.profileDescription),
                      Text(user.fullName,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: AppSizes.spacingRegular),
                      Wrap(children: [
                        StatusPill(
                            label: user.isActive
                                ? AppStrings.accountActive
                                : AppStrings.accountInactive,
                            icon: user.isActive
                                ? Icons.verified_user_outlined
                                : Icons.lock_outline,
                            tone: user.isActive
                                ? AppSemanticColors.of(context).success
                                : AppSemanticColors.of(context).error)
                      ]),
                      const SizedBox(height: AppSizes.spacingLarge),
                      for (final item in [
                        (
                          AppStrings.emailLabel,
                          user.email,
                          Icons.alternate_email
                        ),
                        (
                          AppStrings.studentCodeLabel,
                          user.studentCode,
                          Icons.badge_outlined
                        ),
                        (
                          AppStrings.roleLabel,
                          user.role == UserRole.admin
                              ? AppStrings.adminRole
                              : AppStrings.studentRole,
                          Icons.school_outlined
                        )
                      ])
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(item.$3),
                            title: Text(item.$1),
                            subtitle: SelectableText(item.$2)),
                      const SizedBox(height: AppSizes.spacingXLarge),
                      if (user.role == UserRole.student) ...[
                        SecondaryAction(
                            label: AppStrings.myClaims,
                            icon: Icons.fact_check_outlined,
                            onPressed: () =>
                                Navigator.pushNamed(context, AppRoutes.claims)),
                        const SizedBox(height: AppSizes.spacingLarge),
                      ],
                      SecondaryAction(
                          label: controller.isBusy
                              ? AppStrings.signingOut
                              : AppStrings.signOut,
                          icon: Icons.logout_rounded,
                          onPressed: controller.isBusy
                              ? null
                              : () => controller.logout()),
                    ]));
          }));
}
