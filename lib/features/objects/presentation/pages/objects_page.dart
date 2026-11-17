import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/object_report.dart';
import '../constants/report_labels.dart';
import '../controllers/object_controller.dart';
import '../widgets/report_list.dart';
import '../../../../core/presentation/widgets/design_system.dart';

class ObjectsPage extends StatefulWidget {
  const ObjectsPage({required this.controller, super.key});
  final ObjectController controller;
  @override
  State<ObjectsPage> createState() => _ObjectsPageState();
}

class _ObjectsPageState extends State<ObjectsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text(AppStrings.myReports)),
      body: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) => ContentWidth(
              child: RefreshIndicator(
                  onRefresh: widget.controller.refresh,
                  child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSizes.spacingLarge),
                      children: [
                        const SectionHeading(
                            title: AppStrings.reportCollectionHeadline,
                            subtitle: AppStrings.reportCollectionSubtitle),
                        const Text(AppStrings.filterType),
                        const SizedBox(height: AppSizes.spacingSmall),
                        Wrap(
                            spacing: AppSizes.spacingSmall,
                            runSpacing: AppSizes.spacingSmall,
                            children: [
                              ChoiceChip(
                                  label: const Text(AppStrings.all),
                                  selected:
                                      widget.controller.reportTypeFilter ==
                                          null,
                                  onSelected: (_) => widget.controller
                                      .setFilters(
                                          status:
                                              widget.controller.statusFilter)),
                              for (final type in ReportType.values)
                                ChoiceChip(
                                    label: Text(type.label),
                                    selected: widget
                                            .controller.reportTypeFilter ==
                                        type,
                                    onSelected: (_) => widget.controller
                                        .setFilters(
                                            reportType: type,
                                            status: widget
                                                .controller.statusFilter)),
                            ]),
                        const SizedBox(height: AppSizes.spacingMedium),
                        const Text(AppStrings.filterStatus),
                        const SizedBox(height: AppSizes.spacingSmall),
                        Wrap(
                            spacing: AppSizes.spacingSmall,
                            runSpacing: AppSizes.spacingSmall,
                            children: [
                              FilterChip(
                                  label: const Text(AppStrings.all),
                                  selected:
                                      widget.controller.statusFilter == null,
                                  onSelected: (_) => widget.controller
                                      .setFilters(
                                          reportType: widget
                                              .controller.reportTypeFilter)),
                              for (final status in ReportStatus.values)
                                FilterChip(
                                    label: Text(status.label),
                                    selected: widget.controller.statusFilter ==
                                        status,
                                    onSelected: (selected) => widget.controller
                                        .setFilters(
                                            reportType: widget
                                                .controller.reportTypeFilter,
                                            status: selected ? status : null)),
                            ]),
                        const SizedBox(height: AppSizes.spacingLarge),
                        Text(AppStrings.resultCount(widget.controller.total),
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: AppSizes.spacingMedium),
                        ReportList(controller: widget.controller),
                      ])))));
}
