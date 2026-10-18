import 'dart:typed_data';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/report_image.dart';

class ReportImageRemoteDataSource {
  const ReportImageRemoteDataSource(this.api);
  final AuthenticatedApiClient api;
  Future<Map<String, dynamic>> upload(String id, ReportImageUpload image) =>
      api.uploadImage(ApiConstants.reportImagePath(id), image.bytes,
          image.filename, image.contentType);
  Future<Map<String, dynamic>> metadata(String id) async =>
      (await api.request('GET', ApiConstants.reportImagePath(id)))!;
  Future<Uint8List> content(String id) =>
      api.downloadImage(ApiConstants.reportImageContentPath(id));
  Future<void> delete(String id) =>
      api.request('DELETE', ApiConstants.reportImagePath(id),
          expectedStatus: ApiConstants.noContent);
}
