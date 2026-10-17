import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';

class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.spacingMedium),
          decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge)),
          child: Row(children: [
            Icon(Icons.error_outline, color: colors.onErrorContainer),
            const SizedBox(width: AppSizes.spacingSmall),
            Expanded(
                child: Text(message,
                    style: TextStyle(color: colors.onErrorContainer))),
          ]),
        ));
  }
}
