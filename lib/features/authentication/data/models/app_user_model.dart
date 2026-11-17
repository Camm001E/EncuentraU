import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.studentCode,
    required super.role,
    required super.isActive,
    super.emailVerified,
    super.emailVerificationRequired,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'id': String id,
          'full_name': String fullName,
          'email': String email,
          'student_code': String studentCode,
          'role': String role,
          'is_active': bool isActive,
        }) {
      final parsedRole = switch (role) {
        'student' => UserRole.student,
        'admin' => UserRole.admin,
        _ => throw const FormatException(),
      };
      if ([id, fullName, email, studentCode]
          .any((value) => value.trim().isEmpty)) {
        throw const FormatException();
      }
      return AppUserModel(
        id: id,
        fullName: fullName,
        email: email,
        studentCode: studentCode,
        role: parsedRole,
        isActive: isActive,
        emailVerified: json['email_verified'] == true,
        emailVerificationRequired: json['email_verification_required'] == true,
      );
    }
    throw const FormatException();
  }
}
