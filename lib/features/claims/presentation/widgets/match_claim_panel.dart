import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../../matching/domain/entities/object_match.dart';
import '../../../objects/domain/entities/object_report.dart';
import '../controllers/claims_controller.dart';
import 'claim_widgets.dart';

class MatchClaimPanel extends StatefulWidget {
  const MatchClaimPanel(
      {required this.match, required this.controller, super.key});
  final ObjectMatch match;
  final ClaimsController controller;
  @override
  State<MatchClaimPanel> createState() => _MatchClaimPanelState();
}

class _MatchClaimPanelState extends State<MatchClaimPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.loadForMatch(widget.match.id);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller,
            state = controller.stateFor(widget.match.id);
        if (state == LoadStatus.loading || state == LoadStatus.initial)
          return const LoadingSkeleton(count: 1);
        if (state == LoadStatus.error)
          return LoadFeedback(
              message: controller.errorFor(widget.match.id) ??
                  AppStrings.unexpectedError,
              onRetry: () => controller.loadForMatch(widget.match.id));
        final claim = controller.claimFor(widget.match.id);
        if (claim != null)
          return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spacingLarge),
              child: ClaimStatePanel(claim: claim));
        final match = widget.match;
        if (match.status != MatchStatus.pending ||
            match.myReport.reportType != ReportType.lost ||
            match.myReport.status != ReportStatus.active ||
            match.candidateReport.status != ReportStatus.active)
          return const SizedBox.shrink();
        return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spacingLarge),
            child: PrimaryAction(
                label: AppStrings.claimThisObject,
                icon: Icons.fact_check_outlined,
                onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.submitClaim,
                            arguments: match.id)
                        .then((_) {
                      if (mounted) controller.loadForMatch(match.id);
                    })));
      });
}
