import '../features/objects/domain/repositories/object_analysis_repository.dart';
import '../features/objects/data/datasources/report_image_remote_data_source.dart';
import '../features/objects/data/repositories/report_image_repository_impl.dart';
import '../features/objects/domain/usecases/report_images.dart';
import '../features/objects/presentation/controllers/report_image_controller.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/errors/api_exception.dart';
import '../core/network/authenticated_api_client.dart';
import '../core/session/session_manager.dart';
import '../core/storage/token_storage.dart';
import '../features/authentication/data/datasources/auth_remote_data_source.dart';
import '../features/authentication/data/datasources/secure_token_storage.dart';
import '../features/authentication/data/repositories/auth_repository_impl.dart';
import '../features/authentication/domain/repositories/auth_repository.dart';
import '../features/authentication/domain/usecases/login_user.dart';
import '../features/authentication/domain/usecases/logout_user.dart';
import '../features/authentication/domain/usecases/register_user.dart';
import '../features/authentication/domain/usecases/restore_session.dart';
import '../features/authentication/presentation/controllers/auth_controller.dart';
import '../features/objects/data/datasources/object_analysis_remote_datasource.dart';
import '../features/objects/data/datasources/object_report_remote_data_source.dart';
import '../features/objects/data/repositories/object_analysis_repository_impl.dart';
import '../features/objects/data/repositories/object_repository_impl.dart';
import '../features/objects/domain/usecases/analyze_object_image.dart';
import '../features/objects/domain/usecases/get_my_reports.dart';
import '../features/objects/domain/usecases/get_my_report.dart';
import '../features/objects/domain/usecases/register_object.dart';
import '../features/objects/domain/usecases/update_object_report.dart';
import '../features/objects/domain/usecases/cancel_object_report.dart';
import '../features/objects/presentation/controllers/object_analysis_controller.dart';
import '../features/objects/presentation/controllers/object_controller.dart';
import '../features/matching/data/datasources/match_remote_data_source.dart';
import '../features/matching/data/repositories/match_repository_impl.dart';
import '../features/matching/domain/usecases/generate_report_matches.dart';
import '../features/matching/domain/usecases/get_my_matches.dart';
import '../features/matching/domain/usecases/get_my_match.dart';
import '../features/matching/presentation/controllers/match_controller.dart';

class DependencyContainer {
  DependencyContainer._(
      {required this.objectController,
      required this.reportImageController,
      required this.matchController,
      required this.authController,
      required this.objectAnalysisController,
      required this.session,
      http.Client? ownedClient})
      : _ownedClient = ownedClient {
    _authListener = () {
      final userId = authController.currentUser?.id;
      if (userId != _userId) {
        _userId = userId;
        session.changeSession(active: userId != null);
        objectController.clear();
        matchController.clear();
        objectAnalysisController.reset();
        reportImageController.clear();
        if (userId != null) reportImageController.activate();
      }
    };
    authController.addListener(_authListener);
    _expiry = session.expired.listen((reason) =>
        authController.expireSession(inactive: reason == ApiFailure.forbidden));
  }
  final ObjectController objectController;
  final ReportImageController reportImageController;
  final MatchController matchController;
  final AuthController authController;
  final ObjectAnalysisController objectAnalysisController;
  final SessionManager session;
  final http.Client? _ownedClient;
  late final void Function() _authListener;
  late final StreamSubscription<ApiFailure> _expiry;
  String? _userId;
  static DependencyContainer create(
      {http.Client? client,
      TokenStorage? tokenStorage,
      AuthRepository? authRepository,
      ObjectAnalysisRepository? analysisRepository}) {
    final sharedClient = client ?? http.Client();
    final session = SessionManager(tokenStorage ?? const SecureTokenStorage(),
        active: false);
    final api = AuthenticatedApiClient(client: sharedClient, session: session);
    final objects = ObjectRepositoryImpl(ObjectReportRemoteDataSource(api));
    final imageRepository =
        ReportImageRepositoryImpl(ReportImageRemoteDataSource(api));
    final matches = MatchRepositoryImpl(MatchRemoteDataSource(api));
    final authentication = authRepository ??
        AuthRepositoryImpl(AuthRemoteDataSource(client: sharedClient), session);
    return DependencyContainer._(
        ownedClient: client == null ? sharedClient : null,
        session: session,
        reportImageController: ReportImageController(
            upload: UploadReportImage(imageRepository),
            metadata: GetReportImage(imageRepository),
            download: DownloadReportImage(imageRepository),
            delete: DeleteReportImage(imageRepository)),
        objectController: ObjectController(
            getMyReports: GetMyReports(objects),
            getMyReport: GetMyReport(objects),
            registerObject: RegisterObject(objects),
            updateReport: UpdateObjectReport(objects),
            cancelReport: CancelObjectReport(objects)),
        matchController: MatchController(
            generateReportMatches: GenerateReportMatches(matches),
            getMyMatches: GetMyMatches(matches),
            getMyMatch: GetMyMatch(matches)),
        authController: AuthController(
            registerUser: RegisterUser(authentication),
            loginUser: LoginUser(authentication),
            restoreSession: RestoreSession(authentication),
            logoutUser: LogoutUser(authentication)),
        objectAnalysisController: ObjectAnalysisController(AnalyzeObjectImage(
            analysisRepository ??
                ObjectAnalysisRepositoryImpl(
                    ObjectAnalysisRemoteDataSource(client: sharedClient)))));
  }

  void dispose() {
    authController.removeListener(_authListener);
    unawaited(_expiry.cancel());
    unawaited(session.dispose());
    authController.dispose();
    objectController.dispose();
    matchController.dispose();
    objectAnalysisController.dispose();
    reportImageController.dispose();
    _ownedClient?.close();
  }
}
