import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
      super.key});
  final ReportType type;
  final ObjectController controller;
  final ObjectAnalysisController analysisController;
  final MatchController matchController;
  @override
  State<RegisterObjectPage> createState() => _RegisterObjectPageState();
}

class _RegisterObjectPageState extends State<RegisterObjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _data = ReportFormData();
  XFile? _image;
  Uint8List? _preview;
  ObjectReport? _savedReport;
  bool _submitting = false;
  late final Listenable _changes;
  @override
  void initState() {
    super.initState();
    widget.analysisController.reset();
    _changes = Listenable.merge(
        [widget.controller, widget.analysisController, widget.matchController]);
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  void showMessage(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
  String? mimeType(XFile image) {
    if (ApiConstants.allowedImageMimeTypes.contains(image.mimeType))
      return image.mimeType;
    final name = image.name.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return null;
  }

  Future<void> selectImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;
      if (mimeType(image) == null) {
        showMessage(AppStrings.unsupportedImage);
        return;
      }
      if (await image.length() > ApiConstants.maxImageSizeBytes) {
        if (mounted) showMessage(AppStrings.imageTooLarge);
        return;
      }
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      widget.analysisController.reset();
      setState(() {
        _image = image;
        _preview = bytes;
      });
    } catch (_) {
      if (mounted) showMessage(AppStrings.imagePickerError);
    }
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
        fileName: _image!.name,
        mimeType: mimeType(_image!)!,
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
        !(_formKey.currentState?.validate() ?? false)) return;
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
                                                    fit: BoxFit.contain),
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
                                                      busy ? null : selectImage,
                                                  icon: const Icon(Icons
                                                      .photo_library_outlined),
                                                  label: Text(_preview == null
                                                      ? AppStrings.selectPhoto
                                                      : AppStrings
                                                          .changePhoto)),
                                            ]))),
                                    ReportFormFields(
                                        data: _data, enabled: !busy),
                                    FilledButton.tonalIcon(
                                        onPressed: busy ? null : analyze,
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
                                        label: Text(widget
                                                .matchController.isGenerating
                                            ? AppStrings.generatingMatches
                                            : _submitting
                                                ? AppStrings.savingReport
                                                : AppStrings.registerReport)),
                                  ]))))),
            ));
      });
}
