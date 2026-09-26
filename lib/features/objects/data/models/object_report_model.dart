import '../../domain/entities/object_report.dart';

class ObjectReportModel extends ObjectReport {
  const ObjectReportModel({
    required super.id,
    required super.type,
    required super.category,
    required super.color,
    required super.brand,
    required super.description,
    required super.location,
    required super.eventDate,
    required super.privateFeature,
    required super.status,
    super.imageLabel,
  });

  factory ObjectReportModel.fromEntity(ObjectReport report) {
    return ObjectReportModel(
      id: report.id,
      type: report.type,
      category: report.category,
      color: report.color,
      brand: report.brand,
      description: report.description,
      location: report.location,
      eventDate: report.eventDate,
      privateFeature: report.privateFeature,
      status: report.status,
      imageLabel: report.imageLabel,
    );
  }
}
