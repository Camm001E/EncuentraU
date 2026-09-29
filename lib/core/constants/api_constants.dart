abstract final class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String analyzeObjectImagePath = '/api/v1/ai/analyze';

  static const String imageField = 'image';
  static const String descriptionField = 'description';

  static const int minimumAnalysisDescriptionLength = 3;
  static const int maxImageSizeMb = 10;
  static const int maxImageSizeBytes =
      maxImageSizeMb * 1024 * 1024;

  static const Set<String> allowedImageMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  static Uri get analyzeObjectImageUri =>
      Uri.parse('$baseUrl$analyzeObjectImagePath');
}