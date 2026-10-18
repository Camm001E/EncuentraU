class DashboardSummary {
  const DashboardSummary(
      {required this.activeReports,
      required this.lostReports,
      required this.foundReports,
      required this.matches});
  final int activeReports, lostReports, foundReports, matches;
}
