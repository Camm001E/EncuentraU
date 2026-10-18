import 'dart:typed_data';
import '../entities/report_image.dart';

abstract interface class ReportImageRepository {
  Future<ReportImageReference> upload(String reportId, ReportImageUpload image);
  Future<ReportImageReference> getMetadata(String reportId);
  Future<Uint8List> getContent(String reportId);
  Future<void> delete(String reportId);
}
