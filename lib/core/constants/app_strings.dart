import 'app_validation.dart';

abstract final class AppStrings {
  static const deliveries = 'Entregas';
  static const myDeliveries = 'Mis entregas';
  static const deliveryProcess = 'Proceso de entrega';
  static const coordinatingDelivery = 'Coordinando entrega';
  static const awaitingConfirmations = 'Esperando confirmaciones';
  static const awaitingAdmin = 'Esperando validación';
  static const deliveryDisputed = 'En disputa';
  static const deliveryCompleted = 'Caso cerrado';
  static const deliveryClosedMessage = 'Objeto entregado y caso cerrado';
  static const deliveryClosedHelp =
      'La entrega fue validada. Los reportes están resueltos y el chat conserva su historial en modo lectura.';
  static const confirmCustodianDelivery = 'Confirmar que entregué el objeto';
  static const confirmClaimantDelivery = 'Confirmar que recibí el objeto';
  static const confirmPhysicalDelivery =
      'Confirma únicamente después del intercambio físico. Esta acción registra tu confirmación; la otra persona y un administrador también deben validar la entrega.';
  static const myDeliveryConfirmation = 'Tu confirmación está registrada';
  static const otherDeliveryConfirmation = 'La otra persona ya confirmó';
  static const waitingOtherConfirmation =
      'Falta la confirmación de la otra persona';
  static const custodianConfirmed = 'Custodio confirmó entrega';
  static const claimantConfirmed = 'Reclamante confirmó recepción';
  static const reportDeliveryProblem = 'Reportar un problema';
  static const disputeReason = 'Motivo del problema';
  static const disputeHelp =
      'Explica qué ocurrió con la entrega. No incluyas contraseñas, información bancaria ni datos personales innecesarios. El administrador revisará el caso; el chat seguirá disponible.';
  static const disputeValidation = 'Escribe un motivo de 10 a 2000 caracteres.';
  static const deliveryHistory = 'Historial de la entrega';
  static const deliveryCreated = 'Entrega habilitada';
  static const deliveryReopened = 'Administrador devolvió a coordinación';
  static const deliveryAdminCompleted = 'Administrador validó la entrega';
  static const completeDelivery = 'Validar entrega';
  static const completeDeliveryHelp =
      'Se resolverán ambos reportes y se cerrará el chat. El historial permanecerá disponible para sus participantes.';
  static const reopenDelivery = 'Devolver a coordinación';
  static const reopenDeliveryHelp =
      'Las confirmaciones actuales se reiniciarán para coordinar un nuevo intercambio. El historial anterior se conservará.';
  static const deliveryAdminNote = 'Nota administrativa';
  static const deliveryNoteHelp =
      'Esta nota solo será visible para administradores.';
  static const deliveryNoteValidation =
      'Escribe una nota de 1 a 2000 caracteres.';
  static const noDeliveries = 'Todavía no hay entregas';
  static const noDeliveriesHelp =
      'Las reclamaciones aprobadas habilitan el proceso de entrega y su chat privado.';
  static const deliveryDetails = 'Ver proceso de entrega';
  static const deliveryCasesInProgress = 'Casos en proceso';
  static const deliveryCasesCompleted = 'Casos completados';
  static const chatReadOnly = 'Chat en modo lectura';
  static const chatMetadataOnly =
      'Privacidad del chat: solo se muestran cantidad de mensajes y última actividad. Su contenido pertenece a los participantes.';
  static const evidenceProtected =
      'Evidencia protegida: este reporte y su fotografía no pueden cambiar mientras exista una reclamación pendiente o aprobada.';
  static const reportResolvedByDelivery =
      'Este reporte está resuelto. Si terminó mediante una entrega validada, puedes consultar el cierre y el historial en Mis entregas.';
  static String confirmationCount(int count) => '$count de 2 confirmaciones';
  static String deliveryMessageCount(int count) =>
      count == 1 ? '1 mensaje conservado' : '$count mensajes conservados';
  static String deliveryMetric(String label, int count) => '$label: $count';
  static String deliveryEventWhen(String date, String time) => '$date · $time';
  // Ownership review and approved private conversations.
  static const permissionDenied =
      'No tienes permiso para realizar esta acción.';
  static const workflowConflict =
      'El estado cambió o esta acción ya fue realizada. Actualiza la información.';
  static const myClaims = 'Mis reclamaciones';
  static const claimsSubtitle =
      'Sigue la revisión de los objetos que conectan tus reportes.';
  static const claimThisObject = 'Reclamar este objeto';
  static const claimFormTitle = 'Cuéntanos qué lo hace tuyo';
  static const claimFormHelp =
      'Un administrador comparará tu respuesta con las características privadas de ambos reportes. La coincidencia no acredita la propiedad por sí sola.';
  static const ownershipEvidenceLabel = 'Característica privada que reconoces';
  static const ownershipEvidenceHelp =
      'Describe una señal, marca o detalle que permita identificar tu objeto.';
  static const sensitiveDataWarning =
      'No escribas contraseñas, datos bancarios ni información personal innecesaria.';
  static const evidenceValidation = 'Escribe entre 10 y 4000 caracteres.';
  static const submitClaim = 'Enviar reclamación';
  static const submitClaimConfirmation =
      '¿Quieres enviar esta respuesta para revisión? No podrá modificarse después.';
  static const claimSent = 'Reclamación enviada para revisión.';
  static const claimDetailTitle = 'Seguimiento de la reclamación';
  static const claimPending = 'Pendiente de revisión';
  static const claimApproved = 'Reclamación aprobada';
  static const claimRejected = 'Reclamación rechazada';
  static const pendingClaimHelp =
      'La administración revisará las fotografías y las características privadas. El chat permanece bloqueado hasta la aprobación.';
  static const custodianPending = 'Existe una reclamación en revisión';
  static const custodianPrivacy =
      'La respuesta privada se reserva para su propietario y la administración.';
  static const yourOwnershipEvidence = 'Tu respuesta privada';
  static const rejectionReasonLabel = 'Motivo de rechazo';
  static const claimReviewed = 'Revisada';
  static const claimCreated = 'Reclamación enviada';
  static const chatEnabled = 'Chat privado habilitado';
  static const chatEnabledHelp =
      'La revisión fue aprobada. Ya pueden coordinarse mediante una conversación privada.';
  static const chatRejectedHelp =
      'Esta reclamación no habilita una conversación.';
  static const openClaim = 'Ver reclamación';
  static const openChat = 'Abrir conversación';
  static const noClaims = 'Todavía no hay reclamaciones en este filtro.';
  static const claimantLabel = 'Tu objeto perdido';
  static const custodianLabel = 'Objeto que custodias';
  static const claimStatusFilter = 'Estado de la reclamación';
  static const workflowCancel = 'Volver';
  static const reviewQueue = 'Reclamaciones';
  static const adminHome = 'Resumen';
  static const adminDashboardTitle = 'Revisar para reencontrar';
  static const adminDashboardHelp =
      'Compara la evidencia privada y autoriza una conexión segura entre estudiantes.';
  static const pendingClaims = 'Pendientes';
  static const approvedClaims = 'Aprobadas';
  static const rejectedClaims = 'Rechazadas';
  static const reviewClaim = 'Revisar reclamación';
  static const adminClaimDetail = 'Revisión de propiedad';
  static const adminPrivateEvidence = 'Evidencia reservada para administración';
  static const claimantAnswer = 'Respuesta del reclamante';
  static const lostPrivateFeature = 'Característica privada · reporte perdido';
  static const foundPrivateFeature =
      'Característica privada · reporte encontrado';
  static const adminNote = 'Nota administrativa (opcional)';
  static const internalNoteHelp =
      'La nota es interna. El motivo de rechazo será visible para ambos participantes; evita revelar características privadas ajenas.';
  static const approveClaim = 'Aprobar reclamación';
  static const rejectClaim = 'Rechazar reclamación';
  static const approveClaimConfirmation =
      'La coincidencia será aceptada y se creará una conversación privada para los dos participantes.';
  static const rejectClaimConfirmation =
      'La coincidencia será rechazada y no se creará una conversación.';
  static const reviewReasonValidation =
      'Explica el motivo con entre 3 y 2000 caracteres.';
  static const noteValidation = 'Usa como máximo 2000 caracteres.';
  static const approvalCompleted =
      'Reclamación aprobada. Conversación creada para sus participantes.';
  static const rejectionCompleted =
      'Reclamación rechazada con el motivo indicado.';
  static const reviewFinal = 'La decisión ya es definitiva.';
  static const adminChatPrivacy =
      'La conversación está reservada para los dos participantes. La administración no tiene acceso a sus mensajes.';
  static const noPrivateFeature = 'No se registró una característica privada.';
  static const messages = 'Mensajes';
  static const conversationsTitle = 'Tus conversaciones';
  static const conversationsHelp =
      'Conexiones privadas habilitadas después de una revisión aprobada.';
  static const noConversations = 'Aún no tienes conversaciones aprobadas.';
  static const noMessages =
      'Todavía no hay mensajes. Puedes iniciar la conversación.';
  static const noLastMessage = 'Conversación lista para comenzar';
  static const privateChat = 'Conversación privada';
  static const approvedChat = 'Reclamación aprobada';
  static const chatPrivacyHelp =
      'Solo los dos participantes pueden leer esta conversación. Evita compartir información sensible innecesaria.';
  static const writeMessage = 'Escribe un mensaje';
  static const sendMessage = 'Enviar mensaje';
  static const sendingMessage = 'Enviando mensaje';
  static const retryMessage = 'Reintentar envío';
  static const messageValidation =
      'Escribe un mensaje de entre 1 y 2000 caracteres.';
  static const previousMessages = 'Cargar mensajes anteriores';
  static const yourMessage = 'Tú';
  static const conversationClosed = 'Conversación cerrada';
  static const conversationsUpdating = 'Actualizando conversación';
  static String unreadMessages(int count) => '$count mensajes sin leer';
  static String messageSemantics(String author, String time, String body) =>
      '$author, $time. $body';
  static String claimDate(String date) => 'Enviada el $date';
  static String privateEvidenceSemantics(String label, String value) =>
      '$label. $value';
  static const navHome = 'Inicio';
  static const navProfile = 'Perfil';
  static const brandEyebrow = 'CONECTAMOS LO QUE IMPORTA';
  static const authHeadline =
      'Cada objeto tiene una historia.\nAyudemos a que continúe.';
  static const authDescription =
      'Un punto de encuentro para lo que perdiste y una oportunidad de ayudar con lo que encontraste.';
  static const authTrust = 'Tu comunidad. Tus datos protegidos.';
  static const loginHeading = 'Qué bueno verte de nuevo';
  static const loginHelp = 'Inicia sesión para continuar tu búsqueda.';
  static const homeHeadline = 'Lo importante encuentra su camino.';
  static const homeEyebrow = 'TU PUNTO DE ENCUENTRO';
  static const summaryTitle = 'Tu actividad, de un vistazo';
  static const activeReports = 'Reportes activos';
  static const lostReports = 'Objetos perdidos';
  static const foundReports = 'Objetos encontrados';
  static const availableMatches = 'Coincidencias disponibles';
  static const recentReports = 'Tus últimos reportes';
  static const profileTitle = 'Tu espacio en EncuentraU';
  static const profileDescription =
      'Esta información pertenece a tu cuenta universitaria.';
  static const roleLabel = 'Rol';
  static const studentRole = 'Estudiante';
  static const adminRole = 'Administrador';
  static const accountActive = 'Cuenta activa';
  static const accountInactive = 'Cuenta inactiva';
  static const emptyTitle = 'Un nuevo comienzo';
  static const errorTitle = 'Vamos a intentarlo otra vez';
  static const loadingContent = 'Cargando información';
  static const reportCollectionSubtitle =
      'Cada detalle acerca un objeto a su historia.';
  static const reportCollectionHeadline = 'El recorrido de tus objetos';
  static const matchListHeadline = 'Explora tus coincidencias';
  static const highShort = 'Alta';
  static const possibleShort = 'Posible';
  static const lowShort = 'Baja';
  static const matchListSubtitle =
      'Explora la evidencia que conecta tus reportes.';
  static const estimatedCompatibility = 'Compatibilidad estimada';
  static const ownershipNotice =
      'Esta puntuación compara la evidencia disponible. La propiedad debe validarse antes de entregar el objeto.';
  static const identityEvidence = 'Identidad del objeto';
  static const contextEvidence = 'Contexto del hallazgo';
  static const pointsLegend = 'Puntos obtenidos / máximo evaluable';
  static const warningHelp =
      'Detalles que conviene revisar al comparar los objetos.';
  static const comparisonTitle = 'Dos miradas, una posible conexión';
  static const comparisonEyebrow = 'COMPARACIÓN DE EVIDENCIAS';
  static const candidatePhotoLabel = 'Posible coincidencia';
  static const compareConnector = 'Comparación entre ambos reportes';
  static const openMatch = 'Explorar coincidencia';
  static const photoStep = 'Fotografía';
  static const analysisStep = 'Análisis de IA';
  static const objectStep = 'Información del objeto';
  static const locationStep = 'Lugar y fecha';
  static const privateStep = 'Solo para ti';
  static const reviewStep = 'Revisión y publicación';
  static const privateHelp =
      'Este detalle es privado. No se muestra a otras personas en las coincidencias.';
  static const photoStepHelp =
      'Una imagen clara ayuda a comparar los detalles del objeto.';
  static const analysisStepHelp =
      'La IA sugiere características. Tú decides qué información conservar o corregir.';
  static const reviewHelp =
      'Revisa tus datos. Guardaremos el reporte y la fotografía antes de buscar coincidencias.';
  static const photoReady = 'Fotografía seleccionada';
  static const filterType = 'Tipo de reporte';
  static const filterStatus = 'Estado del reporte';
  static String greeting(String name) =>
      'Hola, ${name.trim().split(RegExp(r"\s+")).first}';
  static String scoreSemantics(int percentage) =>
      '$estimatedCompatibility: $percentage por ciento';
  static String photoSemantics(String label) => 'Fotografía: $label';
  static String stepLabel(int step, String title) => '$step. $title';
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
      'No fue posible conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.';

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
  static const unknownFactor = 'Sin información';
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
  static String resultCount(int count) =>
      count == 1 ? '1 resultado' : '$count resultados';
  static String percentage(num value) => '$value%';
  static String factorPoints(num score, num maximum) => '$score / $maximum';
}
