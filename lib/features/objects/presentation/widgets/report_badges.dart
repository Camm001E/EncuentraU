import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../domain/entities/object_report.dart';
import '../constants/report_labels.dart';

class ReportTypeBadge extends StatelessWidget {
  const ReportTypeBadge(this.type, {super.key});
  final ReportType type;
  @override
  Widget build(BuildContext context) => StatusPill(
      label: type.label,
      icon: type == ReportType.lost
          ? Icons.search_rounded
          : Icons.volunteer_activism_outlined,
      tone: type == ReportType.lost
          ? AppSemanticColors.of(context).lost
          : AppSemanticColors.of(context).found);
}

class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge(this.status, {super.key});
  final ReportStatus status;
  @override
  Widget build(BuildContext context) => StatusPill(
      label: status.label,
      icon: switch (status) {
        ReportStatus.active => Icons.radio_button_checked,
        ReportStatus.resolved => Icons.check_circle_outline,
        ReportStatus.cancelled => Icons.block_outlined
      },
      tone: status == ReportStatus.active
          ? AppSemanticColors.of(context).success
          : AppSemanticColors.of(context).low);
}
