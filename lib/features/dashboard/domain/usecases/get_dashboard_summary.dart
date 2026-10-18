import '../entities/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardSummary {
  const GetDashboardSummary(this.repository);
  final DashboardRepository repository;
  Future<DashboardSummary> call() => repository.getSummary();
}
