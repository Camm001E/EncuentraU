import '../../../matching/domain/repositories/match_repository.dart';
import '../../../objects/domain/entities/object_report.dart';
import '../../../objects/domain/repositories/object_repository.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../../core/constants/api_constants.dart';

/// Counts come from pagination totals, never from a partially loaded page.
class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this.reports, this.matches);
  final ObjectRepository reports;
  final MatchRepository matches;
  @override
  Future<DashboardSummary> getSummary() async {
    final totals = await Future.wait([
      reports
          .getMyReports(
              limit: ApiConstants.countPageSize,
              offset: 0,
              status: ReportStatus.active)
          .then((p) => p.total),
      reports
          .getMyReports(
              limit: ApiConstants.countPageSize,
              offset: 0,
              reportType: ReportType.lost)
          .then((p) => p.total),
      reports
          .getMyReports(
              limit: ApiConstants.countPageSize,
              offset: 0,
              reportType: ReportType.found)
          .then((p) => p.total),
      matches
          .getMyMatches(limit: ApiConstants.countPageSize, offset: 0)
          .then((p) => p.total),
    ]);
    return DashboardSummary(
        activeReports: totals[0],
        lostReports: totals[1],
        foundReports: totals[2],
        matches: totals[3]);
  }
}
