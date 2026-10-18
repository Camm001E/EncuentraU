import 'app_validation.dart';

abstract final class AppStrings {
  static const reportPhoto = 'Fotografía del reporte';
  static const noReportPhoto = 'Sin fotografía';
  static const photoUnavailable = 'No fue posible cargar la fotografía.';
  static const uploadingPhoto = 'Subiendo fotografía...';
  static const retryPhotoUpload = 'Reintentar subir fotografía';
  static const replaceReportPhoto = 'Subir o reemplazar fotografía';
  static const deleteReportPhoto = 'Eliminar fotografía';
  static const deletePhotoConfirmation =
      '¿Quieres eliminar la fotografía de este reporte?';
  static const photoSaved = 'Fotografía guardada correctamente.';
  static const photoDeleted = 'Fotografía eliminada.';
  static const reportSavedPhotoFailed =
      'Reporte guardado, pero no fue posible subir la fotografía. Puedes reintentar sin duplicarlo.';
  static const reportPhotoTooLarge =
      'La fotografía debe pesar como máximo 8 MB.';
  static const reportPhotoUnsupported =
      'Usa una fotografía JPEG, PNG o WebP válida.';
  static const String appName = 'EncuentraU';

  // Inicio de sesión
  static const String signIn = 'Iniciar sesión';
  static const String loginSubtitle =
      'Objetos perdidos, conexiones encontradas.';

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
  static const String accountAlreadyRegistered =
      'El correo o el código estudiantil ya está registrado.';

  static const String accountCreated =
      'Cuenta creada correctamente. Ahora inicia sesión.';
  static const String signingIn = 'Iniciando sesión...';
  static const String restoringSession = 'Restaurando tu sesión...';
  static const String signingOut = 'Cerrando sesión...';
  static const String signOut = 'Cerrar sesión';
  static const String invalidCredentials = 'Correo o contraseña incorrectos.';
  static const String sessionExpired =
      'Tu sesión venció. Inicia sesión nuevamente.';
  static const String inactiveAccount = 'Tu cuenta está inactiva.';
  static const String invalidAuthData =
      'Revisa los datos ingresados e inténtalo nuevamente.';
  static const String authServerError =
      'El servidor tiene un problema temporal. Inténtalo nuevamente.';
  static const String authConnectionError =
      'No fue posible conectar con el servidor. Inténtalo nuevamente.';
  static const String invalidAuthResponse =
      'No fue posible completar la autenticación. Inténtalo nuevamente.';
  static const String secureStorageError =
      'No fue posible actualizar el acceso guardado. Inténtalo nuevamente.';
  static const String fieldTooLong = 'El valor ingresado es demasiado largo.';

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

  static const String savingReport = 'Guardando reporte...';
  static const String registerReport = 'Registrar reporte';
  static const String processCompleted = 'Proceso terminado.';
  static const String unidentifiedBrand = 'Sin identificar';
  static const String imageAnalysisBadge = 'Analizado con Gemini';

  // Reportes y coincidencias persistentes
  static const appVersion = '0.2.0';
  static const myReports = 'Mis reportes';
  static const matchesTitle = 'Coincidencias';
  static const reportDetail = 'Detalle del reporte';
  static const matchDetail = 'Detalle de la coincidencia';
  static const editReport = 'Editar reporte';
  static const cancelReport = 'Cancelar reporte';
  static const cancelConfirmation =
      '¿Quieres cancelar este reporte? Se conservará su historial.';
  static const confirm = 'Confirmar';
  static const dismiss = 'Volver';
  static const saveChanges = 'Guardar cambios';
  static const reportSaved = 'Reporte guardado correctamente.';
  static const reportUpdated = 'Reporte actualizado correctamente.';
  static const reportCancelled = 'Reporte cancelado correctamente.';
  static const reportSavedMatchesFailed =
      'Reporte guardado, pero no fue posible actualizar las coincidencias';
  static const searchMatches = 'Buscar coincidencias';
  static const generatingMatches = 'Buscando coincidencias...';
  static const noReports = 'Todavía no tienes reportes en este filtro.';
  static const noMatches = 'No hay coincidencias en este filtro.';
  static const matchesHelp =
      'Busca coincidencias desde el detalle de un reporte activo.';
  static const retry = 'Reintentar';
  static const refresh = 'Actualizar';
  static const loadMore = 'Cargar más';
  static const all = 'Todos';
  static const lost = 'Perdido';
  static const found = 'Encontrado';
  static const active = 'Activo';
  static const resolved = 'Resuelto';
  static const cancelled = 'Cancelado';
  static const pending = 'Pendiente';
  static const accepted = 'Aceptada';
  static const rejected = 'Rechazada';
  static const highMatch = 'Coincidencia alta';
  static const possibleMatch = 'Coincidencia posible';
  static const lowMatch = 'Coincidencia baja';
  static const identity = 'Identidad';
  static const context = 'Contexto';
  static const evidenceCoverage = 'Cobertura de evidencia';
  static const evidenceFactors = 'Factores de coincidencia';
  static const warnings = 'Observaciones';
  static const myReport = 'Mi reporte';
  static const candidateReport = 'Reporte candidato';
  static const matchingFactor = 'Coincide';
  static const partialFactor = 'Parcial';
  static const differentFactor = 'Diferente';
  static const unknownFactor = 'No evaluado';
  static const compatible = 'Tipos compatibles';
  static const incompatible = 'Tipos incompatibles';
  static const categoryLabel = 'Categoría';
  static const categoryHelp =
      'Ejemplo: electronica, llaves, documentos, bolsos';
  static const secondaryColorsLabel =
      'Colores secundarios (separados por comas)';
  static const shapeLabel = 'Forma (opcional)';
  static const statusLabel = 'Estado';
  static const levelLabel = 'Nivel';
  static const locationLabel = 'Ubicación';
  static const notAvailable = 'Sin información';
  static const createdAtLabel = 'Creado';
  static const updatedAtLabel = 'Actualizado';
  static const reportReadOnly =
      'Este reporte ya no está activo. Su historial permanece disponible.';
  static const apiInvalidData = 'Revisa los campos y la fecha del reporte.';
  static const apiNotFound = 'No se encontró el recurso solicitado.';
  static const apiConflict =
      'El reporte cambió o ya no está activo. Actualiza sus datos.';
  static const apiTimeout = 'La solicitud tardó demasiado. Intenta nuevamente.';
  static const apiInvalidResponse =
      'No fue posible interpretar la respuesta del servidor.';
  static const welcome = 'Hola, estudiante';
  static const welcomeDescription =
      'Reporta, compara y recupera objetos dentro de la universidad.';
  static const lostAction = 'Perdí un objeto';
  static const foundAction = 'Encontré un objeto';
  static const lostActionDescription =
      'Registra sus características y ubicación.';
  static const foundActionDescription =
      'Ayuda a que regrese con su propietario.';
  static const viewReports = 'Ver reportes';
  static const viewAll = 'Ver todos';
  static const invalidDate = 'La fecha no puede ser futura.';
  static const defaultCategory = 'electronica';
  static String generatedCount(int count) =>
      '$count coincidencias para este reporte.';
  static String resultCount(int count) => '$count resultados';
  static String percentage(num value) => '$value%';
  static String factorPoints(num score, num maximum) => '$score / $maximum';
}
