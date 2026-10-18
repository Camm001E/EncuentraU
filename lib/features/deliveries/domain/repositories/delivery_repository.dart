import '../../../../core/domain/page.dart';
import '../entities/delivery.dart';

abstract interface class DeliveryRepository {
  Future<Page<Delivery>> listMine(
      {required int limit, required int offset, DeliveryStatus? status});
  Future<Delivery> getForConversation(String id);
  Future<Delivery> confirm(String id);
  Future<Delivery> dispute(String id, String reason);
  Future<Page<AdminDelivery>> listAdmin(
      {required int limit, required int offset, DeliveryStatus? status});
  Future<AdminDelivery> getAdmin(String id);
  Future<AdminDelivery> complete(String id, {String? note});
  Future<AdminDelivery> reopen(String id, String note);
}
