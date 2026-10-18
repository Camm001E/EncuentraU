import 'dart:typed_data';
import 'package:encuentra_u/features/objects/domain/entities/report_image.dart';
import 'package:encuentra_u/features/objects/domain/repositories/report_image_repository.dart';
import 'package:encuentra_u/features/objects/data/models/report_image_model.dart';
import 'package:encuentra_u/features/objects/domain/usecases/report_images.dart';
import 'package:encuentra_u/features/objects/presentation/controllers/report_image_controller.dart';
import '../remote/support.dart';

final png = Uint8List.fromList([
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  3,
  0,
  0,
  0,
  2,
  8,
  2,
  0,
  0,
  0,
  18,
  22,
  241,
  77,
  0,
  0,
  0,
  20,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  212,
  235,
  14,
  103,
  0,
  3,
  38,
  8,
  197,
  192,
  192,
  0,
  0,
  19,
  51,
  1,
  20,
  4,
  171,
  207,
  216,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130
]);
Map<String, dynamic> imageJson({String? reportId}) => {
      'id': 'image-id',
      'report_id': reportId ?? reportJson()['id'],
      'content_type': 'image/png',
      'size_bytes': png.length,
      'sha256': 'a' * 64,
      'width': 3,
      'height': 2,
      'created_at': '2026-10-17T12:00:00Z',
      'updated_at': '2026-10-17T12:00:00Z',
    };
ReportImageReference imageReference() => ReportImageModel.fromJson(imageJson());
ReportImageUpload uploadInput() => ReportImageUpload(
    bytes: png, filename: 'unit.png', contentType: 'image/png');

class ImageRepositoryStub implements ReportImageRepository {
  int uploads = 0, downloads = 0, metadataCalls = 0, deletes = 0;
  Future<ReportImageReference> Function()? onUpload;
  Future<Uint8List> Function()? onDownload;
  @override
  Future<ReportImageReference> upload(
      String id, ReportImageUpload image) async {
    uploads++;
    return onUpload == null ? imageReference() : await onUpload!();
  }

  @override
  Future<Uint8List> getContent(String id) async {
    downloads++;
    return onDownload == null ? png : await onDownload!();
  }

  @override
  Future<ReportImageReference> getMetadata(String id) async {
    metadataCalls++;
    return imageReference();
  }

  @override
  Future<void> delete(String id) async {
    deletes++;
  }
}

ReportImageController imageController(ImageRepositoryStub repo) =>
    ReportImageController(
        upload: UploadReportImage(repo),
        metadata: GetReportImage(repo),
        download: DownloadReportImage(repo),
        delete: DeleteReportImage(repo));
