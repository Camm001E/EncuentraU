import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/object_report.dart';
import '../../domain/entities/report_page.dart';
import '../../domain/repositories/object_repository.dart';
import '../datasources/object_report_remote_data_source.dart';

class ObjectRepositoryImpl implements ObjectRepository {
  const ObjectRepositoryImpl(this._remote);
  final ObjectReportRemoteDataSource _remote;
  Future<T> _parse<T>(Future<T> Function() work) async {
    try {
      return await work();
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  @override
  Future<ObjectReport> createReport(ObjectReportDraft draft) =>
      _parse(() => _remote.create(draft));
  @override
  Future<ReportPage> getMyReports(
          {required int limit,
          required int offset,
          ReportType? reportType,
          ReportStatus? status}) =>
      _parse(() => _remote.list(
          limit: limit,
          offset: offset,
          reportType: reportType,
          status: status));
  @override
  Future<ObjectReport> getMyReport(String id) => _parse(() => _remote.get(id));
  @override
  Future<ObjectReport> updateReport(String id, ObjectReportUpdate update) =>
      _parse(() => _remote.update(id, update));
  @override
  Future<void> cancelReport(String id) => _remote.cancel(id);
}
