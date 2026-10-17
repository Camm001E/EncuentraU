import '../repositories/object_repository.dart';

class CancelObjectReport {
  const CancelObjectReport(this._repository);
  final ObjectRepository _repository;
  Future<void> call(String id) => _repository.cancelReport(id);
}
