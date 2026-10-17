import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/object_report.dart';

extension ReportTypeLabel on ReportType {
  String get label =>
      this == ReportType.lost ? AppStrings.lost : AppStrings.found;
}

extension ReportStatusLabel on ReportStatus {
  String get label => switch (this) {
        ReportStatus.active => AppStrings.active,
        ReportStatus.resolved => AppStrings.resolved,
        ReportStatus.cancelled => AppStrings.cancelled,
      };
}
