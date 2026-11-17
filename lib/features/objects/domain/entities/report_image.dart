class ReportImageReference {
  const ReportImageReference(
      {required this.id,
      required this.reportId,
      required this.contentType,
      required this.sizeBytes,
      required this.sha256,
      required this.width,
      required this.height,
      required this.createdAt,
      required this.updatedAt});
  final String id, reportId, contentType, sha256;
  final int sizeBytes, width, height;
  final DateTime createdAt, updatedAt;
  String get version => '$id:$sha256:${updatedAt.toIso8601String()}';
}

class ReportImageUpload {
  const ReportImageUpload(
      {required this.bytes, required this.filename, required this.contentType});
  final List<int> bytes;
  final String filename, contentType;
}
