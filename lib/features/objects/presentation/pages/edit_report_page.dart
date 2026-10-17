import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/widgets/load_feedback.dart';
import '../../domain/entities/object_report.dart';
import '../constants/report_labels.dart';
import '../controllers/object_controller.dart';
import '../widgets/report_form_fields.dart';

class EditReportPage extends StatefulWidget {
  const EditReportPage(
      {required this.reportId, required this.controller, super.key});
  final String reportId;
  final ObjectController controller;
  @override
  State<EditReportPage> createState() => _EditReportPageState();
}

class _EditReportPageState extends State<EditReportPage> {
  final _form = GlobalKey<FormState>();
  ReportFormData? _data;
  ReportStatus _status = ReportStatus.active;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.loadDetail(widget.reportId);
    });
  }

  @override
  void dispose() {
    _data?.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (widget.controller.isUpdating ||
        !(_form.currentState?.validate() ?? false)) return;
    final success = await widget.controller
        .update(widget.reportId, _data!.update(status: _status));
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.reportUpdated)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text(AppStrings.editReport)),
      body: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;
            if (controller.detailStatus == LoadStatus.loading ||
                controller.detailStatus == LoadStatus.initial)
              return const Center(child: CircularProgressIndicator());
            if (controller.detailStatus == LoadStatus.error)
              return LoadFeedback(
                  message:
                      controller.detailMessage ?? AppStrings.unexpectedError,
                  onRetry: () => controller.loadDetail(widget.reportId));
            final report = controller.detail;
            if (report == null || report.id != widget.reportId)
              return const LoadFeedback(message: AppStrings.apiNotFound);
            if (_data == null) {
              _data = ReportFormData(report: report);
              _status = report.status;
            }
            final enabled =
                report.status == ReportStatus.active && !controller.isUpdating;
            return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.spacingMLarge),
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxWidth: AppSizes.objectFormMaxWidth),
                        child: Form(
                            key: _form,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (report.status != ReportStatus.active)
                                    const Text(AppStrings.reportReadOnly),
                                  ReportFormFields(
                                      data: _data!, enabled: enabled),
                                  DropdownButtonFormField<ReportStatus>(
                                      initialValue: _status,
                                      decoration: const InputDecoration(
                                          labelText: AppStrings.statusLabel),
                                      items: ReportStatus.values
                                          .map((value) => DropdownMenuItem(
                                              value: value,
                                              child: Text(value.label)))
                                          .toList(),
                                      onChanged: enabled
                                          ? (value) =>
                                              setState(() => _status = value!)
                                          : null),
                                  if (controller.actionMessage != null)
                                    Text(controller.actionMessage!),
                                  const SizedBox(
                                      height: AppSizes.spacingMedium),
                                  FilledButton(
                                      onPressed: enabled ? save : null,
                                      child: Text(controller.isUpdating
                                          ? AppStrings.savingReport
                                          : AppStrings.saveChanges)),
                                ])))));
          }));
}
