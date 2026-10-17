import '../entities/object_report.dart';
import '../entities/report_page.dart';

abstract interface class ObjectRepository {
  Future<ObjectReport> createReport(ObjectReportDraft draft);
  Future<ReportPage> getMyReports(
      {required int limit,
      required int offset,
      ReportType? reportType,
      ReportStatus? status});
  Future<ObjectReport> getMyReport(String id);
  Future<ObjectReport> updateReport(String id, ObjectReportUpdate update);
  Future<void> cancelReport(String id);
}
