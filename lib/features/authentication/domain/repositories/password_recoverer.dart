abstract interface class PasswordRecoverer {
  Future<int> requestPasswordRecovery({required String email});
  Future<void> confirmPasswordRecovery(
      {required String email, required String code, required String password});
}
