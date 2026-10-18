import 'dart:typed_data';
import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/report_image.dart';
import '../../domain/repositories/report_image_repository.dart';
import '../datasources/report_image_remote_data_source.dart';
import '../models/report_image_model.dart';

class ReportImageRepositoryImpl implements ReportImageRepository {
  const ReportImageRepositoryImpl(this.source);
  final ReportImageRemoteDataSource source;
  Future<ReportImageReference> _parse(
      Future<Map<String, dynamic>> response, String reportId) async {
    try {
      return ReportImageModel.forReport(await response, reportId)!;
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  @override
  Future<ReportImageReference> upload(String id, ReportImageUpload image) =>
      _parse(source.upload(id, image), id);
  @override
  Future<ReportImageReference> getMetadata(String id) =>
      _parse(source.metadata(id), id);
  @override
  Future<Uint8List> getContent(String id) => source.content(id);
  @override
  Future<void> delete(String id) => source.delete(id);
}
