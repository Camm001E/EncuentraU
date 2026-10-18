import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/api_message.dart';
import '../../domain/entities/report_image.dart';
import 'report_image_scope.dart';
import 'report_photo.dart';
import 'report_photo_picker.dart';

class ReportPhotoEditor extends StatefulWidget {
  const ReportPhotoEditor(
      {required this.reportId,
      required this.image,
      required this.enabled,
      required this.onChanged,
      this.pickImage = pickReportPhoto,
      super.key});
  final String reportId;
  final ReportImageReference? image;
  final bool enabled;
  final Future<void> Function() onChanged;
  final Future<ReportImageUpload?> Function() pickImage;
  @override
  State<ReportPhotoEditor> createState() => _ReportPhotoEditorState();
}

class _ReportPhotoEditorState extends State<ReportPhotoEditor> {
  ReportImageUpload? _pending;
  bool _picking = false;
  String? _error;
  Future<void> choose() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final image = await widget.pickImage();
      if (!mounted || image == null) return;
      setState(() => _pending = image);
      await upload();
    } catch (error) {
      if (mounted) setState(() => _error = apiMessage(error));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> upload() async {
    final controller = ReportImageScope.maybeOf(context);
    if (controller == null || _pending == null) return;
    final result = await controller.upload(widget.reportId, _pending!);
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _pending = null;
        _error = null;
      });
      await widget.onChanged();
    }
  }

  Future<void> delete() async {
    final controller = ReportImageScope.maybeOf(context);
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: const Text(AppStrings.deleteReportPhoto),
                content: const Text(AppStrings.deletePhotoConfirmation),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text(AppStrings.dismiss)),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text(AppStrings.confirm))
                ]));
    if (!mounted || confirmed != true || controller == null) return;
    if (await controller.delete(widget.reportId) && mounted)
      await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ReportImageScope.maybeOf(context);
    if (controller == null) return ReportPhoto(image: widget.image);
    return AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final busy = _picking || controller.isBusy(widget.reportId);
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReportPhoto(image: widget.image),
                const SizedBox(height: AppSizes.spacingSmall),
                OutlinedButton.icon(
                    onPressed: widget.enabled && !busy ? choose : null,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(busy
                        ? AppStrings.uploadingPhoto
                        : AppStrings.replaceReportPhoto)),
                if (_pending != null && !busy)
                  FilledButton.tonal(
                      onPressed: upload,
                      child: const Text(AppStrings.retryPhotoUpload)),
                if (widget.image != null)
                  TextButton(
                      onPressed: widget.enabled && !busy ? delete : null,
                      child: const Text(AppStrings.deleteReportPhoto)),
                if (_error ?? controller.message(widget.reportId)
                    case final String error)
                  Text(error),
              ]);
        });
  }
}
