import 'app_user_model.dart';

class AuthSessionModel {
  const AuthSessionModel({required this.accessToken, required this.user});
  final String accessToken;
  final AppUserModel user;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'access_token': String token,
          'token_type': 'bearer',
          'expires_in': int expiresIn,
          'user': Map<String, dynamic> user,
        } when token.trim().isNotEmpty && expiresIn > 0) {
      return AuthSessionModel(
          accessToken: token, user: AppUserModel.fromJson(user));
    }
    throw const FormatException();
  }
}
