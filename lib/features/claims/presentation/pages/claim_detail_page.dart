import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../../matching/presentation/widgets/match_detail_content.dart';
import '../../domain/entities/ownership_claim.dart';
import '../controllers/claims_controller.dart';
import '../widgets/claim_widgets.dart';

class ClaimDetailPage extends StatefulWidget {
  const ClaimDetailPage(
      {required this.claimId, required this.controller, super.key});
  final String claimId;
  final ClaimsController controller;
  @override
  State<ClaimDetailPage> createState() => _ClaimDetailPageState();
}

class _ClaimDetailPageState extends State<ClaimDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.loadDetail(widget.claimId);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text(AppStrings.claimDetailTitle)),
      body: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final c = widget.controller, claim = c.detail;
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
                    onRefresh: () => c.loadDetail(widget.claimId),
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSizes.spacingLarge),
                        children: [
                          ClaimStatePanel(claim: claim, showLink: false),
                          const SizedBox(height: AppSizes.spacingLarge),
                          if (claim.relationship ==
                                  ClaimRelationship.claimant &&
                              claim.ownershipEvidence != null)
                            InformationPanel(
                                icon: Icons.lock_outline,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(AppStrings.yourOwnershipEvidence,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(
                                          height: AppSizes.spacingSmall),
                                      Text(claim.ownershipEvidence!)
                                    ]))
                          else
                            const InformationPanel(
                                icon: Icons.shield_outlined,
                                child: Text(AppStrings.custodianPrivacy)),
                          const SizedBox(height: AppSizes.spacingLarge),
                          MatchDetailContent(
                              key: ValueKey(claim.match.id),
                              match: claim.match),
                        ])));
          }));
}
