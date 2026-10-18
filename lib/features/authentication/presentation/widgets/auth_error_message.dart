import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/theme/app_semantic_colors.dart';

class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: true,
      child: InformationPanel(
          tone: AppSemanticColors.of(context).error,
          icon: Icons.error_outline,
          child: Text(message)));
}
