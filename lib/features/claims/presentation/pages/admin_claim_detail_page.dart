import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../matching/presentation/widgets/match_detail_content.dart';
import '../../domain/entities/ownership_claim.dart';
import '../controllers/admin_claims_controller.dart';
import '../widgets/claim_widgets.dart';
import '../widgets/review_decision_dialog.dart';

class AdminClaimDetailPage extends StatefulWidget {
  const AdminClaimDetailPage(
      {required this.claimId, required this.controller, super.key});
  final String claimId;
  final AdminClaimsController controller;
  @override
  State<AdminClaimDetailPage> createState() => _AdminClaimDetailPageState();
}

class _AdminClaimDetailPageState extends State<AdminClaimDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.loadDetail(widget.claimId);
    });
  }

  Future<void> decide(bool approve) async {
    if (widget.controller.isReviewing) return;
    final draft = await showDialog<ReviewDecision>(
        context: context,
        builder: (_) => ReviewDecisionDialog(approve: approve));
    if (!mounted || draft == null) return;
    final success = approve
        ? await widget.controller.approve(widget.claimId, note: draft.note)
        : await widget.controller
            .reject(widget.claimId, reason: draft.reason!, note: draft.note);
    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approve
            ? AppStrings.approvalCompleted
            : AppStrings.rejectionCompleted)));
  }

  Widget evidence(String label, String? value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingMedium),
      child: Semantics(
          label: AppStrings.privateEvidenceSemantics(
              label, value ?? AppStrings.noPrivateFeature),
          child: ExcludeSemantics(
              child: InformationPanel(
                  icon: Icons.lock_outline,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(label,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppSizes.spacingSmall),
                        SelectableText(value ?? AppStrings.noPrivateFeature)
                      ])))));
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final c = widget.controller, claim = c.detail;
        return PopScope(
            canPop: !c.isReviewing,
            child: Scaffold(
                appBar: AppBar(title: const Text(AppStrings.adminClaimDetail)),
                body: Builder(builder: (context) {
                  if (c.detailStatus == LoadStatus.initial ||
                      c.detailStatus == LoadStatus.loading)
                    return const Padding(
                        padding: EdgeInsets.all(AppSizes.spacingLarge),
                        child: LoadingSkeleton());
                  if (c.detailStatus == LoadStatus.error)
                    return LoadFeedback(
                        message: c.detailMessage ?? AppStrings.unexpectedError,
                        onRetry: () => c.loadDetail(widget.claimId));
                  if (claim == null || claim.id != widget.claimId)
                    return const LoadFeedback(message: AppStrings.apiNotFound);
                  return ContentWidth(
                      child: RefreshIndicator(
                          onRefresh: () async {
                            if (!c.isReviewing)
                              await c.loadDetail(widget.claimId);
                          },
                          child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.all(AppSizes.spacingLarge),
                              children: [
                                Wrap(children: [ClaimStatusPill(claim.status)]),
                                const SizedBox(height: AppSizes.spacingLarge),
                                const SectionHeading(
                                    title: AppStrings.adminPrivateEvidence),
                                evidence(AppStrings.claimantAnswer,
                                    claim.ownershipEvidence),
                                evidence(AppStrings.lostPrivateFeature,
                                    claim.lostPrivateFeature),
                                evidence(AppStrings.foundPrivateFeature,
                                    claim.foundPrivateFeature),
                                if (claim.status == ClaimStatus.pending) ...[
                                  const SizedBox(height: AppSizes.spacingSmall),
                                  PrimaryAction(
                                      label: AppStrings.approveClaim,
                                      icon: Icons.verified_outlined,
                                      busy: c.isReviewing,
                                      onPressed: () => decide(true)),
                                  const SizedBox(
                                      height: AppSizes.spacingMedium),
                                  SecondaryAction(
                                      label: AppStrings.rejectClaim,
                                      icon: Icons.rule_outlined,
                                      onPressed: c.isReviewing
                                          ? null
                                          : () => decide(false)),
                                ] else ...[
                                  InformationPanel(
                                      tone: AppSemanticColors.of(context)
                                          .information,
                                      icon: Icons.shield_outlined,
                                      child: const Text(
                                          AppStrings.adminChatPrivacy)),
                                  if (claim.adminNote != null) ...[
                                    const SizedBox(
                                        height: AppSizes.spacingMedium),
                                    evidence(
                                        AppStrings.adminNote, claim.adminNote)
                                  ],
                                  if (claim.rejectionReason != null)
                                    evidence(AppStrings.rejectionReasonLabel,
                                        claim.rejectionReason),
                                ],
                                if (c.actionMessage != null) ...[
                                  const SizedBox(
                                      height: AppSizes.spacingMedium),
                                  InformationPanel(
                                      icon: Icons.info_outline,
                                      child: Text(c.actionMessage!))
                                ],
                                const SizedBox(height: AppSizes.spacingXLarge),
                                MatchDetailContent(
                                    key: ValueKey(claim.match.id),
                                    match: claim.match),
                              ])));
                })));
      });
}
