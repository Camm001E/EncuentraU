import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_validation.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_error_message.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.controller, super.key});
  final AuthController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (widget.controller.isBusy ||
        !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final succeeded = await widget.controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted || !succeeded) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
    if (!AppValidation.isValidEmail(value)) return AppStrings.invalidEmail;
    if (value.trim().length > AppValidation.maximumEmailLength)
      return AppStrings.fieldTooLong;
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.requiredField;
    if (value.length < AppValidation.minimumPasswordLength)
      return AppStrings.passwordMinLength;
    if (value.length > AppValidation.maximumPasswordLength)
      return AppStrings.fieldTooLong;
    return null;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final busy = widget.controller.isBusy;
          final error = widget.controller.errorMessage;
          return Scaffold(
              body: SafeArea(
                  child: Center(
                      child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.spacingLarge),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
              child: Card(
                  child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacingXLarge),
                child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AuthBrandHeader(),
                        const SizedBox(height: AppSizes.spacingXLarge),
                        TextFormField(
                          controller: _emailController,
                          enabled: !busy,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                              labelText: AppStrings.emailLabel,
                              prefixIcon: Icon(Icons.alternate_email_rounded)),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !busy,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                              labelText: AppStrings.passwordLabel,
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: busy
                                    ? null
                                    : () => setState(
                                        () => _hidePassword = !_hidePassword),
                                icon: Icon(_hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                tooltip: _hidePassword
                                    ? AppStrings.showPassword
                                    : AppStrings.hidePassword,
                              )),
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _login(),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: AppSizes.spacingMedium),
                          AuthErrorMessage(error),
                        ],
                        const SizedBox(height: AppSizes.spacingLarge),
                        FilledButton.icon(
                          onPressed: busy ? null : _login,
                          icon: busy
                              ? const SizedBox(
                                  width: AppSizes.spacingLarge,
                                  height: AppSizes.spacingLarge,
                                  child: CircularProgressIndicator())
                              : const Icon(Icons.login_rounded),
                          label: Text(
                              busy ? AppStrings.signingIn : AppStrings.signIn),
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                        Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(AppStrings.dontHaveAccount),
                              TextButton(
                                  onPressed: busy
                                      ? null
                                      : () {
                                          widget.controller.clearError();
                                          Navigator.pushNamed(
                                              context, AppRoutes.register);
                                        },
                                  child:
                                      const Text(AppStrings.registrationTitle)),
                            ]),
                      ],
                    )),
              )),
            ),
          ))));
        },
      );
}
