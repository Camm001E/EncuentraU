abstract final class AppValidation {
  static const int minimumFullNameLength = 3;
  static const int minimumStudentCodeLength = 3;
  static const int minimumPasswordLength = 6;

  static final RegExp _emailPattern = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );

  static bool isValidEmail(String email) {
    return _emailPattern.hasMatch(email.trim());
  }
}
