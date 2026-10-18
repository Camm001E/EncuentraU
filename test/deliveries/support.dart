import 'package:encuentra_u/core/domain/page.dart';
import 'package:encuentra_u/features/deliveries/domain/entities/delivery.dart';
import 'package:encuentra_u/features/deliveries/domain/repositories/delivery_repository.dart';
import 'package:encuentra_u/features/deliveries/domain/usecases/deliveries.dart';
import 'package:encuentra_u/features/deliveries/data/models/delivery_model.dart';
import 'package:encuentra_u/features/deliveries/presentation/controllers/delivery_controller.dart';
import '../remote/support.dart';
import '../claims_chat/support.dart';

Map<String, dynamic> deliveryJson(
    {DeliveryStatus status = DeliveryStatus.coordinating,
    String role = 'claimant'}) {
  final both =
      {DeliveryStatus.awaitingAdmin, DeliveryStatus.completed}.contains(status);
  final first = both || status == DeliveryStatus.awaitingConfirmations;
  const date = '2026-10-17T14:00:00Z';
  return {
    'id': 'delivery-1',
    'match_id': 'match-1',
    'claim_id': 'claim-1',
    'conversation_id': 'conversation-1',
    'status': status.wireName,
    'conversation_status':
        status == DeliveryStatus.completed ? 'closed' : 'active',
    'lost_report': matchJson()['my_report'],
    'found_report': matchJson()['candidate_report'],
    'created_at': date,
    'updated_at': date,
    'completed_at': status == DeliveryStatus.completed ? date : null,
    'claimant_confirmed_at': both ? date : null,
    'custodian_confirmed_at': first ? date : null,
    'relationship': role,
    'my_confirmed_at':
        role == 'custodian' && first || role == 'claimant' && both
            ? date
            : null,
    'other_confirmed_at':
        role == 'claimant' && first || role == 'custodian' && both
            ? date
            : null,
    'can_confirm': status == DeliveryStatus.coordinating ||
        status == DeliveryStatus.awaitingConfirmations && role == 'claimant',
    'can_dispute':
        !{DeliveryStatus.disputed, DeliveryStatus.completed}.contains(status),
    'dispute_reason': status == DeliveryStatus.disputed
        ? 'El objeto no corresponde al reporte'
        : null,
    'events': [
      for (final type in DeliveryEventType.values)
        {
          'id': type.wireName,
          'event_type': type.wireName,
          'actor': type == DeliveryEventType.claimantConfirmed
              ? 'claimant'
              : type == DeliveryEventType.custodianConfirmed
                  ? 'custodian'
                  : 'admin',
          'note': null,
          'created_at': date
        }
    ],
    'claim': claimJson(status: 'approved'),
    'message_count': 3,
    'last_activity_at': date,
    'admin_note': 'Nota administrativa privada',
  };
}

class TestDeliveries implements DeliveryRepository {
  Delivery value = DeliveryModel.fromJson(deliveryJson());
  AdminDelivery admin = DeliveryModel.admin(deliveryJson());
  Object? error;
  int confirmations = 0, disputes = 0, completions = 0, reopens = 0;
  DeliveryStatus? filter;
  Future<Delivery> Function()? onConfirm;
  Future<Delivery> Function()? onGet;
  void check() {
    if (error != null) throw error!;
  }

  @override
  Future<Delivery> getForConversation(String id) async {
    check();
    return onGet == null ? value : await onGet!();
  }

  @override
  Future<Page<Delivery>> listMine(
      {required int limit, required int offset, DeliveryStatus? status}) async {
    check();
    filter = status;
    return Page(
        items: status != null ? [] : [value],
        total: status != null ? 0 : 1,
        limit: limit,
        offset: offset);
  }

  @override
  Future<Delivery> confirm(String id) async {
    confirmations++;
    check();
    return onConfirm == null ? value : await onConfirm!();
  }

  @override
  Future<Delivery> dispute(String id, String reason) async {
    disputes++;
    check();
    return value;
  }

  @override
  Future<Page<AdminDelivery>> listAdmin(
      {required int limit, required int offset, DeliveryStatus? status}) async {
    check();
    filter = status;
    return Page(
        items: status != null ? [] : [admin],
        total: status != null ? 0 : 1,
        limit: limit,
        offset: offset);
  }

  @override
  Future<AdminDelivery> getAdmin(String id) async {
    check();
    return admin;
  }

  @override
  Future<AdminDelivery> complete(String id, {String? note}) async {
    completions++;
    check();
    return admin;
  }

  @override
  Future<AdminDelivery> reopen(String id, String note) async {
    reopens++;
    check();
    return admin;
  }
}

DeliveryController deliveryController(TestDeliveries r, {bool admin = false}) =>
    DeliveryController(
        admin: admin,
        listMine: ListMyDeliveries(r),
        get: GetDelivery(r),
        confirm: ConfirmDelivery(r),
        dispute: OpenDeliveryDispute(r),
        listAdmin: ListAdminDeliveries(r),
        getAdmin: GetAdminDelivery(r),
        complete: CompleteDelivery(r),
        reopen: ReopenDelivery(r));
