import 'app_validation.dart';

abstract final class AppStrings {
  static const String appName = 'EncuentraU';

  // Inicio de sesión
  static const String signIn = 'Iniciar sesión';
  static const String loginSubtitle =
      'Objetos perdidos, conexiones encontradas.';
  static const String simulatedAccessMessage =
      'Acceso simulado: utiliza cualquier correo válido y una contraseña de '
      'mínimo ${AppValidation.minimumPasswordLength} caracteres.';
  static const String dontHaveAccount = '¿No tienes una cuenta?';
  static const String showPassword = 'Mostrar contraseña';
  static const String hidePassword = 'Ocultar contraseña';

  // Registro
  static const String registrationTitle = 'Crear cuenta';
  static const String registrationSubtitle =
      'Regístrate para publicar objetos y consultar coincidencias.';
  static const String fullNameLabel = 'Nombre completo';
  static const String emailLabel = 'Correo institucional';
  static const String studentCodeLabel = 'Código estudiantil';
  static const String passwordLabel = 'Contraseña';
  static const String confirmPasswordLabel = 'Confirmar contraseña';
  static const String registerButton = 'Registrarme';
  static const String alreadyHaveAccount = '¿Ya tienes una cuenta?';

  // Validaciones
  static const String requiredField = 'Este campo es obligatorio.';

  static const String invalidFullName = 'Ingresa un nombre de mínimo '
      '${AppValidation.minimumFullNameLength} caracteres.';

  static const String invalidEmail = 'Ingresa un correo electrónico válido.';

  static const String invalidStudentCode =
      'Ingresa un código estudiantil válido.';

  static const String passwordMinLength = 'La contraseña debe tener mínimo '
      '${AppValidation.minimumPasswordLength} caracteres.';

  static const String passwordsDoNotMatch = 'Las contraseñas no coinciden.';

  // Resultados
  static const String emailAlreadyRegistered =
      'Ya existe una cuenta registrada con este correo.';

  static const String accountCreated = 'Cuenta creada correctamente.';

  static const String unexpectedError =
      'Ocurrió un error inesperado. Inténtalo nuevamente.';
}
