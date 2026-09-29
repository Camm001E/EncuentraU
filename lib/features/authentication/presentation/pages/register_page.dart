import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_validation.dart';
import '../controllers/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _studentCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    widget.controller.clearError();

    final formIsValid = _formKey.currentState?.validate() ?? false;

    if (!formIsValid) {
      return;
    }

    final registered = await widget.controller.register(
      fullName: _fullNameController.text,
      email: _emailController.text,
      studentCode: _studentCodeController.text,
      password: _passwordController.text,
    );

    if (!mounted || !registered) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(AppStrings.accountCreated),
          duration: AppDurations.snackBar,
        ),
      );

    _goToLogin();
  }

  void _goToLogin() {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed(AppRoutes.login);
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }

    return null;
  }

  String? _validateFullName(String? value) {
    final requiredError = _validateRequired(value);

    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length < AppValidation.minimumFullNameLength) {
      return AppStrings.invalidFullName;
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final requiredError = _validateRequired(value);

    if (requiredError != null) {
      return requiredError;
    }

    if (!AppValidation.isValidEmail(value!)) {
      return AppStrings.invalidEmail;
    }

    return null;
  }

  String? _validateStudentCode(String? value) {
    final requiredError = _validateRequired(value);

    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length < AppValidation.minimumStudentCodeLength) {
      return AppStrings.invalidStudentCode;
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final requiredError = _validateRequired(value);

    if (requiredError != null) {
      return requiredError;
    }

    if (value!.length < AppValidation.minimumPasswordLength) {
      return AppStrings.passwordMinLength;
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final requiredError = _validateRequired(value);

    if (requiredError != null) {
      return requiredError;
    }

    if (value != _passwordController.text) {
      return AppStrings.passwordsDoNotMatch;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final isRegistering = widget.controller.isRegistering;
        final errorMessage = widget.controller.errorMessage;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.registrationTitle),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.spacingLarge),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.formMaxWidth,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CircleAvatar(
                          radius: AppSizes.spacingXLarge,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          child: const Icon(Icons.person_add_alt_1),
                        ),
                        const SizedBox(height: AppSizes.spacingLarge),
                        Text(
                          AppStrings.registrationTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingSmall),
                        Text(
                          AppStrings.registrationSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSizes.spacingXLarge),
                        TextFormField(
                          controller: _fullNameController,
                          enabled: !isRegistering,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: AppStrings.fullNameLabel,
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: _validateFullName,
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                        TextFormField(
                          controller: _emailController,
                          enabled: !isRegistering,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: AppStrings.emailLabel,
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                        TextFormField(
                          controller: _studentCodeController,
                          enabled: !isRegistering,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: AppStrings.studentCodeLabel,
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: _validateStudentCode,
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !isRegistering,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: AppStrings.passwordLabel,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                        TextFormField(
                          controller: _confirmPasswordController,
                          enabled: !isRegistering,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: AppStrings.confirmPasswordLabel,
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: _validateConfirmPassword,
                          onFieldSubmitted: (_) {
                            if (!isRegistering) {
                              _submit();
                            }
                          },
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: AppSizes.spacingMedium),
                          Container(
                            padding: const EdgeInsets.all(
                              AppSizes.spacingMedium,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLarge,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                                const SizedBox(
                                  width: AppSizes.spacingSmall,
                                ),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSizes.spacingLarge),
                        FilledButton(
                          onPressed: isRegistering ? null : _submit,
                          child: isRegistering
                              ? const SizedBox(
                                  width: AppSizes.spacingLarge,
                                  height: AppSizes.spacingLarge,
                                  child: CircularProgressIndicator(),
                                )
                              : const Text(AppStrings.registerButton),
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(AppStrings.alreadyHaveAccount),
                            TextButton(
                              onPressed: isRegistering ? null : _goToLogin,
                              child: const Text(AppStrings.signIn),
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
        );
      },
    );
  }
}
