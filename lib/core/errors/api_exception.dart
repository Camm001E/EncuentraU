enum ApiFailure {
  invalidData,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  server,
  connection,
  timeout,
  invalidResponse,
  storage,
}

class ApiException implements Exception {
  const ApiException(this.failure);
  final ApiFailure failure;
}
