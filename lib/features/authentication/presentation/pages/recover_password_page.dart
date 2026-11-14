import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_validation.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/password_recoverer.dart';
import '../widgets/auth_layout.dart';

class RecoverPasswordPage extends StatefulWidget {
  const RecoverPasswordPage(
      {required this.recoverer, this.initialEmail = '', super.key});
  final PasswordRecoverer? recoverer;
  final String initialEmail;
  @override
  State<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends State<RecoverPasswordPage> {
  final _emailForm = GlobalKey<FormState>();
  final _confirmForm = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false, _requested = false, _done = false;
  int _wait = 0;
  String? _message;
  Timer? _timer;

  void _cooldown(int seconds) {
    _timer?.cancel();
    _wait = seconds.clamp(0, 86400);
    if (_wait == 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _wait--);
      if (_wait <= 0) timer.cancel();
    });
  }

  Future<void> _perform({required bool confirm}) async {
    if (_busy || !(_emailForm.currentState?.validate() ?? false)) return;
    if (confirm && !(_confirmForm.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final recoverer = widget.recoverer;
      if (recoverer == null) throw const AuthException(AuthFailure.server);
      if (confirm) {
        await recoverer.confirmPasswordRecovery(
            email: _email.text, code: _code.text, password: _password.text);
        if (!mounted) return;
        _done = true;
        _password.clear();
        _repeat.clear();
        _code.clear();
        _timer?.cancel();
      } else {
        final seconds =
            await recoverer.requestPasswordRecovery(email: _email.text);
        if (!mounted) return;
        _requested = true;
        _cooldown(seconds);
        _message =
            'Si el correo corresponde a una cuenta activa y hay cupo de envío, recibirás un código. Revisa también spam. Puedes volver a solicitarlo cuando termine la espera.';
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.failure == AuthFailure.rateLimited) _cooldown(e.retryAfter);
      _message = switch (e.failure) {
        AuthFailure.verificationCode => AppStrings.emailCodeInvalid,
        AuthFailure.rateLimited => AppStrings.emailResendWait,
        AuthFailure.connection => AppStrings.authConnectionError,
        _ => 'No pudimos completar la recuperación. Intenta nuevamente.',
      };
    } catch (_) {
      if (mounted)
        _message = 'No pudimos completar la recuperación. Intenta nuevamente.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Recuperar contraseña')),
        body: AuthLayout(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_done
                ? 'Contraseña actualizada. Tus sesiones anteriores se cerraron. Inicia sesión con la nueva contraseña.'
                : 'Ingresa el correo de tu cuenta. Te enviaremos un código válido por 10 minutos para elegir una nueva contraseña.'),
            const SizedBox(height: 24),
            if (!_done) ...[
              Form(
                  key: _emailForm,
                  child: TextFormField(
                    controller: _email,
                    enabled: !_busy && !_requested,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    decoration:
                        const InputDecoration(labelText: AppStrings.emailLabel),
                    validator: (value) =>
                        AppValidation.isValidEmail(value ?? '')
                            ? null
                            : AppStrings.invalidEmail,
                  )),
              const SizedBox(height: 16),
              OutlinedButton(
                  onPressed: _busy || _wait > 0
                      ? null
                      : () => _perform(confirm: false),
                  child: Text(_wait > 0
                      ? 'Reenviar en $_wait s'
                      : 'Enviar código de recuperación')),
              if (_requested) ...[
                TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _requested = false;
                              _code.clear();
                              _password.clear();
                              _repeat.clear();
                              _message = null;
                            }),
                    child: const Text('Usar otro correo')),
                Form(
                    key: _confirmForm,
                    child: Column(children: [
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
                              labelText: 'Código de 8 dígitos'),
                          validator: (value) =>
                              RegExp(r'^\d{8}$').hasMatch(value ?? '')
                                  ? null
                                  : 'Escribe los 8 dígitos del código'),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: true,
                          enableSuggestions: false,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: const InputDecoration(
                              labelText: 'Nueva contraseña'),
                          validator: (value) => (value ?? '').length >=
                                      AppValidation.minimumPasswordLength &&
                                  (value ?? '').length <=
                                      AppValidation.maximumPasswordLength
                              ? null
                              : 'Usa entre 8 y 128 caracteres'),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _repeat,
                          enabled: !_busy,
                          obscureText: true,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: const InputDecoration(
                              labelText: 'Confirmar nueva contraseña'),
                          validator: (value) => value == _password.text
                              ? null
                              : 'Las contraseñas no coinciden'),
                      const SizedBox(height: 24),
                      FilledButton(
                          onPressed:
                              _busy ? null : () => _perform(confirm: true),
                          child: const Text('Guardar nueva contraseña')),
                    ])),
              ],
            ],
            if (_busy) const LinearProgressIndicator(),
            if (_message != null && !_done)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Semantics(liveRegion: true, child: Text(_message!))),
            TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.pushNamedAndRemoveUntil(
                        context, AppRoutes.login, (_) => false),
                child: const Text('Volver a iniciar sesión')),
          ],
        )),
      );
}
