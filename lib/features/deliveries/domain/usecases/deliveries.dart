import '../../../../core/domain/page.dart';
import '../entities/delivery.dart';
import '../repositories/delivery_repository.dart';

class GetDelivery {
  const GetDelivery(this.repository);
  final DeliveryRepository repository;
  Future<Delivery> call(String conversationId) =>
      repository.getForConversation(conversationId);
}

class ListMyDeliveries {
  const ListMyDeliveries(this.repository);
  final DeliveryRepository repository;
  Future<Page<Delivery>> call(
          {required int limit, required int offset, DeliveryStatus? status}) =>
      repository.listMine(limit: limit, offset: offset, status: status);
}

class ConfirmDelivery {
  const ConfirmDelivery(this.repository);
  final DeliveryRepository repository;
  Future<Delivery> call(String id) => repository.confirm(id);
}

class OpenDeliveryDispute {
  const OpenDeliveryDispute(this.repository);
  final DeliveryRepository repository;
  Future<Delivery> call(String id, String reason) {
    final value = reason.trim();
    if (value.runes.length < DeliveryLimits.minimumReasonLength ||
        value.runes.length > DeliveryLimits.maximumNoteLength)
      throw const FormatException();
    return repository.dispute(id, value);
  }
}

class ListAdminDeliveries {
  const ListAdminDeliveries(this.repository);
  final DeliveryRepository repository;
  Future<Page<AdminDelivery>> call(
          {required int limit, required int offset, DeliveryStatus? status}) =>
      repository.listAdmin(limit: limit, offset: offset, status: status);
}

class GetAdminDelivery {
  const GetAdminDelivery(this.repository);
  final DeliveryRepository repository;
  Future<AdminDelivery> call(String id) => repository.getAdmin(id);
}

class CompleteDelivery {
  const CompleteDelivery(this.repository);
  final DeliveryRepository repository;
  Future<AdminDelivery> call(String id, {String? note}) {
    if ((note?.trim().runes.length ?? 0) > DeliveryLimits.maximumNoteLength)
      throw const FormatException();
    return repository.complete(id, note: note?.trim());
  }
}

class ReopenDelivery {
  const ReopenDelivery(this.repository);
  final DeliveryRepository repository;
  Future<AdminDelivery> call(String id, String note) {
    final value = note.trim();
    if (value.isEmpty || value.runes.length > DeliveryLimits.maximumNoteLength)
      throw const FormatException();
    return repository.reopen(id, value);
  }
}
