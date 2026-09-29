import '../../domain/entities/object_image_analysis.dart';

class ObjectImageAnalysisModel extends ObjectImageAnalysis {
  const ObjectImageAnalysisModel({
    required super.objectDetected,
    required super.objectType,
    required super.category,
    required super.primaryColor,
    required super.secondaryColors,
    required super.brand,
    required super.shape,
    required super.visibleFeatures,
    required super.visibleText,
    required super.imageQuality,
    required super.confidence,
    required super.requiresAnotherPhoto,
    required super.warnings,
  });

  factory ObjectImageAnalysisModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ObjectImageAnalysisModel(
      objectDetected: _requiredBool(
        json,
        'object_detected',
      ),
      objectType: _optionalString(
        json,
        'object_type',
      ),
      category: _requiredString(
        json,
        'category',
      ),
      primaryColor: _optionalString(
        json,
        'primary_color',
      ),
      secondaryColors: _stringList(
        json,
        'secondary_colors',
      ),
      brand: _optionalString(
        json,
        'brand',
      ),
      shape: _optionalString(
        json,
        'shape',
      ),
      visibleFeatures: _stringList(
        json,
        'visible_features',
      ),
      visibleText: _stringList(
        json,
        'visible_text',
      ),
      imageQuality: _requiredString(
        json,
        'image_quality',
      ),
      confidence: _requiredString(
        json,
        'confidence',
      ),
      requiresAnotherPhoto: _requiredBool(
        json,
        'requires_another_photo',
      ),
      warnings: _stringList(
        json,
        'warnings',
      ),
    );
  }

  static bool _requiredBool(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];

    if (value is bool) {
      return value;
    }

    throw FormatException('El campo $key no es válido.');
  }

  static String _requiredString(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    throw FormatException('El campo $key no es válido.');
  }

  static String? _optionalString(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is String) {
      final normalized = value.trim();
      return normalized.isEmpty ? null : normalized;
    }

    throw FormatException('El campo $key no es válido.');
  }

  static List<String> _stringList(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];

    if (value is! List) {
      throw FormatException('El campo $key no es válido.');
    }

    return value
        .map((item) {
          if (item is! String) {
            throw FormatException(
              'El campo $key contiene un valor no válido.',
            );
          }

          return item.trim();
        })
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
