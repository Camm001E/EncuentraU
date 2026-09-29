import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/object_image_analysis.dart';
import '../../domain/entities/object_image_input.dart';
import '../../domain/entities/object_report.dart';
import '../constants/object_form_options.dart';
import '../controllers/object_analysis_controller.dart';
import '../controllers/object_controller.dart';

class RegisterObjectPage extends StatefulWidget {
  const RegisterObjectPage({
    required this.type,
    required this.controller,
    required this.analysisController,
    super.key,
  });

  final ReportType type;
  final ObjectController controller;
  final ObjectAnalysisController analysisController;

  @override
  State<RegisterObjectPage> createState() => _RegisterObjectPageState();
}

class _RegisterObjectPageState extends State<RegisterObjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _privateFeatureController = TextEditingController();
  final _descriptionFocusNode = FocusNode();
  final _imagePicker = ImagePicker();

  late final Listenable _pageListenable;

  String _category = ObjectFormOptions.categories.first;
  String _color = ObjectFormOptions.colors.first;
  DateTime _eventDate = DateTime.now();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  bool get _isLost => widget.type == ReportType.lost;

  @override
  void initState() {
    super.initState();

    widget.analysisController.reset();

    _pageListenable = Listenable.merge([
      widget.controller,
      widget.analysisController,
    ]);
  }

  @override
  void dispose() {
    _brandController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _privateFeatureController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2048,
      );

      if (image == null) {
        return;
      }

      final mimeType = _mimeTypeFor(image);

      if (mimeType == null) {
        _showMessage(AppStrings.unsupportedImage);
        return;
      }

      final bytes = await image.readAsBytes();

      if (bytes.length > ApiConstants.maxImageSizeBytes) {
        _showMessage(AppStrings.imageTooLarge);
        return;
      }

      if (!mounted) {
        return;
      }

      widget.analysisController.reset();

      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    } catch (_) {
      if (mounted) {
        _showMessage(AppStrings.imagePickerError);
      }
    }
  }

  Future<void> _analyzeImage() async {
    final image = _selectedImage;
    final bytes = _selectedImageBytes;

    if (image == null || bytes == null) {
      _showMessage(AppStrings.selectImageFirst);
      return;
    }

    final description = _descriptionController.text.trim();

    if (description.length < ApiConstants.minimumAnalysisDescriptionLength) {
      _descriptionFocusNode.requestFocus();
      _showMessage(AppStrings.writeDescriptionFirst);
      return;
    }

    final mimeType = _mimeTypeFor(image);

    if (mimeType == null) {
      _showMessage(AppStrings.unsupportedImage);
      return;
    }

    final success = await widget.analysisController.analyze(
      ObjectImageInput(
        bytes: bytes,
        fileName: image.name,
        mimeType: mimeType,
        description: description,
      ),
    );

    if (!mounted) {
      return;
    }

    final analysis = widget.analysisController.analysis;

    if (success && analysis != null) {
      _applyAnalysis(analysis);

      _showMessage(
        analysis.objectDetected
            ? AppStrings.analysisCompletedMessage
            : AppStrings.noObjectDetected,
      );

      return;
    }

    _showMessage(
      widget.analysisController.message ?? AppStrings.analysisUnavailable,
    );
  }

  void _applyAnalysis(ObjectImageAnalysis analysis) {
    if (!analysis.objectDetected) {
      return;
    }

    setState(() {
      _category = ObjectFormOptions.categoryFromAnalysis(analysis);

      _color = ObjectFormOptions.colorFromAnalysis(
        analysis.primaryColor,
      );

      final brand = analysis.brand?.trim();

      if (brand != null && brand.isNotEmpty) {
        _brandController.text = brand;
      }
    });
  }

  String? _mimeTypeFor(XFile image) {
    final reportedMimeType = image.mimeType?.toLowerCase();

    if (reportedMimeType != null &&
        ApiConstants.allowedImageMimeTypes.contains(
          reportedMimeType,
        )) {
      return reportedMimeType;
    }

    final fileName = image.name.toLowerCase();

    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    if (fileName.endsWith('.png')) {
      return 'image/png';
    }

    if (fileName.endsWith('.webp')) {
      return 'image/webp';
    }

    return null;
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _eventDate = selectedDate;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final report = ObjectReport(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      type: widget.type,
      category: _category,
      color: _color,
      brand: _brandController.text.trim().isEmpty
          ? AppStrings.unidentifiedBrand
          : _brandController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      eventDate: _eventDate,
      privateFeature: _privateFeatureController.text.trim(),
      status: ReportStatus.active,
      imageLabel: _selectedImage?.name,
      imageAnalysis: widget.analysisController.analysis,
    );

    final success = await widget.controller.register(report);

    if (!mounted) {
      return;
    }

    _showMessage(
      widget.controller.message ?? AppStrings.processCompleted,
    );

    if (success) {
      widget.controller.clearMessage();

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.objects,
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _isLost ? AppStrings.reportLostTitle : AppStrings.reportFoundTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: AnimatedBuilder(
        animation: _pageListenable,
        builder: (context, _) {
          final analysisController = widget.analysisController;

          final analysis = analysisController.analysis;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.objectFormMaxWidth,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FormIntro(
                        isLost: _isLost,
                      ),
                      const SizedBox(
                        height: AppSizes.spacingMLarge,
                      ),
                      _ImageSelector(
                        imageBytes: _selectedImageBytes,
                        fileName: _selectedImage?.name,
                        isBusy: analysisController.isAnalyzing,
                        onPressed: _selectImage,
                      ),
                      const SizedBox(
                        height: AppSizes.spacingMedium,
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        focusNode: _descriptionFocusNode,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: AppStrings.descriptionLabel,
                          hintText: AppStrings.descriptionHint,
                          alignLabelWithHint: true,
                          prefixIcon: Icon(
                            Icons.description_outlined,
                          ),
                        ),
                        validator: _requiredField,
                      ),
                      const SizedBox(
                        height: AppSizes.spacingRegular,
                      ),
                      FilledButton.tonalIcon(
                        onPressed: analysisController.isAnalyzing
                            ? null
                            : _analyzeImage,
                        icon: analysisController.isAnalyzing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.auto_awesome_rounded,
                              ),
                        label: Text(
                          analysisController.isAnalyzing
                              ? AppStrings.analyzingImage
                              : AppStrings.analyzeWithAi,
                        ),
                      ),
                      if (analysisController.status ==
                          ObjectAnalysisStatus.failure) ...[
                        const SizedBox(
                          height: AppSizes.spacingRegular,
                        ),
                        _AnalysisMessageCard(
                          message: analysisController.message ??
                              AppStrings.analysisUnavailable,
                          isError: true,
                        ),
                      ],
                      if (analysis != null) ...[
                        const SizedBox(
                          height: AppSizes.spacingMedium,
                        ),
                        _AnalysisResultCard(
                          analysis: analysis,
                        ),
                      ],
                      const SizedBox(
                        height: AppSizes.spacingMLarge,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(
                                'category-$_category',
                              ),
                              initialValue: _category,
                              decoration: const InputDecoration(
                                labelText: AppStrings.objectTypeLabel,
                                prefixIcon: Icon(
                                  Icons.category_outlined,
                                ),
                              ),
                              items: ObjectFormOptions.categories
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _category = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(
                            width: AppSizes.spacingRegular,
                          ),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(
                                'color-$_color',
                              ),
                              initialValue: _color,
                              decoration: const InputDecoration(
                                labelText: AppStrings.primaryColorLabel,
                                prefixIcon: Icon(
                                  Icons.palette_outlined,
                                ),
                              ),
                              items: ObjectFormOptions.colors
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _color = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: AppSizes.spacingRegular,
                      ),
                      TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.optionalBrandLabel,
                          prefixIcon: Icon(
                            Icons.sell_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: AppSizes.spacingRegular,
                      ),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: _isLost
                              ? AppStrings.lostLocationLabel
                              : AppStrings.foundLocationLabel,
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                          ),
                        ),
                        validator: _requiredField,
                      ),
                      const SizedBox(
                        height: AppSizes.spacingRegular,
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusLarge,
                        ),
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: AppStrings.eventDateLabel,
                            prefixIcon: Icon(
                              Icons.calendar_today_outlined,
                            ),
                          ),
                          child: Text(
                            formatDate(_eventDate),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: AppSizes.spacingRegular,
                      ),
                      TextFormField(
                        controller: _privateFeatureController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: AppStrings.privateFeatureLabel,
                          hintText: _isLost
                              ? AppStrings.lostPrivateFeatureHint
                              : AppStrings.foundPrivateFeatureHint,
                          alignLabelWithHint: true,
                          prefixIcon: const Icon(
                            Icons.shield_outlined,
                          ),
                        ),
                        validator: _requiredField,
                      ),
                      const SizedBox(
                        height: AppSizes.spacingLarge,
                      ),
                      FilledButton.icon(
                        onPressed: widget.controller.isSaving ||
                                analysisController.isAnalyzing
                            ? null
                            : _submit,
                        icon: widget.controller.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.surface,
                                ),
                              )
                            : const Icon(
                                Icons.check_circle_outline_rounded,
                              ),
                        label: Text(
                          widget.controller.isSaving
                              ? AppStrings.savingReport
                              : AppStrings.registerReport,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }

    return null;
  }
}

class _FormIntro extends StatelessWidget {
  const _FormIntro({
    required this.isLost,
  });

  final bool isLost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        AppSizes.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: isLost ? AppColors.lostBackground : AppColors.foundBackground,
        borderRadius: BorderRadius.circular(
          AppSizes.radiusXLarge,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLost
                ? Icons.search_off_rounded
                : Icons.volunteer_activism_rounded,
            color: isLost ? AppColors.lost : AppColors.primary,
            size: 34,
          ),
          const SizedBox(
            width: AppSizes.spacingRegular,
          ),
          Expanded(
            child: Text(
              isLost ? AppStrings.lostFormIntro : AppStrings.foundFormIntro,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSelector extends StatelessWidget {
  const _ImageSelector({
    required this.imageBytes,
    required this.fileName,
    required this.isBusy,
    required this.onPressed,
  });

  final Uint8List? imageBytes;
  final String? fileName;
  final bool isBusy;
  final VoidCallback onPressed;

  bool get hasImage => imageBytes != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        AppSizes.spacingMLarge,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppSizes.radiusXLarge,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(
                AppSizes.radiusLarge,
              ),
              child: Image.memory(
                imageBytes!,
                width: double.infinity,
                height: AppSizes.imagePreviewHeight,
                fit: BoxFit.contain,
              ),
            )
          else
            const Icon(
              Icons.add_photo_alternate_outlined,
              size: 56,
              color: AppColors.textSecondary,
            ),
          const SizedBox(
            height: AppSizes.spacingRegular,
          ),
          Text(
            hasImage ? AppStrings.selectedPhoto : AppStrings.addPhoto,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (fileName != null) ...[
            const SizedBox(height: 4),
            Text(
              fileName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            AppStrings.photoHelp,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(
            height: AppSizes.spacingRegular,
          ),
          OutlinedButton.icon(
            onPressed: isBusy ? null : onPressed,
            icon: const Icon(
              Icons.photo_library_outlined,
            ),
            label: Text(
              hasImage ? AppStrings.changePhoto : AppStrings.selectPhoto,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisResultCard extends StatelessWidget {
  const _AnalysisResultCard({
    required this.analysis,
  });

  final ObjectImageAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final isWarning = !analysis.objectDetected || analysis.requiresAnotherPhoto;

    return Container(
      padding: const EdgeInsets.all(
        AppSizes.spacingMedium,
      ),
      decoration: BoxDecoration(
        color:
            isWarning ? AppColors.warningBackground : AppColors.foundBackground,
        borderRadius: BorderRadius.circular(
          AppSizes.radiusLarge,
        ),
        border: Border.all(
          color: isWarning ? AppColors.warning : AppColors.primary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isWarning
                    ? Icons.warning_amber_rounded
                    : Icons.auto_awesome_rounded,
                color: isWarning ? AppColors.warning : AppColors.primary,
              ),
              const SizedBox(
                width: AppSizes.spacingSmall,
              ),
              Expanded(
                child: Text(
                  analysis.objectDetected
                      ? AppStrings.analysisCompleted
                      : AppStrings.noObjectDetected,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (analysis.requiresAnotherPhoto) ...[
            const SizedBox(
              height: AppSizes.spacingSmall,
            ),
            const Text(
              AppStrings.anotherPhotoRecommended,
            ),
          ],
          if (analysis.objectDetected) ...[
            const SizedBox(
              height: AppSizes.spacingRegular,
            ),
            Wrap(
              spacing: AppSizes.spacingSmall,
              runSpacing: AppSizes.spacingSmall,
              children: [
                _AnalysisDetail(
                  label: AppStrings.detectedObject,
                  value: analysis.objectType ?? AppStrings.unidentifiedBrand,
                ),
                if (analysis.shape != null)
                  _AnalysisDetail(
                    label: AppStrings.detectedShape,
                    value: analysis.shape!,
                  ),
                if (analysis.primaryColor != null)
                  _AnalysisDetail(
                    label: AppStrings.primaryColorLabel,
                    value: analysis.primaryColor!,
                  ),
                if (analysis.brand != null)
                  _AnalysisDetail(
                    label: AppStrings.detectedBrand,
                    value: analysis.brand!,
                  ),
                _AnalysisDetail(
                  label: AppStrings.imageQuality,
                  value: analysis.imageQuality,
                ),
                _AnalysisDetail(
                  label: AppStrings.confidence,
                  value: analysis.confidence,
                ),
              ],
            ),
          ],
          if (analysis.visibleFeatures.isNotEmpty) ...[
            const SizedBox(
              height: AppSizes.spacingRegular,
            ),
            const Text(
              AppStrings.visibleFeatures,
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: AppSizes.spacingSmall,
            ),
            Wrap(
              spacing: AppSizes.spacingSmall,
              runSpacing: AppSizes.spacingSmall,
              children: analysis.visibleFeatures
                  .map(
                    (feature) => Chip(
                      label: Text(feature),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (analysis.visibleText.isNotEmpty) ...[
            const SizedBox(
              height: AppSizes.spacingRegular,
            ),
            Text(
              '${AppStrings.visibleText}: '
              '${analysis.visibleText.join(', ')}',
            ),
          ],
          if (analysis.warnings.isNotEmpty) ...[
            const SizedBox(
              height: AppSizes.spacingRegular,
            ),
            ...analysis.warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $warning'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalysisDetail extends StatelessWidget {
  const _AnalysisDetail({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppSizes.radiusLarge,
        ),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _AnalysisMessageCard extends StatelessWidget {
  const _AnalysisMessageCard({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        AppSizes.spacingRegular,
      ),
      decoration: BoxDecoration(
        color: isError ? AppColors.lostBackground : AppColors.foundBackground,
        borderRadius: BorderRadius.circular(
          AppSizes.radiusLarge,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: isError ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(
            width: AppSizes.spacingSmall,
          ),
          Expanded(
            child: Text(message),
          ),
        ],
      ),
    );
  }
}
