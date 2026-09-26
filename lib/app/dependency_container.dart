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
  });

  final ObjectController objectController;
  final FindMatches findMatches;

  static DependencyContainer create() {
    final dataSource = ObjectMockDataSource();
    final repository = ObjectRepositoryImpl(dataSource);

    return DependencyContainer(
      objectController: ObjectController(
        getObjects: GetObjects(repository),
        registerObject: RegisterObject(repository),
      ),
      findMatches: const FindMatches(),
    );
  }
}
