import '../../../../core/domain/page.dart';
import 'object_report.dart';

class ReportPage extends Page<ObjectReport> {
  const ReportPage(
      {required super.items,
      required super.total,
      required super.limit,
      required super.offset});
}
