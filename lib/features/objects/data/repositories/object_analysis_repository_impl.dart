import '../../domain/entities/object_image_analysis.dart';
import '../../domain/entities/object_image_input.dart';
import '../../domain/repositories/object_analysis_repository.dart';
import '../datasources/object_analysis_remote_datasource.dart';

class ObjectAnalysisRepositoryImpl implements ObjectAnalysisRepository {
  const ObjectAnalysisRepositoryImpl(this.dataSource);

  final ObjectAnalysisRemoteDataSource dataSource;

  @override
  Future<ObjectImageAnalysis> analyzeImage(
    ObjectImageInput input,
  ) {
    return dataSource.analyzeImage(input);
  }
}
