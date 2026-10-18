import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../theme/app_semantic_colors.dart';
import 'design_system.dart';

class LoadFeedback extends StatelessWidget {
  const LoadFeedback({required this.message, this.onRetry, super.key});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingLarge),
      child: InformationPanel(
          tone: onRetry == null
              ? AppSemanticColors.of(context).information
              : AppSemanticColors.of(context).warning,
          icon: onRetry == null
              ? Icons.explore_outlined
              : Icons.cloud_off_outlined,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    onRetry == null
                        ? AppStrings.emptyTitle
                        : AppStrings.errorTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSizes.spacingSmall),
                Text(message),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSizes.spacingRegular),
                  SecondaryAction(
                      label: AppStrings.retry,
                      onPressed: onRetry,
                      icon: Icons.refresh)
                ],
              ])));
}
