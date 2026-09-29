import '../entities/object_image_analysis.dart';
import '../entities/object_image_input.dart';
import '../repositories/object_analysis_repository.dart';

class AnalyzeObjectImage {
  const AnalyzeObjectImage(this.repository);

  final ObjectAnalysisRepository repository;

  Future<ObjectImageAnalysis> call(ObjectImageInput input) {
    return repository.analyzeImage(input);
  }
}