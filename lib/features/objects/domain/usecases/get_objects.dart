import '../entities/object_report.dart';
import '../repositories/object_repository.dart';

class GetObjects {
  const GetObjects(this.repository);

  final ObjectRepository repository;

  Future<List<ObjectReport>> call() => repository.getObjects();
}
