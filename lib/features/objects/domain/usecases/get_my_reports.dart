import '../entities/object_report.dart';
import '../entities/report_page.dart';
import '../repositories/object_repository.dart';

class GetMyReports {
  const GetMyReports(this._repository);
  final ObjectRepository _repository;
  Future<ReportPage> call(
          {required int limit,
          required int offset,
          ReportType? reportType,
          ReportStatus? status}) =>
      _repository.getMyReports(
          limit: limit, offset: offset, reportType: reportType, status: status);
}
