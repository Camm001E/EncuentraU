import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_validation.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_error_message.dart';
import '../widgets/auth_layout.dart';
import '../../../../core/presentation/widgets/design_system.dart';

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
    if (widget.controller.isBusy) return;
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
    widget.controller.clearError();
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
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
    if (value.trim().length > AppValidation.maximumFullNameLength) {
      return AppStrings.fieldTooLong;
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
    if (value.trim().length > AppValidation.maximumEmailLength) {
      return AppStrings.fieldTooLong;
    }

    return null;
  }

  String? _validateStudentCode(String? value) {
    final requiredError = _validateRequired(value);

    if (requiredError != null) {
      return requiredError;
    }

    if (!AppValidation.isValidStudentCode(value!) ||
        value.trim().length > AppValidation.maximumStudentCodeLength) {
      return AppStrings.invalidStudentCode;
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.requiredField;

    if (value.length < AppValidation.minimumPasswordLength) {
      return AppStrings.passwordMinLength;
    }
    if (value.length > AppValidation.maximumPasswordLength) {
      return AppStrings.fieldTooLong;
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.requiredField;

    if (value != _passwordController.text) {
      return AppStrings.passwordsDoNotMatch;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final busy = widget.controller.isRegistering;
        return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.registrationTitle)),
            body: AuthLayout(
                child: AutofillGroup(
                    child: Form(
                        key: _formKey,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const AuthBrandHeader(),
                              const SizedBox(height: AppSizes.spacingLarge),
                              Text(AppStrings.registrationTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              const SizedBox(height: AppSizes.spacingSmall),
                              const Text(AppStrings.registrationSubtitle),
                              const SizedBox(height: AppSizes.spacingLarge),
                              TextFormField(
                                  controller: _fullNameController,
                                  enabled: !busy,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  autofillHints: const [AutofillHints.name],
                                  decoration: const InputDecoration(
                                      labelText: AppStrings.fullNameLabel,
                                      prefixIcon: Icon(Icons.person_outline)),
                                  validator: _validateFullName),
                              const SizedBox(height: AppSizes.spacingMedium),
                              TextFormField(
                                  controller: _emailController,
                                  enabled: !busy,
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(
                                      labelText: AppStrings.emailLabel,
                                      prefixIcon: Icon(Icons.alternate_email)),
                                  validator: _validateEmail),
                              const SizedBox(height: AppSizes.spacingMedium),
                              TextFormField(
                                  controller: _studentCodeController,
                                  enabled: !busy,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                      labelText: AppStrings.studentCodeLabel,
                                      prefixIcon: Icon(Icons.badge_outlined)),
                                  validator: _validateStudentCode),
                              const SizedBox(height: AppSizes.spacingMedium),
                              TextFormField(
                                  controller: _passwordController,
                                  enabled: !busy,
                                  obscureText: _obscurePassword,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.newPassword
                                  ],
                                  decoration: InputDecoration(
                                      labelText: AppStrings.passwordLabel,
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                          tooltip: _obscurePassword
                                              ? AppStrings.showPassword
                                              : AppStrings.hidePassword,
                                          onPressed: busy
                                              ? null
                                              : () => setState(() =>
                                                  _obscurePassword =
                                                      !_obscurePassword),
                                          icon: Icon(_obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons
                                                  .visibility_off_outlined))),
                                  validator: _validatePassword),
                              const SizedBox(height: AppSizes.spacingMedium),
                              TextFormField(
                                  controller: _confirmPasswordController,
                                  enabled: !busy,
                                  obscureText: _obscureConfirmPassword,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [
                                    AutofillHints.newPassword
                                  ],
                                  decoration: InputDecoration(
                                      labelText:
                                          AppStrings.confirmPasswordLabel,
                                      prefixIcon:
                                          const Icon(Icons.lock_reset_outlined),
                                      suffixIcon: IconButton(
                                          tooltip: _obscureConfirmPassword
                                              ? AppStrings.showPassword
                                              : AppStrings.hidePassword,
                                          onPressed: busy
                                              ? null
                                              : () => setState(() =>
                                                  _obscureConfirmPassword =
                                                      !_obscureConfirmPassword),
                                          icon: Icon(_obscureConfirmPassword
                                              ? Icons.visibility_outlined
                                              : Icons
                                                  .visibility_off_outlined))),
                                  validator: _validateConfirmPassword,
                                  onFieldSubmitted: (_) => _submit()),
                              if (widget.controller.errorMessage
                                  case final error?) ...[
                                const SizedBox(height: AppSizes.spacingMedium),
                                AuthErrorMessage(error)
                              ],
                              const SizedBox(height: AppSizes.spacingLarge),
                              PrimaryAction(
                                  label: AppStrings.registerButton,
                                  onPressed: _submit,
                                  busy: busy,
                                  icon: Icons.person_add_alt_1_outlined),
                              const SizedBox(height: AppSizes.spacingMedium),
                              Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(AppStrings.alreadyHaveAccount),
                                    TextButton(
                                        onPressed: busy ? null : _goToLogin,
                                        child: const Text(AppStrings.signIn)),
                                  ]),
                            ])))));
      });
}
