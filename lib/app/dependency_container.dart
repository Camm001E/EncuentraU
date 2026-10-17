import 'package:http/http.dart' as http;

import '../features/authentication/data/datasources/auth_remote_data_source.dart';
import '../features/authentication/data/datasources/secure_token_storage.dart';
import '../features/authentication/data/datasources/token_storage.dart';
import '../features/authentication/data/repositories/auth_repository_impl.dart';
import '../features/authentication/domain/repositories/auth_repository.dart';
import '../features/authentication/domain/usecases/login_user.dart';
import '../features/authentication/domain/usecases/logout_user.dart';
import '../features/authentication/domain/usecases/register_user.dart';
import '../features/authentication/domain/usecases/restore_session.dart';
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
    http.Client? ownedClient,
  }) : _ownedClient = ownedClient;

  final http.Client? _ownedClient;

  final ObjectController objectController;
  final FindMatches findMatches;
  final AuthController authController;
  final ObjectAnalysisController objectAnalysisController;

  static DependencyContainer create({
    http.Client? client,
    TokenStorage? tokenStorage,
    AuthRepository? authRepository,
  }) {
    final sharedClient = client ?? http.Client();
    // Dependencias para los objetos simulados.
    final objectDataSource = ObjectMockDataSource();
    final objectRepository = ObjectRepositoryImpl(
      objectDataSource,
    );

    final repository = authRepository ??
        AuthRepositoryImpl(
          AuthRemoteDataSource(client: sharedClient),
          tokenStorage ?? const SecureTokenStorage(),
        );

    // Dependencias para el análisis real de imágenes.
    final objectAnalysisDataSource =
        ObjectAnalysisRemoteDataSource(client: sharedClient);

    final objectAnalysisRepository = ObjectAnalysisRepositoryImpl(
      objectAnalysisDataSource,
    );

    return DependencyContainer(
      ownedClient: client == null ? sharedClient : null,
      objectController: ObjectController(
        getObjects: GetObjects(objectRepository),
        registerObject: RegisterObject(objectRepository),
      ),
      findMatches: const FindMatches(),
      authController: AuthController(
        registerUser: RegisterUser(repository),
        loginUser: LoginUser(repository),
        restoreSession: RestoreSession(repository),
        logoutUser: LogoutUser(repository),
      ),
      objectAnalysisController: ObjectAnalysisController(
        AnalyzeObjectImage(objectAnalysisRepository),
      ),
    );
  }

  void dispose() {
    authController.dispose();
    objectController.dispose();
    objectAnalysisController.dispose();
    _ownedClient?.close();
  }
}
