import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/design_system.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../objects/presentation/widgets/report_photo.dart';
import '../../domain/entities/delivery.dart';
import '../controllers/delivery_controller.dart';
import '../widgets/delivery_widgets.dart';

class DeliveriesPage extends StatefulWidget {
  const DeliveriesPage({required this.controller, super.key});
  final DeliveryController controller;
  @override
  State<DeliveriesPage> createState() => _DeliveriesPageState();
}

class _DeliveriesPageState extends State<DeliveriesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.refresh();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(widget.controller.admin
              ? AppStrings.deliveries
              : AppStrings.myDeliveries)),
      body: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            return ContentWidth(
                child: RefreshIndicator(
                    onRefresh: c.refresh,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSizes.spacingLarge),
                        children: [
                          DropdownButtonFormField<DeliveryStatus>(
                              key: ValueKey(c.statusFilter),
                              initialValue: c.statusFilter,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  labelText: AppStrings.deliveryProcess),
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text(AppStrings.all)),
                                for (final s in DeliveryStatus.values)
                                  DropdownMenuItem(
                                      value: s, child: Text(s.label)),
                              ],
                              onChanged: c.setStatus),
                          const SizedBox(height: AppSizes.spacingLarge),
                          if (c.status == LoadStatus.initial ||
                              c.status == LoadStatus.loading)
                            const LoadingSkeleton(),
                          if (c.status == LoadStatus.error)
                            LoadFeedback(
                                message:
                                    c.message ?? AppStrings.unexpectedError,
                                onRetry: c.refresh),
                          if (c.status == LoadStatus.empty)
                            const InformationPanel(
                                icon: Icons.handshake_outlined,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(AppStrings.noDeliveries),
                                      Text(AppStrings.noDeliveriesHelp)
                                    ])),
                          for (final d in c.items)
                            Card(
                                key: ValueKey('delivery-${d.id}'),
                                child: InkWell(
                                    onTap: () => Navigator.pushNamed(
                                                context,
                                                c.admin
                                                    ? AppRoutes
                                                        .adminDeliveryDetail
                                                    : AppRoutes.deliveryDetail,
                                                arguments: c.admin
                                                    ? d.id
                                                    : d.conversationId)
                                            .then((_) {
                                          if (mounted) c.refresh();
                                        }),
                                    child: Padding(
                                        padding: const EdgeInsets.all(
                                            AppSizes.spacingMedium),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              ReportPhoto(
                                                  image: d.lostReport.image,
                                                  height: AppSizes
                                                      .matchPhotoHeight),
                                              const SizedBox(
                                                  height:
                                                      AppSizes.spacingMedium),
                                              Text(d.lostReport.objectType,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium),
                                              Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: DeliveryStatusPill(
                                                      d.status)),
                                              Text(AppStrings.confirmationCount(
                                                  (d.claimantConfirmedAt == null
                                                          ? 0
                                                          : 1) +
                                                      (d.custodianConfirmedAt ==
                                                              null
                                                          ? 0
                                                          : 1))),
                                              Text(formatDate(
                                                  d.updatedAt.toLocal())),
                                            ])))),
                          if (c.hasMore)
                            SecondaryAction(
                                label: AppStrings.loadMore,
                                onPressed: c.isLoadingMore ? null : c.loadMore),
                        ])));
          }));
}
