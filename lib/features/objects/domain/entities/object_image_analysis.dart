class ObjectImageAnalysis {
  const ObjectImageAnalysis({
    required this.objectDetected,
    required this.objectType,
    required this.category,
    required this.primaryColor,
    required this.secondaryColors,
    required this.brand,
    required this.shape,
    required this.visibleFeatures,
    required this.visibleText,
    required this.imageQuality,
    required this.confidence,
    required this.requiresAnotherPhoto,
    required this.warnings,
  });

  final bool objectDetected;
  final String? objectType;
  final String category;
  final String? primaryColor;
  final List<String> secondaryColors;
  final String? brand;
  final String? shape;
  final List<String> visibleFeatures;
  final List<String> visibleText;
  final String imageQuality;
  final String confidence;
  final bool requiresAnotherPhoto;
  final List<String> warnings;
}
