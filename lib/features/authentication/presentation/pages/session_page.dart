import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_brand_header.dart';

class SessionPage extends StatefulWidget {
  const SessionPage({required this.controller, super.key});
  final AuthController controller;
  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  Future<void> _restore() async {
    if (!mounted) return;
    await widget.controller.restoreSession();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      widget.controller.isAuthenticated ? AppRoutes.home : AppRoutes.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: SafeArea(
            child: Center(
                child: Padding(
          padding: EdgeInsets.all(AppSizes.spacingLarge),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AuthBrandHeader(),
            SizedBox(height: AppSizes.spacingXLarge),
            CircularProgressIndicator(),
            SizedBox(height: AppSizes.spacingMedium),
            Text(AppStrings.restoringSession),
          ]),
        ))),
      );
}
