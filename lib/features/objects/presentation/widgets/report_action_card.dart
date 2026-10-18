import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_semantic_colors.dart';

class ReportActionCard extends StatelessWidget {
  const ReportActionCard(
      {required this.icon,
      required this.title,
      required this.description,
      required this.tone,
      required this.onTap,
      super.key});
  final IconData icon;
  final String title, description;
  final SemanticTone tone;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: tone.background,
      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          child: Padding(
              padding: const EdgeInsets.all(AppSizes.spacingLarge),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon, color: tone.foreground, size: AppSizes.cardIconSize),
                const SizedBox(width: AppSizes.spacingMedium),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: tone.foreground)),
                      const SizedBox(height: AppSizes.spacingTiny),
                      Text(description,
                          style: TextStyle(color: tone.foreground)),
                    ])),
                const SizedBox(width: AppSizes.spacingSmall),
                Icon(Icons.arrow_outward_rounded, color: tone.foreground),
              ]))));
}
