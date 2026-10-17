import '../../../../core/network/json_reader.dart';
import '../../domain/entities/object_image_analysis.dart';
import '../../domain/entities/object_report.dart';
import '../../domain/entities/report_page.dart';

String reportDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

abstract final class ReportCreateModel {
  static String? _optional(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
  static Map<String, dynamic> analysisJson(ObjectImageAnalysis value) => {
        'object_detected': value.objectDetected,
        'object_type': value.objectType,
        'category': value.category,
        'primary_color': value.primaryColor,
        'secondary_colors': List<String>.of(value.secondaryColors),
        'brand': value.brand,
        'shape': value.shape,
        'visible_features': List<String>.of(value.visibleFeatures),
        'visible_text': List<String>.of(value.visibleText),
        'image_quality': value.imageQuality,
        'confidence': value.confidence,
        'requires_another_photo': value.requiresAnotherPhoto,
        'warnings': List<String>.of(value.warnings),
      };
  static Map<String, dynamic> toJson(ObjectReportDraft draft) => {
        'report_type': draft.reportType.name,
        'object_type': draft.objectType.trim(),
        'category': draft.category.trim(),
        'primary_color': _optional(draft.primaryColor),
        'secondary_colors': List<String>.of(draft.secondaryColors),
        'brand': _optional(draft.brand),
        'shape': _optional(draft.shape),
        'description': draft.description.trim(),
        'location': draft.location.trim(),
        'event_date': reportDate(draft.eventDate),
        'private_feature': _optional(draft.privateFeature),
        if (draft.imageAnalysis != null)
          'analysis': {
            'extracted_data': analysisJson(draft.imageAnalysis!),
            'confidence': draft.imageAnalysis!.confidence,
          },
      };
}

abstract final class ReportUpdateModel {
  static Map<String, dynamic> toJson(ObjectReportUpdate update) => {
        if (update.objectType != null) 'object_type': update.objectType!.trim(),
        if (update.category != null) 'category': update.category!.trim(),
        if (update.primaryColor != null)
          'primary_color': update.primaryColor!.value,
        if (update.secondaryColors != null)
          'secondary_colors': List<String>.of(update.secondaryColors!),
        if (update.brand != null) 'brand': update.brand!.value,
        if (update.shape != null) 'shape': update.shape!.value,
        if (update.description != null)
          'description': update.description!.trim(),
        if (update.location != null) 'location': update.location!.trim(),
        if (update.eventDate != null)
          'event_date': reportDate(update.eventDate!),
        if (update.privateFeature != null)
          'private_feature': update.privateFeature!.value,
        if (update.status != null) 'status': update.status!.name,
      };
}

abstract final class ObjectReportModel {
  static ObjectReport fromJson(Map<String, dynamic> json) {
    StoredImageAnalysis? analysis;
    if (json['analysis'] != null) {
      final data = JsonReader.object(json['analysis']);
      analysis = StoredImageAnalysis(
          id: JsonReader.string(data['id']),
          reportId: JsonReader.string(data['report_id']),
          provider: JsonReader.string(data['provider']),
          model: JsonReader.string(data['model']),
          extractedData: Map<String, dynamic>.unmodifiable(
              JsonReader.object(data['extracted_data'])),
          confidence: JsonReader.string(data['confidence']),
          createdAt: JsonReader.date(data['created_at']));
    }
    return ObjectReport(
        id: JsonReader.string(json['id']),
        reportType:
            JsonReader.enumeration(json['report_type'], ReportType.values),
        status: JsonReader.enumeration(json['status'], ReportStatus.values),
        objectType: JsonReader.string(json['object_type']),
        category: JsonReader.string(json['category']),
        primaryColor: JsonReader.optionalString(json['primary_color']),
        secondaryColors: JsonReader.strings(json['secondary_colors']),
        brand: JsonReader.optionalString(json['brand']),
        shape: JsonReader.optionalString(json['shape']),
        description: JsonReader.string(json['description']),
        location: JsonReader.string(json['location']),
        eventDate: JsonReader.date(json['event_date']),
        privateFeature: JsonReader.optionalString(json['private_feature']),
        imageAnalysis: analysis,
        createdAt: JsonReader.date(json['created_at']),
        updatedAt: JsonReader.date(json['updated_at']));
  }

  static ReportPage page(Map<String, dynamic> json) => ReportPage(
      items: JsonReader.list(
          json['items'], (item) => fromJson(JsonReader.object(item))),
      total: JsonReader.integer(json['total']),
      limit: JsonReader.integer(json['limit']),
      offset: JsonReader.integer(json['offset']));
}
