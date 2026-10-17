import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_durations.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../models/app_user_model.dart';
import '../models/auth_session_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({required http.Client client}) : _client = client;
  final http.Client _client;

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
        throw AuthException(switch (response.statusCode) {
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
