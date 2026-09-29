import '../features/authentication/data/datasources/auth_mock_data_source.dart';
import '../features/authentication/data/repositories/auth_repository_impl.dart';
import '../features/authentication/domain/usecases/register_user.dart';
import '../features/authentication/presentation/controllers/auth_controller.dart';
import '../features/matching/domain/usecases/find_matches.dart';
import '../features/objects/data/datasources/object_mock_datasource.dart';
import '../features/objects/data/repositories/object_repository_impl.dart';
import '../features/objects/domain/usecases/get_objects.dart';
import '../features/objects/domain/usecases/register_object.dart';
import '../features/objects/presentation/controllers/object_controller.dart';

class DependencyContainer {
  const DependencyContainer({
    required this.objectController,
    required this.findMatches,
    required this.authController,
  });

  final ObjectController objectController;
  final FindMatches findMatches;
  final AuthController authController;

  static DependencyContainer create() {
    final objectDataSource = ObjectMockDataSource();
    final objectRepository = ObjectRepositoryImpl(objectDataSource);

    final authDataSource = AuthMockDataSource();
    final authRepository = AuthRepositoryImpl(authDataSource);

    return DependencyContainer(
      objectController: ObjectController(
        getObjects: GetObjects(objectRepository),
        registerObject: RegisterObject(objectRepository),
      ),
      findMatches: const FindMatches(),
      authController: AuthController(
        RegisterUser(authRepository),
      ),
    );
  }
}
