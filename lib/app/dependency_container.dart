import '../features/authentication/data/datasources/auth_mock_data_source.dart';
import '../features/authentication/data/repositories/auth_repository_impl.dart';
import '../features/authentication/domain/usecases/register_user.dart';
import '../features/authentication/presentation/controllers/auth_controller.dart';
import '../features/matching/domain/usecases/find_matches.dart';
import '../features/objects/data/datasources/object_analysis_remote_datasource.dart';
import '../features/objects/data/datasources/object_mock_datasource.dart';
import '../features/objects/data/repositories/object_analysis_repository_impl.dart';
import '../features/objects/data/repositories/object_repository_impl.dart';
import '../features/objects/domain/usecases/analyze_object_image.dart';
import '../features/objects/domain/usecases/get_objects.dart';
import '../features/objects/domain/usecases/register_object.dart';
import '../features/objects/presentation/controllers/object_analysis_controller.dart';
import '../features/objects/presentation/controllers/object_controller.dart';

class DependencyContainer {
  const DependencyContainer({
    required this.objectController,
    required this.findMatches,
    required this.authController,
    required this.objectAnalysisController,
  });

  final ObjectController objectController;
  final FindMatches findMatches;
  final AuthController authController;
  final ObjectAnalysisController objectAnalysisController;

  static DependencyContainer create() {
    // Dependencias para los objetos simulados.
    final objectDataSource = ObjectMockDataSource();
    final objectRepository = ObjectRepositoryImpl(
      objectDataSource,
    );

    // Dependencias para el registro simulado.
    final authDataSource = AuthMockDataSource();
    final authRepository = AuthRepositoryImpl(
      authDataSource,
    );

    // Dependencias para el análisis real de imágenes.
    final objectAnalysisDataSource = ObjectAnalysisRemoteDataSource();

    final objectAnalysisRepository = ObjectAnalysisRepositoryImpl(
      objectAnalysisDataSource,
    );

    return DependencyContainer(
      objectController: ObjectController(
        getObjects: GetObjects(objectRepository),
        registerObject: RegisterObject(objectRepository),
      ),
      findMatches: const FindMatches(),
      authController: AuthController(
        RegisterUser(authRepository),
      ),
      objectAnalysisController: ObjectAnalysisController(
        AnalyzeObjectImage(objectAnalysisRepository),
      ),
    );
  }
}
