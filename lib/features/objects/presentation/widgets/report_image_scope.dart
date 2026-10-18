import 'package:flutter/widgets.dart';
import '../controllers/report_image_controller.dart';

class ReportImageScope extends InheritedWidget {
  const ReportImageScope(
      {required this.controller, required super.child, super.key});
  final ReportImageController controller;
  static ReportImageController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ReportImageScope>()
      ?.controller;
  @override
  bool updateShouldNotify(ReportImageScope oldWidget) =>
      controller != oldWidget.controller;
}
