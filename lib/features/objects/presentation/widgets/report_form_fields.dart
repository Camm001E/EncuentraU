import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/object_image_analysis.dart';
import '../../domain/entities/object_report.dart';
import '../../../../core/presentation/widgets/design_system.dart';

class ReportFormData {
  ReportFormData({ObjectReport? report}) {
    objectType.text = report?.objectType ?? '';
    category.text = report?.category ?? AppStrings.defaultCategory;
    primaryColor.text = report?.primaryColor ?? '';
    secondaryColors.text = report?.secondaryColors.join(', ') ?? '';
    brand.text = report?.brand ?? '';
    shape.text = report?.shape ?? '';
    description.text = report?.description ?? '';
    location.text = report?.location ?? '';
    privateFeature.text = report?.privateFeature ?? '';
    eventDate = report?.eventDate ?? DateTime.now();
  }
  final objectType = TextEditingController(),
      category = TextEditingController(),
      primaryColor = TextEditingController(),
      secondaryColors = TextEditingController(),
      brand = TextEditingController(),
      shape = TextEditingController(),
      description = TextEditingController(),
      location = TextEditingController(),
      privateFeature = TextEditingController();
  late DateTime eventDate;
  String? optional(TextEditingController value) =>
      value.text.trim().isEmpty ? null : value.text.trim();
  List<String> get colors => secondaryColors.text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();
  void applyAnalysis(ObjectImageAnalysis value) {
    if (!value.objectDetected) return;
    objectType.text = value.objectType ?? objectType.text;
    category.text = value.category;
    primaryColor.text = value.primaryColor ?? '';
    secondaryColors.text = value.secondaryColors.join(', ');
    brand.text = value.brand ?? '';
    shape.text = value.shape ?? '';
  }

  ObjectReportDraft draft(ReportType type, ObjectImageAnalysis? analysis) =>
      ObjectReportDraft(
          reportType: type,
          objectType: objectType.text,
          category: category.text,
          description: description.text,
          location: location.text,
          eventDate: eventDate,
          primaryColor: optional(primaryColor),
          secondaryColors: colors,
          brand: optional(brand),
          shape: optional(shape),
          privateFeature: optional(privateFeature),
          imageAnalysis: analysis);
  ObjectReportUpdate update({ReportStatus? status}) => ObjectReportUpdate(
      objectType: objectType.text,
      category: category.text,
      description: description.text,
      location: location.text,
      eventDate: eventDate,
      primaryColor: FieldUpdate(optional(primaryColor)),
      secondaryColors: colors,
      brand: FieldUpdate(optional(brand)),
      shape: FieldUpdate(optional(shape)),
      privateFeature: FieldUpdate(optional(privateFeature)),
      status: status);
  void dispose() {
    for (final controller in [
      objectType,
      category,
      primaryColor,
      secondaryColors,
      brand,
      shape,
      description,
      location,
      privateFeature
    ]) {
      controller.dispose();
    }
  }
}

class ReportFormFields extends StatefulWidget {
  const ReportFormFields(
      {required this.data,
      this.enabled = true,
      this.includeDescription = true,
      this.firstStep = 1,
      super.key});
  final ReportFormData data;
  final bool enabled;
  final bool includeDescription;
  final int firstStep;
  @override
  State<ReportFormFields> createState() => _ReportFormFieldsState();
}

class _ReportFormFieldsState extends State<ReportFormFields> {
  Widget field(String name, TextEditingController controller, String label,
          int maximum,
          {bool mandatory = false, bool multiline = false, String? hint}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacingRegular),
          child: TextFormField(
              key: ValueKey('report-$name'),
              controller: controller,
              enabled: widget.enabled,
              minLines: multiline ? 2 : 1,
              maxLines: multiline ? 4 : 1,
              decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  alignLabelWithHint: multiline),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (mandatory && text.isEmpty) return AppStrings.requiredField;
                if (text.length > maximum) return AppStrings.fieldTooLong;
                if (name == 'secondary-colors' &&
                    (widget.data.colors.length >
                            ApiConstants.maxSecondaryColors ||
                        widget.data.colors.any((color) =>
                            color.length > ApiConstants.colorMaxLength)))
                  return AppStrings.apiInvalidData;
                return null;
              }));
  Future<void> pickDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: widget.data.eventDate,
        firstDate: DateTime(1),
        lastDate: DateTime.now());
    if (!mounted || date == null) return;
    setState(() => widget.data.eventDate = date);
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionHeading(
            title:
                AppStrings.stepLabel(widget.firstStep, AppStrings.objectStep)),
        field('object-type', widget.data.objectType, AppStrings.objectTypeLabel,
            ApiConstants.objectTypeMaxLength,
            mandatory: true),
        field('category', widget.data.category, AppStrings.categoryLabel,
            ApiConstants.categoryMaxLength,
            mandatory: true, hint: AppStrings.categoryHelp),
        if (widget.includeDescription)
          field('description', widget.data.description,
              AppStrings.descriptionLabel, ApiConstants.descriptionMaxLength,
              mandatory: true, multiline: true),
        field('primary-color', widget.data.primaryColor,
            AppStrings.primaryColorLabel, ApiConstants.colorMaxLength),
        field(
            'secondary-colors',
            widget.data.secondaryColors,
            AppStrings.secondaryColorsLabel,
            ApiConstants.maxSecondaryColors *
                (ApiConstants.colorMaxLength + 1)),
        field('brand', widget.data.brand, AppStrings.optionalBrandLabel,
            ApiConstants.brandMaxLength),
        field('shape', widget.data.shape, AppStrings.shapeLabel,
            ApiConstants.shapeMaxLength),
        const SizedBox(height: AppSizes.spacingLarge),
        SectionHeading(
            title: AppStrings.stepLabel(
                widget.firstStep + 1, AppStrings.locationStep)),
        field('location', widget.data.location, AppStrings.locationLabel,
            ApiConstants.locationMaxLength,
            mandatory: true),
        OutlinedButton.icon(
            onPressed: widget.enabled ? pickDate : null,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
                '${AppStrings.eventDateLabel}: ${formatDate(widget.data.eventDate)}')),
        const SizedBox(height: AppSizes.spacingRegular),
        const SizedBox(height: AppSizes.spacingLarge),
        SectionHeading(
            title: AppStrings.stepLabel(
                widget.firstStep + 2, AppStrings.privateStep)),
        const InformationPanel(
            icon: Icons.lock_outline, child: Text(AppStrings.privateHelp)),
        const SizedBox(height: AppSizes.spacingMedium),
        field(
            'private-feature',
            widget.data.privateFeature,
            AppStrings.privateFeatureLabel,
            ApiConstants.privateFeatureMaxLength,
            multiline: true),
      ]);
}

class ReportDescriptionField extends StatelessWidget {
  const ReportDescriptionField(
      {required this.data, required this.enabled, super.key});
  final ReportFormData data;
  final bool enabled;
  @override
  Widget build(BuildContext context) => TextFormField(
      key: const ValueKey('report-description'),
      controller: data.description,
      enabled: enabled,
      minLines: 2,
      maxLines: 4,
      decoration: const InputDecoration(
          labelText: AppStrings.descriptionLabel,
          hintText: AppStrings.descriptionHint),
      validator: (value) {
        if (value == null || value.trim().isEmpty)
          return AppStrings.requiredField;
        if (value.trim().length > ApiConstants.descriptionMaxLength)
          return AppStrings.fieldTooLong;
        return null;
      });
}
