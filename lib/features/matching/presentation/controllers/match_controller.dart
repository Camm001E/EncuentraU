import '../../../../core/presentation/api_message.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../domain/entities/object_match.dart';
import '../../domain/entities/match_page.dart';
import '../../domain/usecases/generate_report_matches.dart';
import '../../domain/usecases/get_my_matches.dart';
import '../../domain/usecases/get_my_match.dart';

class MatchController extends PagedController<ObjectMatch> {
  MatchController(
      {required GenerateReportMatches generateReportMatches,
      required GetMyMatches getMyMatches,
      required GetMyMatch getMyMatch,
      this.onMatchesChanged})
      : _generate = generateReportMatches,
        _list = getMyMatches,
        _get = getMyMatch;
  final GenerateReportMatches _generate;
  final GetMyMatches _list;
  final GetMyMatch _get;
  final void Function()? onMatchesChanged;
  MatchLevel? levelFilter;
  MatchStatus? statusFilter;
  ObjectMatch? detail;
  LoadStatus detailStatus = LoadStatus.initial;
  String? detailMessage;
  String? generationMessage;
  bool isGenerating = false;
  int _detailRequest = 0;
  @override
  String itemId(ObjectMatch item) => item.id;
  @override
  Future<MatchPage> fetchPage(int limit, int offset) => _list(
      limit: limit, offset: offset, level: levelFilter, status: statusFilter);
  Future<void> setFilters({MatchLevel? level, MatchStatus? status}) async {
    levelFilter = level;
    statusFilter = status;
    await refresh();
  }

  void resetFilters() {
    levelFilter = null;
    statusFilter = null;
  }

  Future<GeneratedMatches?> generate(String reportId) async {
    if (isGenerating) return null;
    final epoch = generation;
    isGenerating = true;
    generationMessage = null;
    notify();
    try {
      final result = await _generate(reportId);
      if (isCurrent(epoch)) onMatchesChanged?.call();
      return isCurrent(epoch) ? result : null;
    } catch (error) {
      if (isCurrent(epoch)) generationMessage = apiMessage(error);
      return null;
    } finally {
      if (isCurrent(epoch)) {
        isGenerating = false;
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
    } catch (error) {
      if (!isCurrent(epoch) || request != _detailRequest) return;
      detailStatus = LoadStatus.error;
      detailMessage = apiMessage(error);
    } finally {
      if (isCurrent(epoch) && request == _detailRequest) notify();
    }
  }

  @override
  void clear() {
    _detailRequest++;
    detail = null;
    detailStatus = LoadStatus.initial;
    detailMessage = null;
    generationMessage = null;
    isGenerating = false;
    resetFilters();
    super.clear();
  }
}
