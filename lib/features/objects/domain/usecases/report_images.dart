import 'dart:typed_data';
import '../entities/report_image.dart';
import '../repositories/report_image_repository.dart';

class UploadReportImage {
  const UploadReportImage(this.repository);
  final ReportImageRepository repository;
  Future<ReportImageReference> call(String id, ReportImageUpload image) =>
      repository.upload(id, image);
}

class GetReportImage {
  const GetReportImage(this.repository);
  final ReportImageRepository repository;
  Future<ReportImageReference> call(String id) => repository.getMetadata(id);
}

class DownloadReportImage {
  const DownloadReportImage(this.repository);
  final ReportImageRepository repository;
  Future<Uint8List> call(String id) => repository.getContent(id);
}

class DeleteReportImage {
  const DeleteReportImage(this.repository);
  final ReportImageRepository repository;
  Future<void> call(String id) => repository.delete(id);
}
