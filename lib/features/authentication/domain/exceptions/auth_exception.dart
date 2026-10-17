enum AuthFailure {
  invalidCredentials,
  sessionExpired,
  inactiveAccount,
  duplicateAccount,
  invalidData,
  server,
  connection,
  invalidResponse,
  storage,
  unexpected,
}

final class AuthException implements Exception {
  const AuthException(this.failure);
  final AuthFailure failure;
}
