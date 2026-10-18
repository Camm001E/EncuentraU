import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../../matching/presentation/widgets/match_detail_content.dart';
import '../../domain/entities/delivery.dart';
import '../controllers/delivery_controller.dart';
import '../widgets/delivery_widgets.dart';

class DeliveryDetailPage extends StatefulWidget {
  const DeliveryDetailPage(
      {required this.id, required this.controller, super.key});
  final String id;
  final DeliveryController controller;
  @override
  State<DeliveryDetailPage> createState() => _DeliveryDetailPageState();
}

class _DeliveryDetailPageState extends State<DeliveryDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.loadDetail(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text(AppStrings.deliveryProcess)),
      body: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final c = widget.controller, d = c.detail;
            if (c.detailStatus == LoadStatus.initial ||
                c.detailStatus == LoadStatus.loading)
              return const Padding(
                  padding: EdgeInsets.all(AppSizes.spacingLarge),
                  child: LoadingSkeleton());
            if (d == null || (c.admin ? d.id : d.conversationId) != widget.id)
              return LoadFeedback(
                  message: c.detailMessage ?? AppStrings.unexpectedError,
                  onRetry: () => c.loadDetail(widget.id));
            return ContentWidth(
                child: RefreshIndicator(
                    onRefresh: () => c.loadDetail(widget.id),
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSizes.spacingLarge),
                        children: [
                          Text(d.lostReport.objectType,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: AppSizes.spacingLarge),
                          DeliveryContent(delivery: d, controller: c),
                          if (d is AdminDelivery && d.claim != null) ...[
                            const SizedBox(height: AppSizes.spacingLarge),
                            MatchDetailContent(match: d.claim!.match),
                            const SizedBox(height: AppSizes.spacingLarge),
                            for (final item in [
                              (
                                AppStrings.claimantAnswer,
                                d.claim!.ownershipEvidence
                              ),
                              (
                                AppStrings.lostPrivateFeature,
                                d.claim!.lostPrivateFeature
                              ),
                              (
                                AppStrings.foundPrivateFeature,
                                d.claim!.foundPrivateFeature
                              )
                            ])
                              Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSizes.spacingMedium),
                                  child: InformationPanel(
                                      icon: Icons.lock_outline,
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item.$1,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall),
                                            Text(item.$2 ??
                                                AppStrings.notAvailable)
                                          ]))),
                          ],
                        ])));
          }));
}
