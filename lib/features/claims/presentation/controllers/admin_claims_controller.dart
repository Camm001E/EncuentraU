import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/domain/ownership_limits.dart';
import '../../../../core/domain/page.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/presentation/api_message.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../domain/entities/ownership_claim.dart';
import '../../domain/usecases/claims.dart';

class AdminClaimsController extends PagedController<AdminClaim> {
  AdminClaimsController(
      {required ListAdminClaims list,
      required GetAdminClaim get,
      required ApproveClaim approve,
      required RejectClaim reject,
      this.onReviewed})
      : _list = list,
        _get = get,
        _approve = approve,
        _reject = reject;
  final ListAdminClaims _list;
  final GetAdminClaim _get;
  final ApproveClaim _approve;
  final RejectClaim _reject;
  final void Function()? onReviewed;
  ClaimStatus? statusFilter = ClaimStatus.pending;
  AdminClaim? detail;
  LoadStatus detailStatus = LoadStatus.initial;
  String? detailMessage, actionMessage;
  bool isReviewing = false;
  int _detailRequest = 0;
  @override
  String itemId(AdminClaim item) => item.id;
  @override
  Future<Page<AdminClaim>> fetchPage(int limit, int offset) =>
      _list(limit: limit, offset: offset, status: statusFilter);
  Future<void> setStatus(ClaimStatus? value) async {
    statusFilter = value;
    await refresh();
  }

  Future<void> loadDetail(String id) async {
    final epoch = generation, request = ++_detailRequest;
    detail = null;
    detailStatus = LoadStatus.loading;
    detailMessage = null;
    notify();
    try {
      final result = await _get(id);
      if (!isCurrent(epoch) || request != _detailRequest) return;
      detail = result;
      detailStatus = LoadStatus.ready;
    } catch (error) {
      if (isCurrent(epoch) && request == _detailRequest) {
        detailStatus = LoadStatus.error;
        detailMessage = apiMessage(error);
      }
    } finally {
      if (isCurrent(epoch) && request == _detailRequest) notify();
    }
  }

  Future<bool> approve(String id, {String? note}) =>
      _review(id, () => _approve(id, note: note));
  Future<bool> reject(String id, {required String reason, String? note}) {
    if (reason.trim().runes.length < OwnershipLimits.minimumRejectionLength ||
        reason.trim().runes.length > OwnershipLimits.maximumNoteLength) {
      actionMessage = AppStrings.reviewReasonValidation;
      notify();
      return Future.value(false);
    }
    return _review(id, () => _reject(id, reason: reason, note: note));
  }

  Future<bool> _review(String id, Future<AdminClaim> Function() work) async {
    if (isReviewing) return false;
    if (detail?.id != id || detail?.status != ClaimStatus.pending) {
      actionMessage = AppStrings.workflowConflict;
      notify();
      return false;
    }
    final epoch = generation;
    isReviewing = true;
    actionMessage = null;
    notify();
    try {
      final result = await work();
      if (!isCurrent(epoch)) return false;
      detail = result;
      detailStatus = LoadStatus.ready;
      onReviewed?.call();
      await refresh();
      return isCurrent(epoch);
    } catch (error) {
      if (isCurrent(epoch)) {
        actionMessage = apiMessage(error);
        if (error is ApiException &&
            error.failure == ApiFailure.workflowConflict) await loadDetail(id);
      }
      return false;
    } finally {
      if (isCurrent(epoch)) {
        isReviewing = false;
        notify();
      }
    }
  }

  @override
  void clear() {
    _detailRequest++;
    detail = null;
    detailStatus = LoadStatus.initial;
    detailMessage = null;
    actionMessage = null;
    isReviewing = false;
    statusFilter = ClaimStatus.pending;
    super.clear();
  }
}

class AdminSummaryController extends ChangeNotifier {
  AdminSummaryController(this._get);
  final GetAdminClaimTotals _get;
  AdminClaimTotals? totals;
  LoadStatus status = LoadStatus.initial;
  String? message;
  int _epoch = 0;
  bool _disposed = false;
  Future<void> ensureLoaded() async {
    if (status == LoadStatus.initial) await refresh();
  }

  Future<void> refresh() async {
    final epoch = ++_epoch;
    status = LoadStatus.loading;
    message = null;
    notifyListeners();
    try {
      final value = await _get();
      if (_disposed || epoch != _epoch) return;
      totals = value;
      status = LoadStatus.ready;
    } catch (error) {
      if (_disposed || epoch != _epoch) return;
      totals = null;
      status = LoadStatus.error;
      message = apiMessage(error);
    }
    if (!_disposed && epoch == _epoch) notifyListeners();
  }

  void clear() {
    _epoch++;
    totals = null;
    status = LoadStatus.initial;
    message = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
