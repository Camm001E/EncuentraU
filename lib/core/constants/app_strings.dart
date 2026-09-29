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

  // Análisis de imágenes
  static const String addPhoto = 'Agrega una fotografía';
  static const String changePhoto = 'Cambiar fotografía';
  static const String selectPhoto = 'Seleccionar fotografía';
  static const String selectedPhoto = 'Fotografía seleccionada';

  static const String photoHelp =
      'Usa una imagen clara donde el objeto sea el elemento principal.';

  static const String analyzeWithAi = 'Analizar con IA';
  static const String analyzingImage = 'Analizando fotografía...';
  static const String analysisCompleted = 'Análisis de IA completado';

  static const String analysisCompletedMessage =
      'Revisa y corrige los datos antes de registrar el reporte.';

  static const String analysisUnavailable =
      'No se pudo analizar la fotografía. Puedes intentarlo nuevamente o '
      'completar el formulario manualmente.';

  static const String selectImageFirst =
      'Selecciona una fotografía antes de analizar.';

  static const String writeDescriptionFirst =
      'Escribe una descripción breve antes de analizar la fotografía.';

  static const String unsupportedImage =
      'Elige una fotografía JPEG, PNG o WEBP.';

  static const String imageTooLarge =
      'La fotografía supera el límite de 10 MB.';

  static const String imagePickerError =
      'No fue posible abrir la fotografía seleccionada.';

  static const String networkError =
      'No fue posible conectar con el servidor. Verifica que FastAPI esté '
      'encendido.';

  static const String analysisTimeout =
      'El análisis tardó demasiado. Intenta nuevamente.';

  static const String invalidAnalysisResponse =
      'El servidor devolvió un análisis que no se pudo interpretar.';

  static const String noObjectDetected =
      'No se detectó un objeto principal. Puedes cambiar la fotografía o '
      'completar los datos manualmente.';

  static const String anotherPhotoRecommended =
      'Gemini recomienda utilizar otra fotografía más clara.';

  static const String visibleFeatures = 'Características visibles';
  static const String visibleText = 'Texto visible';
  static const String detectedObject = 'Objeto detectado';
  static const String detectedShape = 'Forma';
  static const String detectedBrand = 'Marca detectada';
  static const String imageQuality = 'Calidad de imagen';
  static const String confidence = 'Confianza';
  static const String aiSuggestion = 'Sugerencia de IA';

  // Formulario de objetos
  static const String reportLostTitle = 'Reportar objeto perdido';
  static const String reportFoundTitle = 'Reportar objeto encontrado';

  static const String lostFormIntro =
      'Describe el objeto con el mayor detalle posible.';

  static const String foundFormIntro =
      'Registra el objeto sin revelar públicamente sus detalles privados.';

  static const String objectTypeLabel = 'Tipo de objeto';
  static const String primaryColorLabel = 'Color principal';
  static const String optionalBrandLabel = 'Marca (opcional)';
  static const String descriptionLabel = 'Descripción';

  static const String descriptionHint =
      'Ejemplo: audífonos negros con estuche ovalado';

  static const String lostLocationLabel = 'Lugar aproximado donde se perdió';

  static const String foundLocationLabel = 'Lugar donde se encontró';

  static const String eventDateLabel = 'Fecha del suceso';
  static const String privateFeatureLabel = 'Característica privada';

  static const String lostPrivateFeatureHint =
      'Algo que solo el propietario conozca';

  static const String foundPrivateFeatureHint =
      'Detalle que no se publicará abiertamente';

  static const String savingReport = 'Guardando simulación...';
  static const String registerReport = 'Registrar reporte';
  static const String processCompleted = 'Proceso terminado.';
  static const String unidentifiedBrand = 'Sin identificar';
  static const String imageAnalysisBadge = 'Analizado con Gemini';
}
