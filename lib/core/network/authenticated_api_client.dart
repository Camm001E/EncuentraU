import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../constants/app_durations.dart';
import '../errors/api_exception.dart';
import '../session/session_manager.dart';

class AuthenticatedApiClient {
  const AuthenticatedApiClient(
      {required http.Client client,
      required SessionManager session,
      this.timeout = AppDurations.apiRequestTimeout,
      this.transferTimeout = AppDurations.imageTransferTimeout})
      : _client = client,
        _session = session;
  final http.Client _client;
  final SessionManager _session;
  final Duration timeout;
  final Duration transferTimeout;

  Future<Map<String, dynamic>?> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    int expectedStatus = ApiConstants.ok,
  }) async {
    final req = http.Request(method, ApiConstants.uri(path, query))
      ..headers.addAll(ApiConstants.jsonHeaders);
    if (body != null) req.body = jsonEncode(body);
    final response = await _send(req, expectedStatus: expectedStatus);
    if (expectedStatus == ApiConstants.noContent) return null;
    return _json(response);
  }

  Map<String, dynamic> _json(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return decoded;
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<Map<String, dynamic>> uploadImage(
      String path, List<int> bytes, String filename, String contentType) async {
    if (bytes.length > ApiConstants.reportImageMaxBytes)
      throw const ApiException(ApiFailure.imageTooLarge);
    if (filename.isEmpty || RegExp(r'[\\/:\x00-\x1f]').hasMatch(filename))
      throw const ApiException(ApiFailure.invalidData);
    if (bytes.isEmpty ||
        !ApiConstants.allowedImageMimeTypes.contains(contentType))
      throw const ApiException(ApiFailure.unsupportedImage);
    final request = http.MultipartRequest('PUT', ApiConstants.uri(path))
      ..headers['Accept'] = ApiConstants.jsonHeaders['Accept']!
      ..files.add(http.MultipartFile.fromBytes(ApiConstants.imageField, bytes,
          filename: filename, contentType: MediaType.parse(contentType)));
    return _json(await _send(request, requestTimeout: transferTimeout));
  }

  Future<Uint8List> downloadImage(String path) async {
    final request = http.Request('GET', ApiConstants.uri(path))
      ..headers['Accept'] = ApiConstants.allowedImageMimeTypes.join(', ');
    final response = await _send(request,
        requestTimeout: transferTimeout,
        maxBytes: ApiConstants.reportImageMaxBytes);
    final type = response.headers['content-type']?.split(';').first.trim();
    if (!ApiConstants.allowedImageMimeTypes.contains(type) ||
        response.bodyBytes.isEmpty)
      throw const ApiException(ApiFailure.invalidResponse);
    return response.bodyBytes;
  }

  Future<http.Response> _send(http.BaseRequest request,
      {int expectedStatus = ApiConstants.ok,
      Duration? requestTimeout,
      int? maxBytes}) async {
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
    request.headers[ApiConstants.authorizationHeader] =
        '${ApiConstants.bearerPrefix}$token';
    try {
      final response = await (() async {
        final stream = await _client.send(request);
        if (maxBytes == null || stream.statusCode != expectedStatus)
          return http.Response.fromStream(stream);
        final builder = BytesBuilder(copy: false);
        await for (final chunk in stream.stream) {
          if (builder.length + chunk.length > maxBytes)
            throw const ApiException(ApiFailure.invalidResponse);
          builder.add(chunk);
        }
        return http.Response.bytes(builder.takeBytes(), stream.statusCode,
            headers: stream.headers);
      })()
          .timeout(requestTimeout ?? timeout);
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
          ApiConstants.payloadTooLarge => ApiFailure.imageTooLarge,
          ApiConstants.unsupportedMediaType => ApiFailure.unsupportedImage,
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
      return response;
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
