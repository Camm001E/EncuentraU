sealed class AuthException implements Exception {
  const AuthException();
}

final class EmailAlreadyRegisteredException extends AuthException {
  const EmailAlreadyRegisteredException();
}

final class WeakPasswordException extends AuthException {
  const WeakPasswordException();
}
