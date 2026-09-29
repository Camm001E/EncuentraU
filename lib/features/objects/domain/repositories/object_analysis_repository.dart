import '../entities/object_image_analysis.dart';
import '../entities/object_image_input.dart';

abstract interface class ObjectAnalysisRepository {
  Future<ObjectImageAnalysis> analyzeImage(ObjectImageInput input);
}