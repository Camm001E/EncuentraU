enum AuthFailure {
  emailUnverified,
  verificationCode,
  rateLimited,
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
  const AuthException(this.failure, {this.retryAfter = 0});
  final AuthFailure failure;
  final int retryAfter;
}
