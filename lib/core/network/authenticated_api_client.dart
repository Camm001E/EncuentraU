import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../constants/app_durations.dart';
import '../errors/api_exception.dart';
import '../session/session_manager.dart';

class AuthenticatedApiClient {
  const AuthenticatedApiClient(
      {required http.Client client,
      required SessionManager session,
      this.timeout = AppDurations.apiRequestTimeout})
      : _client = client,
        _session = session;
  final http.Client _client;
  final SessionManager _session;
  final Duration timeout;

  Future<Map<String, dynamic>?> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    int expectedStatus = ApiConstants.ok,
  }) async {
    final generation = _session.generation;
    if (!_session.active) throw const ApiException(ApiFailure.unauthorized);
    String? token;
    try {
      token = await _session.readToken().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(ApiFailure.timeout);
    } catch (_) {
      throw const ApiException(ApiFailure.storage);
    }
    if (generation != _session.generation)
      throw const ApiException(ApiFailure.unauthorized);
    if (token == null || token.trim().isEmpty) {
      await _session.invalidate(generation, ApiFailure.unauthorized);
      throw const ApiException(ApiFailure.unauthorized);
    }
    try {
      final req = http.Request(method, ApiConstants.uri(path, query))
        ..headers.addAll({
          ...ApiConstants.jsonHeaders,
          ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix}$token'
        });
      if (body != null) req.body = jsonEncode(body);
      final response = await (() async {
        final streamed = await _client.send(req);
        return http.Response.fromStream(streamed);
      })()
          .timeout(timeout);
      if (generation != _session.generation)
        throw const ApiException(ApiFailure.unauthorized);
      if (response.statusCode != expectedStatus) {
        final failure = switch (response.statusCode) {
          ApiConstants.badRequest ||
          ApiConstants.unprocessable =>
            ApiFailure.invalidData,
          ApiConstants.unauthorized => ApiFailure.unauthorized,
          ApiConstants.forbidden => ApiFailure.forbidden,
          ApiConstants.notFound => ApiFailure.notFound,
          ApiConstants.conflict => ApiFailure.conflict,
          >= ApiConstants.serverError && <= ApiConstants.lastServerError =>
            ApiFailure.server,
          _ => ApiFailure.invalidResponse,
        };
        if (failure == ApiFailure.unauthorized ||
            failure == ApiFailure.forbidden) {
          await _session.invalidate(generation, failure);
        }
        throw ApiException(failure);
      }
      if (expectedStatus == ApiConstants.noContent) return null;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(ApiFailure.timeout);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    } catch (_) {
      throw const ApiException(ApiFailure.connection);
    }
  }
}
