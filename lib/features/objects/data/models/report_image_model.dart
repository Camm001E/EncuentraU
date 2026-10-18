import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/entities/report_image.dart';

abstract final class ReportImageModel {
  static ReportImageReference? forReport(dynamic json, String reportId) {
    if (json == null) return null;
    final image = fromJson(JsonReader.object(json));
    if (image.reportId != reportId) throw const FormatException();
    return image;
  }

  static ReportImageReference fromJson(Map<String, dynamic> json) {
    final value = ReportImageReference(
        id: JsonReader.string(json['id']),
        reportId: JsonReader.string(json['report_id']),
        contentType: JsonReader.string(json['content_type']),
        sizeBytes: JsonReader.integer(json['size_bytes']),
        sha256: JsonReader.string(json['sha256']),
        width: JsonReader.integer(json['width']),
        height: JsonReader.integer(json['height']),
        createdAt: JsonReader.date(json['created_at']),
        updatedAt: JsonReader.date(json['updated_at']));
    if (!ApiConstants.allowedImageMimeTypes.contains(value.contentType) ||
        value.sizeBytes <= 0 ||
        value.width <= 0 ||
        value.height <= 0 ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(value.sha256))
      throw const FormatException();
    return value;
  }
}
