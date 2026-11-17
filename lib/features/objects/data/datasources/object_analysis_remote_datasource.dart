import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/object_image_input.dart';
import '../../domain/exceptions/object_analysis_exception.dart';
import '../models/object_image_analysis_model.dart';

class ObjectAnalysisRemoteDataSource {
  ObjectAnalysisRemoteDataSource({
    required AuthenticatedApiClient api,
  }) : _api = api;

  final AuthenticatedApiClient _api;

  Future<ObjectImageAnalysisModel> analyzeImage(
    ObjectImageInput input,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      ApiConstants.analyzeObjectImageUri,
    )
      ..fields[ApiConstants.descriptionField] = input.description.trim()
      ..files.add(
        http.MultipartFile.fromBytes(
          ApiConstants.imageField,
          input.bytes,
          filename: input.fileName,
          contentType: MediaType.parse(input.mimeType),
        ),
      );

    try {
      final response = await _api.sendMultipart(request,
          requestTimeout: AppDurations.aiAnalysisTimeout);

      final body = _decodeBody(response.bodyBytes);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ObjectAnalysisException(
          _errorMessage(response.statusCode, body),
        );
      }

      if (body is! Map<String, dynamic>) {
        throw const ObjectAnalysisException(
          AppStrings.invalidAnalysisResponse,
        );
      }

      try {
        return ObjectImageAnalysisModel.fromJson(body);
      } on FormatException {
        throw const ObjectAnalysisException(
          AppStrings.invalidAnalysisResponse,
        );
      }
    } on ApiException catch (error) {
      throw ObjectAnalysisException(switch (error.failure) {
        ApiFailure.rateLimited => AppStrings.aiQuotaReached,
        ApiFailure.unauthorized ||
        ApiFailure.forbidden =>
          AppStrings.sessionExpired,
        ApiFailure.imageTooLarge => AppStrings.imageTooLarge,
        ApiFailure.unsupportedImage => AppStrings.unsupportedImage,
        ApiFailure.timeout => AppStrings.analysisTimeout,
        ApiFailure.connection => AppStrings.networkError,
        _ => AppStrings.analysisUnavailable,
      });
    } on TimeoutException {
      throw const ObjectAnalysisException(
        AppStrings.analysisTimeout,
      );
    } on http.ClientException {
      throw const ObjectAnalysisException(
        AppStrings.networkError,
      );
    } on ObjectAnalysisException {
      rethrow;
    } catch (_) {
      throw const ObjectAnalysisException(
        AppStrings.networkError,
      );
    }
  }

  dynamic _decodeBody(List<int> bytes) {
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return null;
    }
  }

  String _errorMessage(
    int statusCode,
    dynamic body,
  ) {
    if (statusCode == ApiConstants.payloadTooLarge) {
      return AppStrings.imageTooLarge;
    }

    if (statusCode == ApiConstants.unsupportedMediaType) {
      return AppStrings.unsupportedImage;
    }

    return AppStrings.analysisUnavailable;
  }
}
