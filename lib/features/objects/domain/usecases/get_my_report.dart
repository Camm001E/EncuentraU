import '../entities/object_report.dart';
import '../repositories/object_repository.dart';

class GetMyReport {
  const GetMyReport(this._repository);
  final ObjectRepository _repository;
  Future<ObjectReport> call(String id) => _repository.getMyReport(id);
}
