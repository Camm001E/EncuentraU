import '../../domain/entities/object_report.dart';
import '../../domain/repositories/object_repository.dart';
import '../datasources/object_mock_datasource.dart';
import '../models/object_report_model.dart';

class ObjectRepositoryImpl implements ObjectRepository {
  const ObjectRepositoryImpl(this.dataSource);

  final ObjectMockDataSource dataSource;

  @override
  Future<List<ObjectReport>> getObjects() => dataSource.getObjects();

  @override
  Future<void> registerObject(ObjectReport report) {
    return dataSource.registerObject(ObjectReportModel.fromEntity(report));
  }
}
