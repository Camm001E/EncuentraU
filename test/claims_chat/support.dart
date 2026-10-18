import 'package:encuentra_u/core/domain/page.dart';
import 'package:encuentra_u/features/claims/data/models/claim_model.dart';
import 'package:encuentra_u/features/claims/domain/entities/ownership_claim.dart';
import 'package:encuentra_u/features/claims/domain/repositories/claim_repository.dart';
import 'package:encuentra_u/features/claims/domain/usecases/claims.dart';
import 'package:encuentra_u/features/claims/presentation/controllers/claims_controller.dart';
import 'package:encuentra_u/features/claims/presentation/controllers/admin_claims_controller.dart';
import 'package:encuentra_u/features/messaging/data/models/conversation_model.dart';
import 'package:encuentra_u/features/messaging/domain/entities/conversation.dart';
import 'package:encuentra_u/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:encuentra_u/features/messaging/domain/usecases/conversations.dart';
import 'package:encuentra_u/features/messaging/presentation/controllers/chat_controller.dart';
import '../remote/support.dart';

Map<String, dynamic> claimJson(
        {String status = 'pending', String relationship = 'claimant'}) =>
    {
      'id': 'claim-1',
      'match_id': matchJson()['id'],
      'status': status,
      'relationship': relationship,
      'match': matchJson(),
      'ownership_evidence': 'Una marca blanca debajo de la copa izquierda.',
      'lost_private_feature': 'Detalle privado perdido',
      'found_private_feature': 'Detalle privado encontrado',
      'admin_note': 'Nota interna',
      'created_at': '2026-10-17T12:00:00Z',
      'updated_at': '2026-10-17T12:00:01Z',
      'reviewed_at': status == 'pending' ? null : '2026-10-17T12:00:01Z',
      'rejection_reason':
          status == 'rejected' ? 'El detalle no coincide.' : null,
      'conversation_id': status == 'approved' ? 'conversation-1' : null
    };
Map<String, dynamic> messageJson(
        {String id = 'message-1', bool mine = false, int second = 1}) =>
    {
      'id': id,
      'client_message_id': 'client-$id',
      'body': 'Mensaje $id',
      'is_mine': mine,
      'created_at': '2026-10-17T12:00:${second.toString().padLeft(2, '0')}Z'
    };
Map<String, dynamic> conversationJson({int unread = 1}) => {
      'id': 'conversation-1',
      'match_id': matchJson()['id'],
      'claim_id': 'claim-1',
      'status': 'active',
      'other_display_name': 'Persona',
      'report': matchJson()['my_report'],
      'unread_count': unread,
      'last_message': messageJson(),
      'last_message_at': '2026-10-17T12:00:01Z',
      'created_at': '2026-10-17T12:00:00Z',
      'updated_at': '2026-10-17T12:00:01Z'
    };

class TestClaims implements ClaimRepository, AdminClaimRepository {
  OwnershipClaim value = ClaimModel.fromJson(claimJson());
  AdminClaim admin = ClaimModel.admin(claimJson());
  Object? error;
  int submitted = 0, approved = 0, rejected = 0;
  Future<OwnershipClaim> Function()? onSubmit;
  Future<AdminClaim> Function()? onApprove;
  ClaimStatus? filter;
  int? offset;
  void check() {
    if (error != null) throw error!;
  }

  @override
  Future<OwnershipClaim> submit(String id, ClaimDraft draft) async {
    submitted++;
    check();
    return onSubmit == null ? value : await onSubmit!();
  }

  @override
  Future<OwnershipClaim> getClaim(String id) async {
    check();
    return value;
  }

  @override
  Future<OwnershipClaim?> getMatchClaim(String id) async {
    check();
    return value;
  }

  @override
  Future<Page<OwnershipClaim>> getMyClaims(
      {required int limit, required int offset, ClaimStatus? status}) async {
    check();
    filter = status;
    this.offset = offset;
    return Page(items: [value], total: 21, limit: limit, offset: offset);
  }

  @override
  Future<Page<AdminClaim>> getAdminClaims(
      {required int limit, required int offset, ClaimStatus? status}) async {
    check();
    filter = status;
    return Page(items: [admin], total: 1, limit: limit, offset: offset);
  }

  @override
  Future<AdminClaim> getAdminClaim(String id) async {
    check();
    return admin;
  }

  @override
  Future<AdminClaimTotals> getTotals() async {
    check();
    return const AdminClaimTotals(pending: 12, approved: 7, rejected: 3);
  }

  @override
  Future<AdminClaim> approve(String id, {String? note}) async {
    approved++;
    check();
    admin = onApprove == null
        ? ClaimModel.admin(claimJson(status: 'approved'))
        : await onApprove!();
    return admin;
  }

  @override
  Future<AdminClaim> reject(String id,
      {required String reason, String? note}) async {
    rejected++;
    check();
    return admin = ClaimModel.admin(claimJson(status: 'rejected'));
  }
}

ClaimsController claimsController(TestClaims repo) => ClaimsController(
    submit: SubmitOwnershipClaim(repo),
    list: ListMyClaims(repo),
    get: GetClaim(repo),
    forMatch: GetMatchClaim(repo));
AdminClaimsController adminController(TestClaims repo) => AdminClaimsController(
    list: ListAdminClaims(repo),
    get: GetAdminClaim(repo),
    approve: ApproveClaim(repo),
    reject: RejectClaim(repo));

class TestConversations implements ConversationRepository {
  Object? error;
  int lists = 0, reads = 0, sends = 0;
  final sentIds = <String>[];
  final readIds = <String?>[];
  Future<ChatMessage> Function()? onSend;
  Future<MessagePage> Function(String?)? onMessages;
  Future<Page<Conversation>> Function()? onInbox;
  List<ChatMessage> items = [ConversationModel.message(messageJson())];
  void check() {
    if (error != null) throw error!;
  }

  @override
  Future<Page<Conversation>> getMyConversations(
      {required int limit, required int offset}) async {
    check();
    if (onInbox != null) return onInbox!();
    return Page(
        items: [ConversationModel.fromJson(conversationJson())],
        total: 1,
        limit: limit,
        offset: offset);
  }

  @override
  Future<Conversation> getConversation(String id) async {
    check();
    return ConversationModel.fromJson(conversationJson());
  }

  @override
  Future<MessagePage> getMessages(String id,
      {int limit = 50, String? before}) async {
    lists++;
    check();
    return onMessages == null
        ? MessagePage(items: items, limit: limit)
        : await onMessages!(before);
  }

  @override
  Future<ChatMessage> sendMessage(String id,
      {required String body, required String clientMessageId}) async {
    sends++;
    sentIds.add(clientMessageId);
    check();
    return onSend == null
        ? ConversationModel.message(
            messageJson(id: 'sent', mine: true, second: 2))
        : await onSend!();
  }

  @override
  Future<void> markRead(String id, {String? lastMessageId}) async {
    reads++;
    readIds.add(lastMessageId);
    check();
  }
}

ChatController chatController(TestConversations repo,
        {Duration interval = const Duration(seconds: 4)}) =>
    ChatController(
        get: GetConversation(repo),
        list: ListMessages(repo),
        send: SendMessage(repo),
        read: MarkConversationRead(repo),
        pollInterval: interval);
