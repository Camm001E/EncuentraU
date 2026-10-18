import '../../../../core/domain/page.dart';
import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../datasources/delivery_remote_data_source.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  const DeliveryRepositoryImpl(this.remote);
  final DeliveryRemoteDataSource remote;
  Future<T> parse<T>(Future<T> Function() work) async {
    try {
      return await work();
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  @override
  Future<Page<Delivery>> listMine(
          {required int limit, required int offset, DeliveryStatus? status}) =>
      parse(
          () => remote.listMine(limit: limit, offset: offset, status: status));
  @override
  Future<Delivery> getForConversation(String id) =>
      parse(() => remote.getForConversation(id));
  @override
  Future<Delivery> confirm(String id) => parse(() => remote.confirm(id));
  @override
  Future<Delivery> dispute(String id, String reason) =>
      parse(() => remote.dispute(id, reason));
  @override
  Future<Page<AdminDelivery>> listAdmin(
          {required int limit, required int offset, DeliveryStatus? status}) =>
      parse(
          () => remote.listAdmin(limit: limit, offset: offset, status: status));
  @override
  Future<AdminDelivery> getAdmin(String id) => parse(() => remote.getAdmin(id));
  @override
  Future<AdminDelivery> complete(String id, {String? note}) =>
      parse(() => remote.complete(id, note));
  @override
  Future<AdminDelivery> reopen(String id, String note) =>
      parse(() => remote.reopen(id, note));
}
