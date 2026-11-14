enum UserRole { student, admin }

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.studentCode,
    required this.role,
    required this.isActive,
    this.emailVerified = false,
    this.emailVerificationRequired = false,
  });

  final String id;
  final String fullName;
  final String email;
  final String studentCode;
  final UserRole role;
  final bool isActive;
  final bool emailVerified;
  final bool emailVerificationRequired;
}
