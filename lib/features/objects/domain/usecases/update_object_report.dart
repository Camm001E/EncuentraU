import '../entities/object_report.dart';
import '../repositories/object_repository.dart';

class UpdateObjectReport {
  const UpdateObjectReport(this._repository);
  final ObjectRepository _repository;
  Future<ObjectReport> call(String id, ObjectReportUpdate update) =>
      _repository.updateReport(id, update);
}
