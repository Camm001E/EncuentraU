import '../entities/object_report.dart';
import '../repositories/object_repository.dart';

class RegisterObject {
  const RegisterObject(this.repository);

  final ObjectRepository repository;

  Future<void> call(ObjectReport report) => repository.registerObject(report);
}
