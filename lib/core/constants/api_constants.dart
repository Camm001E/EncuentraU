abstract final class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String analyzeObjectImagePath = '/api/v1/ai/analyze';
  static const String authRegisterPath = '/api/v1/auth/register';
  static const String authLoginPath = '/api/v1/auth/login';
  static const String authMePath = '/api/v1/auth/me';
  static const String authorizationHeader = 'Authorization';
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  static const int ok = 200;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int notFound = 404;
  static const int payloadTooLarge = 413;
  static const int unsupportedMediaType = 415;
  static const int created = 201;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int conflict = 409;
  static const int unprocessable = 422;
  static const int serverError = 500;
  static const int lastServerError = 599;
  static const String bearerPrefix = 'Bearer ';
  static const String reportsPath = '/api/v1/reports';
  static const String myReportsPath = '$reportsPath/me';
  static const String matchesPath = '/api/v1/matches';
  static const String myMatchesPath = '$matchesPath/me';
  static String reportPath(String id) =>
      '$reportsPath/${Uri.encodeComponent(id)}';
  static String matchPath(String id) =>
      '$matchesPath/${Uri.encodeComponent(id)}';
  static String generateMatchesPath(String id) =>
      '${reportPath(id)}/matches/generate';
  static String reportImagePath(String id) => '${reportPath(id)}/image';
  static String reportImageContentPath(String id) =>
      '${reportImagePath(id)}/content';
  static const int reportImageMaxBytes = 8388608;
  static const int imageCacheMaxBytes = 16777216;
  static const int imageCacheMaxEntries = 32;
  static Uri uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);
  static const String limitParameter = 'limit';
  static const String offsetParameter = 'offset';
  static const String reportTypeParameter = 'report_type';
  static const String statusParameter = 'status';
  static const String levelParameter = 'level';
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int maxPercentage = 100;
  static const int objectTypeMaxLength = 200;
  static const int categoryMaxLength = 100;
  static const int colorMaxLength = 100;
  static const int brandMaxLength = 100;
  static const int shapeMaxLength = 500;
  static const int descriptionMaxLength = 5000;
  static const int locationMaxLength = 300;
  static const int privateFeatureMaxLength = 2000;
  static const int maxSecondaryColors = 20;

  static const String imageField = 'image';
  static const String descriptionField = 'description';

  static const int minimumAnalysisDescriptionLength = 3;
  static const int maxImageSizeMb = 10;
  static const int maxImageSizeBytes = maxImageSizeMb * 1024 * 1024;

  static const Set<String> allowedImageMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  static Uri get analyzeObjectImageUri =>
      Uri.parse('$baseUrl$analyzeObjectImagePath');
  static Uri get authRegisterUri => Uri.parse('$baseUrl$authRegisterPath');
  static Uri get authLoginUri => Uri.parse('$baseUrl$authLoginPath');
  static Uri get authMeUri => Uri.parse('$baseUrl$authMePath');
}
