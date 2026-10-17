enum UserRole { student, admin }

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.studentCode,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String fullName;
  final String email;
  final String studentCode;
  final UserRole role;
  final bool isActive;
}
