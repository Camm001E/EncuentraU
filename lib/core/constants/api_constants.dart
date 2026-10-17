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
  static const int created = 201;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int conflict = 409;
  static const int unprocessable = 422;
  static const int serverError = 500;
  static const int lastServerError = 599;

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
