import '../entities/object_report.dart';
import '../repositories/object_repository.dart';

class RegisterObject {
  const RegisterObject(this._repository);
  final ObjectRepository _repository;
  Future<ObjectReport> call(ObjectReportDraft draft) =>
      _repository.createReport(draft);
}
