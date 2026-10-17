import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/object_report.dart';
import '../constants/report_labels.dart';
import '../controllers/object_controller.dart';
import '../widgets/report_list.dart';

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
          builder: (context, _) => RefreshIndicator(
              onRefresh: widget.controller.refresh,
              child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSizes.spacingMLarge),
                  children: [
                    Wrap(
                        spacing: AppSizes.spacingMedium,
                        runSpacing: AppSizes.spacingSmall,
                        children: [
                          DropdownButton<ReportType?>(
                              value: widget.controller.reportTypeFilter,
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text(AppStrings.all)),
                                ...ReportType.values.map((type) =>
                                    DropdownMenuItem(
                                        value: type, child: Text(type.label))),
                              ],
                              onChanged: (type) => widget.controller.setFilters(
                                  reportType: type,
                                  status: widget.controller.statusFilter)),
                          DropdownButton<ReportStatus?>(
                              value: widget.controller.statusFilter,
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text(AppStrings.all)),
                                ...ReportStatus.values.map((status) =>
                                    DropdownMenuItem(
                                        value: status,
                                        child: Text(status.label))),
                              ],
                              onChanged: (status) => widget.controller
                                  .setFilters(
                                      reportType:
                                          widget.controller.reportTypeFilter,
                                      status: status)),
                        ]),
                    Text(AppStrings.resultCount(widget.controller.total)),
                    ReportList(controller: widget.controller),
                  ]))));
}
