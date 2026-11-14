class VerificationRequestResult {
  const VerificationRequestResult(
      {required this.alreadyVerified, required this.retryAfter});
  final bool alreadyVerified;
  final int retryAfter;
}

abstract interface class EmailVerifier {
  Future<VerificationRequestResult> requestCode(
      {required String email, required String password});
  Future<void> confirmCode(
      {required String email, required String password, required String code});
}
