import 'object_image_analysis.dart';
import 'report_image.dart';

enum ReportType { lost, found }

enum ReportStatus { active, resolved, cancelled }

class StoredImageAnalysis {
  const StoredImageAnalysis(
      {required this.id,
      required this.reportId,
      required this.provider,
      required this.model,
      required this.extractedData,
      required this.confidence,
      required this.createdAt});
  final String id, reportId, provider, model, confidence;
  final Map<String, dynamic> extractedData;
  final DateTime createdAt;
}

class ObjectReport {
  const ObjectReport(
      {required this.id,
      required this.reportType,
      required this.status,
      required this.objectType,
      required this.category,
      required this.description,
      required this.location,
      required this.eventDate,
      required this.createdAt,
      required this.updatedAt,
      this.primaryColor,
      this.secondaryColors = const [],
      this.brand,
      this.shape,
      this.privateFeature,
      this.imageAnalysis,
      this.evidenceLocked = false,
      this.image});
  final String id, objectType, category, description, location;
  final bool evidenceLocked;
  final ReportType reportType;
  final ReportStatus status;
  final String? primaryColor, brand, shape, privateFeature;
  final List<String> secondaryColors;
  final DateTime eventDate, createdAt, updatedAt;
  final StoredImageAnalysis? imageAnalysis;
  final ReportImageReference? image;
}

/// Creation carries no ID, owner, status, audit dates or photo/file data.
class ObjectReportDraft {
  const ObjectReportDraft(
      {required this.reportType,
      required this.objectType,
      required this.category,
      required this.description,
      required this.location,
      required this.eventDate,
      this.primaryColor,
      this.secondaryColors = const [],
      this.brand,
      this.shape,
      this.privateFeature,
      this.imageAnalysis});
  final ReportType reportType;
  final String objectType, category, description, location;
  final DateTime eventDate;
  final String? primaryColor, brand, shape, privateFeature;
  final List<String> secondaryColors;
  final ObjectImageAnalysis? imageAnalysis;
}

/// Present wrapper clears a nullable field with null; absent wrapper omits it.
class FieldUpdate<T> {
  const FieldUpdate(this.value);
  final T? value;
}

class ObjectReportUpdate {
  const ObjectReportUpdate(
      {this.objectType,
      this.category,
      this.primaryColor,
      this.secondaryColors,
      this.brand,
      this.shape,
      this.description,
      this.location,
      this.eventDate,
      this.privateFeature,
      this.status});
  final String? objectType, category, description, location;
  final FieldUpdate<String>? primaryColor, brand, shape, privateFeature;
  final List<String>? secondaryColors;
  final DateTime? eventDate;
  final ReportStatus? status;
}
