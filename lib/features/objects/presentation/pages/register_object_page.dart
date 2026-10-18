import 'dart:async';
import '../../domain/entities/report_image.dart';
import '../widgets/report_image_scope.dart';
import '../widgets/report_photo_picker.dart';
import '../../../../core/presentation/api_message.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../matching/presentation/controllers/match_controller.dart';
import '../../domain/entities/object_image_input.dart';
import '../../domain/entities/object_report.dart';
import '../controllers/object_analysis_controller.dart';
import '../controllers/object_controller.dart';
import '../widgets/report_form_fields.dart';

class RegisterObjectPage extends StatefulWidget {
  const RegisterObjectPage(
      {required this.type,
      required this.controller,
      required this.analysisController,
      required this.matchController,
      this.pickImage = pickReportPhoto,
      super.key});
  final ReportType type;
  final ObjectController controller;
  final ObjectAnalysisController analysisController;
  final MatchController matchController;
  final Future<ReportImageUpload?> Function() pickImage;
  @override
  State<RegisterObjectPage> createState() => _RegisterObjectPageState();
}

class _RegisterObjectPageState extends State<RegisterObjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _data = ReportFormData();
  ReportImageUpload? _image;
  bool _photoUploaded = false;
  bool _photoFailure = false;
  Uint8List? _preview;
  ObjectReport? _savedReport;
  bool _submitting = false;
  late Listenable _changes;
  @override
  void initState() {
    super.initState();
    widget.analysisController.reset();
    _changes = Listenable.merge(
        [widget.controller, widget.analysisController, widget.matchController]);
  }

  @override
  void dispose() {
    if (_preview != null) unawaited(MemoryImage(_preview!).evict());
    _preview = null;
    _image = null;
    _data.dispose();
    super.dispose();
  }

  void showMessage(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
  Future<void> selectImage() async {
    try {
      final image = await widget.pickImage();
      if (image == null || !mounted) return;
      widget.analysisController.reset();
      if (_preview != null) unawaited(MemoryImage(_preview!).evict());
      setState(() {
        _image = image;
        _preview = Uint8List.fromList(image.bytes);
        _photoUploaded = false;
        _photoFailure = false;
      });
    } catch (error) {
      if (mounted) showMessage(apiMessage(error));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _changes = Listenable.merge([
      widget.controller,
      widget.analysisController,
      widget.matchController,
      if (ReportImageScope.maybeOf(context) case final controller?) controller
    ]);
  }

  Future<void> analyze() async {
    if (_image == null || _preview == null) {
      showMessage(AppStrings.selectImageFirst);
      return;
    }
    if (_data.description.text.trim().length <
        ApiConstants.minimumAnalysisDescriptionLength) {
      showMessage(AppStrings.writeDescriptionFirst);
      return;
    }
    final success = await widget.analysisController.analyze(ObjectImageInput(
        bytes: _preview!,
        fileName: _image!.filename,
        mimeType: _image!.contentType,
        description: _data.description.text.trim()));
    if (!mounted) return;
    final analysis = widget.analysisController.analysis;
    if (success && analysis != null) {
      setState(() => _data.applyAnalysis(analysis));
      showMessage(analysis.objectDetected
          ? AppStrings.analysisCompletedMessage
          : AppStrings.noObjectDetected);
    }
  }

  Future<void> submit() async {
    if (_submitting ||
        widget.analysisController.isAnalyzing ||
        (_savedReport == null && !(_formKey.currentState?.validate() ?? false)))
      return;
    setState(() => _submitting = true);
    try {
      _savedReport ??= await widget.controller.register(
          _data.draft(widget.type, widget.analysisController.analysis));
      if (!mounted) return;
      final saved = _savedReport;
      if (saved == null) {
        showMessage(
            widget.controller.actionMessage ?? AppStrings.unexpectedError);
        return;
      }
      if (_image != null && !_photoUploaded) {
        final images = ReportImageScope.maybeOf(context);
        final uploaded = await images?.upload(saved.id, _image!);
        if (!mounted) return;
        if (uploaded == null) {
          setState(() => _photoFailure = true);
          return;
        }
        _photoUploaded = true;
        _photoFailure = false;
        await widget.controller.refresh();
        if (!mounted) return;
      }
      final result = await widget.matchController.generate(saved.id);
      if (!mounted) return;
      if (result == null) {
        Navigator.pushReplacementNamed(context, AppRoutes.reportDetail,
            arguments: saved.id);
        showMessage(AppStrings.reportSavedMatchesFailed);
      } else {
        widget.matchController.resetFilters();
        Navigator.pushReplacementNamed(context, AppRoutes.matches);
        showMessage(AppStrings.generatedCount(result.items.length));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _changes,
      builder: (context, _) {
        final analysis = widget.analysisController;
        final busy = _submitting || analysis.isAnalyzing;
        return PopScope(
            canPop: !_submitting,
            child: Scaffold(
              appBar: AppBar(
                  title: Text(widget.type == ReportType.lost
                      ? AppStrings.reportLostTitle
                      : AppStrings.reportFoundTitle)),
              body: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.spacingMLarge),
                  child: Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: AppSizes.objectFormMaxWidth),
                          child: Form(
                              key: _formKey,
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(widget.type == ReportType.lost
                                        ? AppStrings.lostFormIntro
                                        : AppStrings.foundFormIntro),
                                    const SizedBox(
                                        height: AppSizes.spacingMedium),
                                    Card(
                                        child: Padding(
                                            padding: const EdgeInsets.all(
                                                AppSizes.spacingMedium),
                                            child: Column(children: [
                                              if (_preview != null)
                                                Image.memory(_preview!,
                                                    height: AppSizes
                                                        .imagePreviewHeight,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, error,
                                                            stack) =>
                                                        const Icon(
                                                            Icons
                                                                .broken_image_outlined,
                                                            size: AppSizes
                                                                .iconLarge,
                                                            color: AppColors
                                                                .textSecondary)),
                                              if (_preview == null)
                                                const Icon(
                                                    Icons
                                                        .add_photo_alternate_outlined,
                                                    size: AppSizes.iconLarge,
                                                    color: AppColors
                                                        .textSecondary),
                                              const Text(AppStrings.photoHelp),
                                              OutlinedButton.icon(
                                                  onPressed:
                                                      busy || _photoUploaded
                                                          ? null
                                                          : selectImage,
                                                  icon: const Icon(Icons
                                                      .photo_library_outlined),
                                                  label: Text(_preview == null
                                                      ? AppStrings.selectPhoto
                                                      : AppStrings
                                                          .changePhoto)),
                                            ]))),
                                    ReportFormFields(
                                        data: _data,
                                        enabled: !busy && _savedReport == null),
                                    FilledButton.tonalIcon(
                                        onPressed: busy || _savedReport != null
                                            ? null
                                            : analyze,
                                        icon: const Icon(Icons.auto_awesome),
                                        label: Text(analysis.isAnalyzing
                                            ? AppStrings.analyzingImage
                                            : AppStrings.analyzeWithAi)),
                                    if (analysis.message != null)
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical:
                                                  AppSizes.spacingRegular),
                                          child: Text(analysis.message!)),
                                    if (analysis.analysis != null)
                                      Wrap(
                                          spacing: AppSizes.spacingSmall,
                                          children: [
                                            const Chip(
                                                label: Text(AppStrings
                                                    .imageAnalysisBadge)),
                                            ...analysis
                                                .analysis!.visibleFeatures
                                                .map((feature) =>
                                                    Chip(label: Text(feature))),
                                          ]),
                                    const SizedBox(
                                        height: AppSizes.spacingLarge),
                                    if (_photoFailure)
                                      const Text(
                                          AppStrings.reportSavedPhotoFailed),
                                    if (_savedReport != null &&
                                        ReportImageScope.maybeOf(context)
                                                ?.message(_savedReport!.id) !=
                                            null)
                                      Text(ReportImageScope.maybeOf(context)!
                                          .message(_savedReport!.id)!),
                                    FilledButton.icon(
                                        onPressed: busy ? null : submit,
                                        icon: busy
                                            ? const SizedBox(
                                                width: AppSizes.iconMedium,
                                                height: AppSizes.iconMedium,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: AppSizes
                                                            .strokeWidth))
                                            : const Icon(
                                                Icons.check_circle_outline),
                                        label: Text(_savedReport != null &&
                                                (ReportImageScope.maybeOf(
                                                            context)
                                                        ?.isBusy(
                                                            _savedReport!.id) ??
                                                    false)
                                            ? AppStrings.uploadingPhoto
                                            : widget.matchController
                                                    .isGenerating
                                                ? AppStrings.generatingMatches
                                                : _submitting
                                                    ? AppStrings.savingReport
                                                    : _photoFailure
                                                        ? AppStrings
                                                            .retryPhotoUpload
                                                        : AppStrings
                                                            .registerReport)),
                                  ]))))),
            ));
      });
}
