import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/object_report.dart';
import '../../domain/entities/report_page.dart';
import '../models/object_report_model.dart';

class ObjectReportRemoteDataSource {
  const ObjectReportRemoteDataSource(this._api);
  final AuthenticatedApiClient _api;
  Future<ObjectReport> create(ObjectReportDraft draft) async =>
      ObjectReportModel.fromJson((await _api.request(
          'POST', ApiConstants.reportsPath,
          body: ReportCreateModel.toJson(draft),
          expectedStatus: ApiConstants.created))!);
  Future<ReportPage> list(
          {required int limit,
          required int offset,
          ReportType? reportType,
          ReportStatus? status}) async =>
      ObjectReportModel.page(
          (await _api.request('GET', ApiConstants.myReportsPath, query: {
        ApiConstants.limitParameter: '$limit',
        ApiConstants.offsetParameter: '$offset',
        if (reportType != null)
          ApiConstants.reportTypeParameter: reportType.name,
        if (status != null) ApiConstants.statusParameter: status.name,
      }))!);
  Future<ObjectReport> get(String id) async => ObjectReportModel.fromJson(
      (await _api.request('GET', ApiConstants.reportPath(id)))!);
  Future<ObjectReport> update(String id, ObjectReportUpdate update) async =>
      ObjectReportModel.fromJson((await _api.request(
          'PATCH', ApiConstants.reportPath(id),
          body: ReportUpdateModel.toJson(update)))!);
  Future<void> cancel(String id) async {
    await _api.request('DELETE', ApiConstants.reportPath(id),
        expectedStatus: ApiConstants.noContent);
  }
}
