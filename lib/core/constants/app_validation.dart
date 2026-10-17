abstract final class AppValidation {
  static const int minimumFullNameLength = 1;
  static const int minimumStudentCodeLength = 1;
  static const int minimumPasswordLength = 8;
  static const int maximumFullNameLength = 200;
  static const int maximumEmailLength = 254;
  static const int maximumStudentCodeLength = 50;
  static const int maximumPasswordLength = 128;

  static final RegExp _studentCodePattern = RegExp(r'^[A-Z0-9][A-Z0-9._-]*$');

  static bool isValidStudentCode(String code) =>
      _studentCodePattern.hasMatch(code.trim().toUpperCase());

  static final RegExp _emailPattern = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );

  static bool isValidEmail(String email) {
    return _emailPattern.hasMatch(email.trim());
  }
}
