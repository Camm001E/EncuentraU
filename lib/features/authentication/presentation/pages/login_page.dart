import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_validation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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

  void _login() {
    final formIsValid = _formKey.currentState?.validate() ?? false;

    if (!formIsValid) {
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _openRegister() {
    Navigator.pushNamed(context, AppRoutes.register);
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }

    if (!AppValidation.isValidEmail(value)) {
      return AppStrings.invalidEmail;
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }

    if (value.length < AppValidation.minimumPasswordLength) {
      return AppStrings.passwordMinLength;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.spacingLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.formMaxWidth,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spacingXLarge),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _BrandHeader(),
                        const SizedBox(height: AppSizes.spacingXLarge),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: AppStrings.emailLabel,
                            prefixIcon: Icon(
                              Icons.alternate_email_rounded,
                            ),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: AppStrings.passwordLabel,
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _hidePassword = !_hidePassword;
                                });
                              },
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              tooltip: _hidePassword
                                  ? AppStrings.showPassword
                                  : AppStrings.hidePassword,
                            ),
                          ),
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: AppSizes.spacingLarge),
                        FilledButton.icon(
                          onPressed: _login,
                          icon: const Icon(Icons.login_rounded),
                          label: const Text(AppStrings.signIn),
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                        Text(
                          AppStrings.simulatedAccessMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(AppStrings.dontHaveAccount),
                            TextButton(
                              onPressed: _openRegister,
                              child: const Text(
                                AppStrings.registrationTitle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CircleAvatar(
          radius: AppSizes.spacingXLarge,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: const Icon(Icons.travel_explore_rounded),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        Text(
          AppStrings.appName,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSizes.spacingSmall),
        Text(
          AppStrings.loginSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
