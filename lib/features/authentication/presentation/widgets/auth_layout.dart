import 'package:flutter/material.dart';
import '../../../../core/constants/app_gradients.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/widgets/design_system.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.welcome),
      child: SafeArea(
          child: LayoutBuilder(
              builder: (context, constraints) => Center(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.spacingLarge),
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: AppSizes.authMaxWidth),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (constraints.maxWidth >=
                                    AppSizes.authArtworkBreakpoint) ...[
                                  Expanded(
                                      child: Padding(
                                          padding: const EdgeInsets.all(
                                              AppSizes.spacingXLarge),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const BrandMark(
                                                    size: AppSizes
                                                        .brandMarkLarge),
                                                const SizedBox(
                                                    height:
                                                        AppSizes.spacingXLarge),
                                                Text(AppStrings.brandEyebrow,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelMedium
                                                        ?.copyWith(
                                                            letterSpacing: AppSizes
                                                                .eyebrowLetterSpacing)),
                                                const SizedBox(
                                                    height:
                                                        AppSizes.spacingMedium),
                                                Text(AppStrings.authHeadline,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headlineLarge),
                                                const SizedBox(
                                                    height:
                                                        AppSizes.spacingLarge),
                                                Text(AppStrings.authDescription,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge),
                                                const SizedBox(
                                                    height:
                                                        AppSizes.spacingXLarge),
                                                const Row(children: [
                                                  Icon(Icons
                                                      .verified_user_outlined),
                                                  SizedBox(
                                                      width: AppSizes
                                                          .spacingSmall),
                                                  Expanded(
                                                      child: Text(
                                                          AppStrings.authTrust))
                                                ]),
                                              ]))),
                                  const SizedBox(width: AppSizes.spacingXLarge),
                                ],
                                Expanded(
                                    child: Align(
                                        child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxWidth:
                                                    AppSizes.formMaxWidth),
                                            child: Container(
                                                padding: const EdgeInsets.all(
                                                    AppSizes.spacingLarge),
                                                decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppSizes
                                                                .radiusXLarge),
                                                    boxShadow: AppShadows.soft),
                                                child: child)))),
                              ])))))));
}
