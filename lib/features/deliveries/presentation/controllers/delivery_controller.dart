import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/domain/page.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/presentation/api_message.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/usecases/deliveries.dart';

class DeliveryController extends PagedController<DeliveryRecord> {
  DeliveryController(
      {required ListMyDeliveries listMine,
      required GetDelivery get,
      required ConfirmDelivery confirm,
      required OpenDeliveryDispute dispute,
      required ListAdminDeliveries listAdmin,
      required GetAdminDelivery getAdmin,
      required CompleteDelivery complete,
      required ReopenDelivery reopen,
      this.admin = false,
      this.onChanged})
      : _listMine = listMine,
        _get = get,
        _confirm = confirm,
        _dispute = dispute,
        _listAdmin = listAdmin,
        _getAdmin = getAdmin,
        _complete = complete,
        _reopen = reopen;
  final ListMyDeliveries _listMine;
  final GetDelivery _get;
  final ConfirmDelivery _confirm;
  final OpenDeliveryDispute _dispute;
  final ListAdminDeliveries _listAdmin;
  final GetAdminDelivery _getAdmin;
  final CompleteDelivery _complete;
  final ReopenDelivery _reopen;
  final bool admin;
  final void Function()? onChanged;
  DeliveryStatus? statusFilter;
  DeliveryRecord? detail;
  LoadStatus detailStatus = LoadStatus.initial,
      countsStatus = LoadStatus.initial;
  String? detailMessage, actionMessage, countsMessage;
  Map<DeliveryStatus, int>? totals;
  bool isActing = false;
  int _detailRequest = 0, _countsRequest = 0;
  String? _key;
  @override
  String itemId(DeliveryRecord item) => item.id;
  @override
  Future<Page<DeliveryRecord>> fetchPage(int limit, int offset) => admin
      ? _listAdmin(limit: limit, offset: offset, status: statusFilter)
      : _listMine(limit: limit, offset: offset, status: statusFilter);
  Future<void> setStatus(DeliveryStatus? value) async {
    statusFilter = value;
    await refresh();
  }

  Future<void> loadDetail(String key, {bool silent = false}) async {
    final epoch = generation, request = ++_detailRequest;
    final retained = silent && _key == key && detail != null;
    _key = key;
    detailMessage = null;
    if (!retained) {
      detail = null;
      detailStatus = LoadStatus.loading;
    }
    notify();
    try {
      final result = admin ? await _getAdmin(key) : await _get(key);
      if (!isCurrent(epoch) || request != _detailRequest) return;
      detail = result;
      detailStatus = LoadStatus.ready;
    } catch (error) {
      if (!isCurrent(epoch) || request != _detailRequest) return;
      detailMessage = apiMessage(error);
      if (error is ApiException &&
          {ApiFailure.unauthorized, ApiFailure.forbidden, ApiFailure.notFound}
              .contains(error.failure)) detail = null;
      detailStatus = detail == null ? LoadStatus.error : LoadStatus.ready;
    } finally {
      if (isCurrent(epoch) && request == _detailRequest) notify();
    }
  }

  Future<void> refreshDetail() async {
    if (_key != null && !isActing) await loadDetail(_key!, silent: true);
  }

  Future<bool> confirm() => _act(() => _confirm(detail!.id));
  Future<bool> dispute(String reason) {
    if (reason.trim().runes.length < DeliveryLimits.minimumReasonLength ||
        reason.trim().runes.length > DeliveryLimits.maximumNoteLength) {
      actionMessage = AppStrings.disputeValidation;
      notify();
      return Future.value(false);
    }
    return _act(() => _dispute(detail!.id, reason));
  }

  Future<bool> complete({String? note}) =>
      _act(() => _complete(detail!.id, note: note));
  Future<bool> reopen(String note) => _act(() => _reopen(detail!.id, note));
  Future<bool> _act(Future<DeliveryRecord> Function() action) async {
    if (isActing || detail == null) return false;
    final epoch = generation;
    isActing = true;
    actionMessage = null;
    notify();
    try {
      final result = await action();
      if (!isCurrent(epoch)) return false;
      detail = result;
      detailStatus = LoadStatus.ready;
      onChanged?.call();
      await refreshCounts();
      return isCurrent(epoch);
    } catch (error) {
      if (isCurrent(epoch)) {
        actionMessage = apiMessage(error);
        if (error is ApiException &&
            error.failure == ApiFailure.workflowConflict &&
            _key != null) await loadDetail(_key!, silent: true);
      }
      return false;
    } finally {
      if (isCurrent(epoch)) {
        isActing = false;
        notify();
      }
    }
  }

  Future<void> refreshCounts() async {
    final epoch = generation, request = ++_countsRequest;
    countsStatus = LoadStatus.loading;
    countsMessage = null;
    notify();
    try {
      final counts = await Future.wait([
        for (final s in DeliveryStatus.values)
          (admin
                  ? _listAdmin(
                      limit: ApiConstants.countPageSize, offset: 0, status: s)
                  : _listMine(
                      limit: ApiConstants.countPageSize, offset: 0, status: s))
              .then((p) => p.total)
      ]);
      if (!isCurrent(epoch) || request != _countsRequest) return;
      totals =
          Map.unmodifiable(Map.fromIterables(DeliveryStatus.values, counts));
      countsStatus = LoadStatus.ready;
    } catch (error) {
      if (isCurrent(epoch) && request == _countsRequest) {
        totals = null;
        countsStatus = LoadStatus.error;
        countsMessage = apiMessage(error);
      }
    } finally {
      if (isCurrent(epoch) && request == _countsRequest) notify();
    }
  }

  @override
  void clear() {
    _detailRequest++;
    _countsRequest++;
    _key = null;
    detail = null;
    totals = null;
    detailStatus = LoadStatus.initial;
    countsStatus = LoadStatus.initial;
    detailMessage = null;
    countsMessage = null;
    actionMessage = null;
    isActing = false;
    statusFilter = null;
    super.clear();
  }
}
