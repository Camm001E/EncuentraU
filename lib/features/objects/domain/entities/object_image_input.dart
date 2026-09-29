class ObjectImageInput {
  const ObjectImageInput({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.description,
  });

  final List<int> bytes;
  final String fileName;
  final String mimeType;
  final String description;
}
