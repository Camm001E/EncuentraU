import '../../../../core/constants/app_strings.dart';
import '../../../../core/domain/page.dart';
import '../../../../core/presentation/api_message.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../domain/entities/ownership_claim.dart';
import '../../domain/usecases/claims.dart';

class ClaimsController extends PagedController<OwnershipClaim> {
  ClaimsController(
      {required SubmitOwnershipClaim submit,
      required ListMyClaims list,
      required GetClaim get,
      required GetMatchClaim forMatch,
      this.onConversationAvailable})
      : _submit = submit,
        _list = list,
        _get = get,
        _forMatch = forMatch;
  final SubmitOwnershipClaim _submit;
  final ListMyClaims _list;
  final GetClaim _get;
  final GetMatchClaim _forMatch;
  final void Function()? onConversationAvailable;
  ClaimStatus? statusFilter;
  OwnershipClaim? detail;
  LoadStatus detailStatus = LoadStatus.initial;
  String? detailMessage, actionMessage;
  bool isSubmitting = false;
  int _detailRequest = 0;
  final _matchClaims = <String, OwnershipClaim?>{};
  final _matchStates = <String, LoadStatus>{};
  final _matchErrors = <String, String>{};
  final _lookupRequests = <String, int>{};
  final _knownConversations = <String>{};
  OwnershipClaim? claimFor(String id) => _matchClaims[id];
  LoadStatus stateFor(String id) => _matchStates[id] ?? LoadStatus.initial;
  String? errorFor(String id) => _matchErrors[id];
  @override
  String itemId(OwnershipClaim item) => item.id;
  @override
  Future<Page<OwnershipClaim>> fetchPage(int limit, int offset) =>
      _list(limit: limit, offset: offset, status: statusFilter);
  Future<void> setStatus(ClaimStatus? value) async {
    statusFilter = value;
    await refresh();
  }

  void _remember(OwnershipClaim value) {
    _matchClaims[value.matchId] = value;
    _matchStates[value.matchId] = LoadStatus.ready;
    final conversation = value.conversationId;
    if (conversation != null && _knownConversations.add(conversation))
      onConversationAvailable?.call();
  }

  Future<void> loadForMatch(String id) async {
    final epoch = generation, request = (_lookupRequests[id] ?? 0) + 1;
    _lookupRequests[id] = request;
    _matchStates[id] = LoadStatus.loading;
    _matchErrors.remove(id);
    notify();
    try {
      final result = await _forMatch(id);
      if (!isCurrent(epoch) || _lookupRequests[id] != request) return;
      _matchClaims[id] = result;
      if (result != null) _remember(result);
      _matchStates[id] = LoadStatus.ready;
    } catch (error) {
      if (!isCurrent(epoch) || _lookupRequests[id] != request) return;
      _matchStates[id] = LoadStatus.error;
      _matchErrors[id] = apiMessage(error);
    } finally {
      if (isCurrent(epoch) && _lookupRequests[id] == request) notify();
    }
  }

  Future<OwnershipClaim?> submit(String matchId, ClaimDraft draft) async {
    if (isSubmitting) return null;
    if (!draft.isValid) {
      actionMessage = AppStrings.evidenceValidation;
      notify();
      return null;
    }
    final epoch = generation;
    isSubmitting = true;
    actionMessage = null;
    notify();
    try {
      final result = await _submit(matchId, draft);
      if (!isCurrent(epoch)) return null;
      _remember(result);
      detail = result;
      detailStatus = LoadStatus.ready;
      await refresh();
      return isCurrent(epoch) ? result : null;
    } catch (error) {
      if (isCurrent(epoch)) actionMessage = apiMessage(error);
      return null;
    } finally {
      if (isCurrent(epoch)) {
        isSubmitting = false;
        notify();
      }
    }
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
      _remember(result);
    } catch (error) {
      if (isCurrent(epoch) && request == _detailRequest) {
        detailStatus = LoadStatus.error;
        detailMessage = apiMessage(error);
      }
    } finally {
      if (isCurrent(epoch) && request == _detailRequest) notify();
    }
  }

  @override
  void clear() {
    _detailRequest++;
    statusFilter = null;
    detail = null;
    detailStatus = LoadStatus.initial;
    detailMessage = null;
    actionMessage = null;
    isSubmitting = false;
    _matchClaims.clear();
    _matchStates.clear();
    _matchErrors.clear();
    _lookupRequests.clear();
    _knownConversations.clear();
    super.clear();
  }
}
