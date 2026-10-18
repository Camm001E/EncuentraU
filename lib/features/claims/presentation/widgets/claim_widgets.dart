import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../objects/presentation/widgets/report_photo.dart';
import '../../domain/entities/ownership_claim.dart';

extension ClaimStatusLabel on ClaimStatus {
  String get label => switch (this) {
        ClaimStatus.pending => AppStrings.claimPending,
        ClaimStatus.approved => AppStrings.claimApproved,
        ClaimStatus.rejected => AppStrings.claimRejected
      };
}

SemanticTone claimTone(BuildContext context, ClaimStatus status) =>
    switch (status) {
      ClaimStatus.pending => AppSemanticColors.of(context).information,
      ClaimStatus.approved => AppSemanticColors.of(context).success,
      ClaimStatus.rejected => AppSemanticColors.of(context).warning
    };
IconData claimIcon(ClaimStatus status) => switch (status) {
      ClaimStatus.pending => Icons.schedule_rounded,
      ClaimStatus.approved => Icons.verified_outlined,
      ClaimStatus.rejected => Icons.info_outline_rounded
    };

class ClaimStatusPill extends StatelessWidget {
  const ClaimStatusPill(this.status, {super.key});
  final ClaimStatus status;
  @override
  Widget build(BuildContext context) => StatusPill(
      label: status.label,
      icon: claimIcon(status),
      tone: claimTone(context, status));
}

class ClaimCard extends StatelessWidget {
  const ClaimCard({required this.claim, this.admin = false, super.key});
  final ClaimSummary claim;
  final bool admin;
  @override
  Widget build(BuildContext context) {
    final report = claim.match.myReport;
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(report.objectType, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSizes.spacingSmall),
      ClaimStatusPill(claim.status),
      const SizedBox(height: AppSizes.spacingRegular),
      Text(
          '${AppStrings.estimatedCompatibility}: ${AppStrings.percentage(claim.match.percentage)}'),
      Text(AppStrings.claimDate(formatDate(claim.createdAt.toLocal()))),
    ]);
    return Card(
        child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            onTap: () => Navigator.pushNamed(context,
                admin ? AppRoutes.adminClaimDetail : AppRoutes.claimDetail,
                arguments: claim.id),
            child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacingMedium),
                child: MediaQuery.textScalerOf(context).scale(1) >
                        AppSizes.textScaleNavigationCutoff
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            ReportPhoto(
                                image: report.image,
                                height: AppSizes.matchPhotoHeight),
                            const SizedBox(height: AppSizes.spacingMedium),
                            content
                          ])
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            SizedBox(
                                width: AppSizes.reportCardPhoto,
                                child: ReportPhoto(
                                    image: report.image,
                                    height: AppSizes.reportCardPhoto)),
                            const SizedBox(width: AppSizes.spacingMedium),
                            Expanded(child: content),
                            const Icon(Icons.chevron_right_rounded),
                          ]))));
  }
}

class ClaimStatePanel extends StatelessWidget {
  const ClaimStatePanel({required this.claim, this.showLink = true, super.key});
  final OwnershipClaim claim;
  final bool showLink;
  @override
  Widget build(BuildContext context) => InformationPanel(
      tone: claimTone(context, claim.status),
      icon: claimIcon(claim.status),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(claim.status.label,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSizes.spacingSmall),
        if (claim.status == ClaimStatus.pending)
          Text(claim.relationship == ClaimRelationship.custodian
              ? AppStrings.custodianPending
              : AppStrings.pendingClaimHelp),
        if (claim.status == ClaimStatus.approved)
          const Text(AppStrings.chatEnabledHelp),
        if (claim.status == ClaimStatus.rejected) ...[
          const Text(AppStrings.chatRejectedHelp),
          if (claim.rejectionReason != null)
            Text(
                '${AppStrings.rejectionReasonLabel}: ${claim.rejectionReason}'),
        ],
        if (showLink) ...[
          const SizedBox(height: AppSizes.spacingMedium),
          SecondaryAction(
              label: AppStrings.openClaim,
              onPressed: () => Navigator.pushNamed(
                  context, AppRoutes.claimDetail,
                  arguments: claim.id)),
        ],
        if (claim.status == ClaimStatus.approved &&
            claim.conversationId != null) ...[
          const SizedBox(height: AppSizes.spacingMedium),
          PrimaryAction(
              label: AppStrings.openChat,
              icon: Icons.forum_outlined,
              onPressed: () => Navigator.pushNamed(
                  context, AppRoutes.conversation,
                  arguments: claim.conversationId)),
        ],
      ]));
}

class ClaimStatusFilter extends StatelessWidget {
  const ClaimStatusFilter(
      {required this.value, required this.onChanged, super.key});
  final ClaimStatus? value;
  final ValueChanged<ClaimStatus?> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<ClaimStatus>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration:
          const InputDecoration(labelText: AppStrings.claimStatusFilter),
      items: [
        const DropdownMenuItem(value: null, child: Text(AppStrings.all)),
        for (final status in ClaimStatus.values)
          DropdownMenuItem(value: status, child: Text(status.label))
      ],
      onChanged: onChanged);
}
