import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/widgets/design_system.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});
  @override
  Widget build(BuildContext context) => Column(children: [
        const BrandWordmark(),
        const SizedBox(height: AppSizes.spacingSmall),
        Text(AppStrings.loginSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]);
}
