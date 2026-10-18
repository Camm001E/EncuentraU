import '../features/objects/domain/repositories/object_analysis_repository.dart';
import '../features/deliveries/data/datasources/delivery_remote_data_source.dart';
import '../features/deliveries/data/repositories/delivery_repository_impl.dart';
import '../features/deliveries/domain/repositories/delivery_repository.dart';
import '../features/deliveries/domain/usecases/deliveries.dart';
import '../features/deliveries/presentation/controllers/delivery_controller.dart';
import '../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../features/dashboard/domain/usecases/get_dashboard_summary.dart';
import '../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../features/dashboard/presentation/controllers/dashboard_controller.dart';
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
import '../features/claims/data/datasources/claim_remote_data_source.dart';
import '../features/claims/data/repositories/claim_repository_impl.dart';
import '../features/claims/domain/repositories/claim_repository.dart';
import '../features/claims/domain/usecases/claims.dart';
import '../features/claims/presentation/controllers/claims_controller.dart';
import '../features/claims/presentation/controllers/admin_claims_controller.dart';
import '../features/messaging/data/datasources/conversation_remote_data_source.dart';
import '../features/messaging/data/repositories/conversation_repository_impl.dart';
import '../features/messaging/domain/repositories/conversation_repository.dart';
import '../features/messaging/domain/usecases/conversations.dart';
import '../features/messaging/presentation/controllers/conversations_controller.dart';
import '../features/messaging/presentation/controllers/chat_controller.dart';

class DependencyContainer {
  DependencyContainer._(
      {required this.objectController,
      required this.deliveryController,
      required this.adminDeliveryController,
      required this.dashboardController,
      required this.reportImageController,
      required this.matchController,
      required this.authController,
      required this.objectAnalysisController,
      required this.session,
      required this.claimsController,
      required this.adminClaimsController,
      required this.adminSummaryController,
      required this.conversationsController,
      required ChatController Function() chatFactory,
      http.Client? ownedClient})
      : _ownedClient = ownedClient,
        _chatFactory = chatFactory {
    _authListener = () {
      final user = authController.currentUser;
      final userId = user == null ? null : '${user.id}:${user.role.name}';
      if (userId != _userId) {
        _userId = userId;
        session.changeSession(active: userId != null);
        objectController.clear();
        dashboardController.clear();
        matchController.clear();
        objectAnalysisController.reset();
        reportImageController.clear();
        claimsController.clear();
        adminClaimsController.clear();
        adminSummaryController.clear();
        conversationsController.clear();
        deliveryController.clear();
        adminDeliveryController.clear();
        for (final chat in _chats) {
          chat.clear();
        }
        if (userId != null) reportImageController.activate();
      }
    };
    authController.addListener(_authListener);
    _expiry = session.expired.listen((reason) =>
        authController.expireSession(inactive: reason == ApiFailure.forbidden));
  }
  final ObjectController objectController;
  final DeliveryController deliveryController, adminDeliveryController;
  final DashboardController dashboardController;
  final ReportImageController reportImageController;
  final MatchController matchController;
  final AuthController authController;
  final ObjectAnalysisController objectAnalysisController;
  final SessionManager session;
  final ClaimsController claimsController;
  final AdminClaimsController adminClaimsController;
  final AdminSummaryController adminSummaryController;
  final ConversationsController conversationsController;
  final ChatController Function() _chatFactory;
  final _chats = <ChatController>{};
  ChatController createChatController() {
    final controller = _chatFactory();
    _chats.add(controller);
    return controller;
  }

  void releaseChatController(ChatController controller) {
    if (_chats.remove(controller)) controller.dispose();
  }

  final http.Client? _ownedClient;
  late final void Function() _authListener;
  late final StreamSubscription<ApiFailure> _expiry;
  String? _userId;
  static DependencyContainer create(
      {http.Client? client,
      TokenStorage? tokenStorage,
      AuthRepository? authRepository,
      DashboardRepository? dashboardRepository,
      ClaimRepository? claimRepository,
      AdminClaimRepository? adminClaimRepository,
      ConversationRepository? conversationRepository,
      DeliveryRepository? deliveryRepository,
      ObjectAnalysisRepository? analysisRepository}) {
    final sharedClient = client ?? http.Client();
    final session = SessionManager(tokenStorage ?? const SecureTokenStorage(),
        active: false);
    final api = AuthenticatedApiClient(client: sharedClient, session: session);
    final objects = ObjectRepositoryImpl(ObjectReportRemoteDataSource(api));
    final imageRepository =
        ReportImageRepositoryImpl(ReportImageRemoteDataSource(api));
    final matches = MatchRepositoryImpl(MatchRemoteDataSource(api));
    final claims = ClaimRepositoryImpl(ClaimRemoteDataSource(api));
    final studentClaims = claimRepository ?? claims;
    final adminClaims = adminClaimRepository ?? claims;
    final conversations = conversationRepository ??
        ConversationRepositoryImpl(ConversationRemoteDataSource(api));
    final inbox = ConversationsController(ListConversations(conversations));
    final adminSummary =
        AdminSummaryController(GetAdminClaimTotals(adminClaims));
    final authentication = authRepository ??
        AuthRepositoryImpl(AuthRemoteDataSource(client: sharedClient), session);
    final dashboard = DashboardController(GetDashboardSummary(
        dashboardRepository ?? DashboardRepositoryImpl(objects, matches)));
    final deliveries = deliveryRepository ??
        DeliveryRepositoryImpl(DeliveryRemoteDataSource(api));
    late final DependencyContainer result;
    DeliveryController deliveryController(bool admin) => DeliveryController(
        admin: admin,
        listMine: ListMyDeliveries(deliveries),
        get: GetDelivery(deliveries),
        confirm: ConfirmDelivery(deliveries),
        dispute: OpenDeliveryDispute(deliveries),
        listAdmin: ListAdminDeliveries(deliveries),
        getAdmin: GetAdminDelivery(deliveries),
        complete: CompleteDelivery(deliveries),
        reopen: ReopenDelivery(deliveries),
        onChanged: () {
          inbox.refresh();
          if (!admin) {
            result.objectController.refresh();
            dashboard.refresh();
          }
        });
    final studentDelivery = deliveryController(false);
    result = DependencyContainer._(
        deliveryController: studentDelivery,
        adminDeliveryController: deliveryController(true),
        dashboardController: dashboard,
        ownedClient: client == null ? sharedClient : null,
        session: session,
        claimsController: ClaimsController(
            submit: SubmitOwnershipClaim(studentClaims),
            list: ListMyClaims(studentClaims),
            get: GetClaim(studentClaims),
            forMatch: GetMatchClaim(studentClaims),
            onConversationAvailable: inbox.refresh),
        adminClaimsController: AdminClaimsController(
            list: ListAdminClaims(adminClaims),
            get: GetAdminClaim(adminClaims),
            approve: ApproveClaim(adminClaims),
            reject: RejectClaim(adminClaims),
            onReviewed: adminSummary.refresh),
        adminSummaryController: adminSummary,
        conversationsController: inbox,
        chatFactory: () => ChatController(
            get: GetConversation(conversations),
            list: ListMessages(conversations),
            send: SendMessage(conversations),
            read: MarkConversationRead(conversations),
            onRefreshed: (id) => studentDelivery.loadDetail(id, silent: true),
            onActivity: inbox.refresh),
        reportImageController: ReportImageController(
            upload: UploadReportImage(imageRepository),
            metadata: GetReportImage(imageRepository),
            download: DownloadReportImage(imageRepository),
            delete: DeleteReportImage(imageRepository)),
        objectController: ObjectController(
            onReportsChanged: dashboard.refresh,
            getMyReports: GetMyReports(objects),
            getMyReport: GetMyReport(objects),
            registerObject: RegisterObject(objects),
            updateReport: UpdateObjectReport(objects),
            cancelReport: CancelObjectReport(objects)),
        matchController: MatchController(
            onMatchesChanged: dashboard.refresh,
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
    return result;
  }

  void dispose() {
    authController.removeListener(_authListener);
    unawaited(_expiry.cancel());
    unawaited(session.dispose());
    authController.dispose();
    objectController.dispose();
    dashboardController.dispose();
    matchController.dispose();
    objectAnalysisController.dispose();
    reportImageController.dispose();
    claimsController.dispose();
    adminClaimsController.dispose();
    adminSummaryController.dispose();
    for (final chat in _chats) {
      chat.dispose();
    }
    _chats.clear();
    conversationsController.dispose();
    deliveryController.dispose();
    adminDeliveryController.dispose();
    _ownedClient?.close();
  }
}
