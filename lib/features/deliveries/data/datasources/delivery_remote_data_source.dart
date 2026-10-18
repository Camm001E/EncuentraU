import '../../../../core/constants/api_constants.dart';
import '../../../../core/domain/page.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/entities/delivery.dart';
import '../models/delivery_model.dart';

class DeliveryRemoteDataSource {
  const DeliveryRemoteDataSource(this.api);
  final AuthenticatedApiClient api;
  Map<String, String> query(int limit, int offset, DeliveryStatus? status) => {
        ApiConstants.limitParameter: '$limit',
        ApiConstants.offsetParameter: '$offset',
        if (status != null) ApiConstants.statusParameter: status.wireName,
      };
  Future<Page<Delivery>> listMine(
          {required int limit,
          required int offset,
          DeliveryStatus? status}) async =>
      JsonReader.page(
          (await api.request('GET', ApiConstants.myDeliveriesPath,
              query: query(limit, offset, status)))!,
          (v) => DeliveryModel.fromJson(JsonReader.object(v)));
  Future<Delivery> getForConversation(String id) async =>
      DeliveryModel.fromJson((await api.request(
          'GET', ApiConstants.conversationDeliveryPath(id)))!);
  Future<Delivery> confirm(String id) async => DeliveryModel.fromJson(
      (await api.request('POST', ApiConstants.confirmDeliveryPath(id)))!);
  Future<Delivery> dispute(String id, String reason) async =>
      DeliveryModel.fromJson((await api.request(
          'POST', ApiConstants.disputeDeliveryPath(id),
          body: {'reason': reason}))!);
  Future<Page<AdminDelivery>> listAdmin(
          {required int limit,
          required int offset,
          DeliveryStatus? status}) async =>
      JsonReader.page(
          (await api.request('GET', ApiConstants.adminDeliveriesPath,
              query: query(limit, offset, status)))!,
          (v) => DeliveryModel.admin(JsonReader.object(v)));
  Future<AdminDelivery> getAdmin(String id) async => DeliveryModel.admin(
      (await api.request('GET', ApiConstants.adminDeliveryPath(id)))!);
  Future<AdminDelivery> complete(String id, String? note) async =>
      DeliveryModel.admin((await api.request(
          'POST', ApiConstants.completeDeliveryPath(id),
          body: {if (note != null && note.isNotEmpty) 'admin_note': note}))!);
  Future<AdminDelivery> reopen(String id, String note) async =>
      DeliveryModel.admin((await api.request(
          'POST', ApiConstants.reopenDeliveryPath(id),
          body: {'admin_note': note}))!);
}
