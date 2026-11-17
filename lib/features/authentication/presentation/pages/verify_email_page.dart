import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_validation.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/email_verifier.dart';
import '../widgets/auth_layout.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage(
      {required this.verifier, this.initialEmail = '', super.key});
  final EmailVerifier? verifier;
  final String initialEmail;
  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false, _done = false;
  String? _message;
  int _wait = 0;
  Timer? _timer;

  void _cooldown(int seconds) {
    _timer?.cancel();
    _wait = seconds.clamp(0, 86400);
    if (_wait > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _wait--);
        if (_wait <= 0) timer.cancel();
      });
    }
  }

  Future<void> _perform({required bool confirm}) async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    if (confirm && !RegExp(r'^\d{8}$').hasMatch(_code.text.trim())) {
      setState(() => _message = AppStrings.emailCodeLabel);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final verifier = widget.verifier;
      if (verifier == null) throw const AuthException(AuthFailure.server);
      if (confirm) {
        await verifier.confirmCode(
            email: _email.text, password: _password.text, code: _code.text);
        if (!mounted) return;
        _done = true;
      } else {
        final result = await verifier.requestCode(
            email: _email.text, password: _password.text);
        if (!mounted) return;
        _done = result.alreadyVerified;
        _cooldown(result.retryAfter);
      }
      _message = _done ? AppStrings.emailVerified : AppStrings.emailCodeSent;
      if (_done) {
        _password.clear();
        _code.clear();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.failure == AuthFailure.rateLimited) _cooldown(e.retryAfter);
      _message = switch (e.failure) {
        AuthFailure.invalidCredentials => AppStrings.invalidCredentials,
        AuthFailure.inactiveAccount => AppStrings.inactiveAccount,
        AuthFailure.verificationCode => AppStrings.emailCodeInvalid,
        AuthFailure.rateLimited => AppStrings.emailResendWait,
        AuthFailure.connection => AppStrings.authConnectionError,
        _ => AppStrings.emailSendFailed,
      };
    } catch (_) {
      if (mounted) _message = AppStrings.emailSendFailed;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.verifyEmail)),
        body: AuthLayout(
            child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_done
                        ? AppStrings.emailVerified
                        : AppStrings.emailVerificationHelp),
                    const SizedBox(height: 24),
                    if (!_done) ...[
                      TextFormField(
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(
                              labelText: AppStrings.emailLabel),
                          validator: (value) =>
                              AppValidation.isValidEmail(value ?? '')
                                  ? null
                                  : AppStrings.invalidEmail),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: const InputDecoration(
                              labelText: AppStrings.passwordLabel),
                          validator: (value) => (value ?? '').isEmpty
                              ? AppStrings.requiredField
                              : null),
                      const SizedBox(height: 16),
                      OutlinedButton(
                          onPressed: _busy || _wait > 0
                              ? null
                              : () => _perform(confirm: false),
                          child: Text(_wait > 0
                              ? 'Reenviar en $_wait s'
                              : AppStrings.emailCodeRequest)),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _code,
                          enabled: !_busy,
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                              labelText: AppStrings.emailCodeLabel)),
                      FilledButton(
                          onPressed:
                              _busy ? null : () => _perform(confirm: true),
                          child: const Text(AppStrings.emailCodeConfirm)),
                    ],
                    if (_busy) const LinearProgressIndicator(),
                  if (_message != null && !_done)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Semantics(
                              liveRegion: true, child: Text(_message!))),
                    TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.pushNamedAndRemoveUntil(
                                context, AppRoutes.login, (_) => false),
                        child: const Text(AppStrings.signIn)),
                  ],
                ))),
      );
}
