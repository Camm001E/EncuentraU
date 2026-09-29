class ObjectAnalysisException implements Exception {
  const ObjectAnalysisException(this.message);

  final String message;

  @override
  String toString() => message;
}
