import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';

class LoadFeedback extends StatelessWidget {
  const LoadFeedback({required this.message, this.onRetry, super.key});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(AppSizes.spacingLarge),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: AppSizes.spacingRegular),
          OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry))
        ],
      ]));
}
