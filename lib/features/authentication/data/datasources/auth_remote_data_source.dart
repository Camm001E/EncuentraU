import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_durations.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/email_verifier.dart';
import '../../domain/repositories/password_recoverer.dart';
import '../models/app_user_model.dart';
import '../models/auth_session_model.dart';

class AuthRemoteDataSource implements EmailVerifier, PasswordRecoverer {
  AuthRemoteDataSource({required http.Client client}) : _client = client;
  final http.Client _client;

  @override
  Future<VerificationRequestResult> requestCode(
      {required String email, required String password}) async {
    final result = await _verification(
        'request', {'email': email.trim().toLowerCase(), 'password': password});
    if (result['status'] != 'sent' && result['status'] != 'already_verified') {
      throw const AuthException(AuthFailure.invalidResponse);
    }
    return VerificationRequestResult(
        alreadyVerified: result['status'] == 'already_verified',
        retryAfter:
            result['retry_after'] is int ? result['retry_after'] as int : 60);
  }

  @override
  Future<void> confirmCode(
      {required String email,
      required String password,
      required String code}) async {
    final result = await _verification('confirm', {
      'email': email.trim().toLowerCase(),
      'password': password,
      'code': code.trim()
    });
    if (result['status'] != 'verified')
      throw const AuthException(AuthFailure.invalidResponse);
  }

  Future<Map<String, dynamic>> _verification(
          String action, Map<String, String> body) =>
      _request(() => _client.post(
          Uri.parse('${ApiConstants.baseUrl}/api/v1/auth/verification/$action'),
          headers: ApiConstants.jsonHeaders,
          body: jsonEncode(body)));

  @override
  Future<int> requestPasswordRecovery({required String email}) async {
    final result = await _passwordRecovery(
        'request', {'email': email.trim().toLowerCase()});
    if (result['status'] != 'accepted')
      throw const AuthException(AuthFailure.invalidResponse);
    return result['retry_after'] is int ? result['retry_after'] as int : 60;
  }

  @override
  Future<void> confirmPasswordRecovery(
      {required String email,
      required String code,
      required String password}) async {
    final result = await _passwordRecovery('confirm', {
      'email': email.trim().toLowerCase(),
      'code': code.trim(),
      'new_password': password,
    });
    if (result['status'] != 'password_reset')
      throw const AuthException(AuthFailure.invalidResponse);
  }

  Future<Map<String, dynamic>> _passwordRecovery(
          String action, Map<String, String> body) =>
      _request(() => _client.post(
          Uri.parse('${ApiConstants.baseUrl}/api/v1/auth/password/$action'),
          headers: ApiConstants.jsonHeaders,
          body: jsonEncode(body)));

  Future<AppUserModel> register({
    required String fullName,
    required String email,
    required String studentCode,
    required String password,
  }) async =>
      AppUserModel.fromJson(await _request(
        () => _client.post(
          ApiConstants.authRegisterUri,
          headers: ApiConstants.jsonHeaders,
          body: jsonEncode({
            'full_name': fullName,
            'email': email,
            'student_code': studentCode,
            'password': password,
          }),
        ),
        expectedStatus: ApiConstants.created,
      ));

  Future<AuthSessionModel> login(
          {required String email, required String password}) async =>
      AuthSessionModel.fromJson(await _request(
        () => _client.post(
          ApiConstants.authLoginUri,
          headers: ApiConstants.jsonHeaders,
          body: jsonEncode({'email': email, 'password': password}),
        ),
      ));

  Future<AppUserModel> getCurrentUser(String token) async =>
      AppUserModel.fromJson(await _request(
        () => _client.get(ApiConstants.authMeUri, headers: {
          ...ApiConstants.jsonHeaders,
          ApiConstants.authorizationHeader: 'Bearer $token',
        }),
        unauthorizedFailure: AuthFailure.sessionExpired,
      ));

  Future<Map<String, dynamic>> _request(
    Future<http.Response> Function() send, {
    int expectedStatus = ApiConstants.ok,
    AuthFailure unauthorizedFailure = AuthFailure.invalidCredentials,
  }) async {
    try {
      final response = await send().timeout(AppDurations.authRequestTimeout);
      if (response.statusCode != expectedStatus) {
        if (response.statusCode == 403) {
          try {
            final body = jsonDecode(utf8.decode(response.bodyBytes));
            if (body is Map && body['code'] == 'email_verification_required') {
              throw const AuthException(AuthFailure.emailUnverified);
            }
          } on FormatException {/* Keep the generic forbidden response. */}
        }
        if (response.statusCode == 429) {
          throw AuthException(AuthFailure.rateLimited,
              retryAfter:
                  int.tryParse(response.headers['retry-after'] ?? '') ?? 60);
        }
        throw AuthException(switch (response.statusCode) {
          400 => AuthFailure.verificationCode,
          ApiConstants.unauthorized => unauthorizedFailure,
          ApiConstants.forbidden => AuthFailure.inactiveAccount,
          ApiConstants.conflict => AuthFailure.duplicateAccount,
          ApiConstants.unprocessable => AuthFailure.invalidData,
          >= ApiConstants.serverError && <= ApiConstants.lastServerError =>
            AuthFailure.server,
          _ => AuthFailure.invalidResponse,
        });
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) {
        throw const AuthException(AuthFailure.invalidResponse);
      }
      return body;
    } on AuthException {
      rethrow;
    } on FormatException {
      throw const AuthException(AuthFailure.invalidResponse);
    } catch (_) {
      throw const AuthException(AuthFailure.connection);
    }
  }
}
