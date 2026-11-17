import 'package:encuentra_u/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:encuentra_u/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Isolates the dashboard in tests for existing auth/report/image contracts.
class TestDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary() async => const DashboardSummary(
      activeReports: 0, lostReports: 0, foundReports: 0, matches: 0);
}
