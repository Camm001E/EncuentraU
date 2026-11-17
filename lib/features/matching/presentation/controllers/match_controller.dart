import '../../../objects/domain/entities/object_report.dart';
import '../../../../core/presentation/api_message.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../domain/entities/object_match.dart';
import '../../domain/entities/visual_review.dart';
import '../../domain/entities/match_page.dart';
import '../../domain/usecases/generate_report_matches.dart';
import '../../domain/usecases/get_my_matches.dart';
import '../../domain/usecases/get_my_match.dart';

enum MatchSection { candidates, discarded, closed }

class MatchController extends PagedController<ObjectMatch> {
  MatchController(
      {required GenerateReportMatches generateReportMatches,
      required GetMyMatches getMyMatches,
      required GetMyMatch getMyMatch,
      this.reviewPhotos,
      this.reportId,
      this.onMatchesChanged})
      : _generate = generateReportMatches,
        _list = getMyMatches,
        _get = getMyMatch;
  final String? reportId;
  MatchSection section = MatchSection.candidates;
  MatchController forReport(String id) => MatchController(
      generateReportMatches: _generate,
      getMyMatches: _list,
      getMyMatch: _get,
      reviewPhotos: reviewPhotos,
      onMatchesChanged: onMatchesChanged,
      reportId: id);
  MatchSection sectionFor(ObjectMatch match) {
    if (match.myReport.status != ReportStatus.active ||
        match.candidateReport.status != ReportStatus.active)
      return MatchSection.closed;
    if (match.status == MatchStatus.rejected ||
        visualReviewFor(match)?.verdict == VisualVerdict.different)
      return MatchSection.discarded;
    return MatchSection.candidates;
  }

  List<ObjectMatch> get visibleItems =>
      rankedItems.where((m) => sectionFor(m) == section).toList();
  int sectionCount(MatchSection value) =>
      items.where((m) => sectionFor(m) == value).length;
  void selectSection(MatchSection value) {
    section = value;
    notify();
  }

  final GenerateReportMatches _generate;
  final GetMyMatches _list;
  final GetMyMatch _get;
  final void Function()? onMatchesChanged;
  final Future<VisualReview> Function(String)? reviewPhotos;
  final Map<String, VisualReview> _reviews = {};
  final Set<String> reviewing = {};
  final Map<String, String> reviewErrors = {};
  bool isReviewingBatch = false;
  int batchCompleted = 0, batchTotal = 0;
  bool get canReview => reviewPhotos != null;
  int get reviewableCount => visibleItems
      .where((m) =>
          m.myReport.image != null &&
          m.candidateReport.image != null &&
          visualReviewFor(m) == null)
      .length;

  VisualReview? visualReviewFor(ObjectMatch match) {
    for (final result in [_reviews[match.id], match.visualReview]) {
      if (result != null && result.appliesTo(match)) return result;
    }
    return null;
  }

  List<ObjectMatch> get rankedItems {
    final ordered = items.toList();
    int rank(ObjectMatch m) => switch (visualReviewFor(m)?.verdict) {
          VisualVerdict.consistent => 0,
          VisualVerdict.different => 2,
          _ => 1,
        };
    final positions = {
      for (var i = 0; i < ordered.length; i++) ordered[i].id: i
    };
    ordered.sort((a, b) {
      final difference = rank(a).compareTo(rank(b));
      return difference != 0
          ? difference
          : positions[a.id]!.compareTo(positions[b.id]!);
    });
    return ordered;
  }

  Future<void> review(ObjectMatch match) async {
    if (!canReview ||
        reviewing.contains(match.id) ||
        match.myReport.image == null ||
        match.candidateReport.image == null) return;
    final epoch = generation;
    reviewing.add(match.id);
    reviewErrors.remove(match.id);
    notify();
    try {
      final result = await reviewPhotos!(match.id);
      if (!isCurrent(epoch)) return;
      if (!result.appliesTo(match)) {
        _reviews.remove(match.id);
        reviewErrors[match.id] =
            'Las fotos cambiaron. Actualiza esta coincidencia.';
        return;
      }
      if (_reviews.length >= 128) _reviews.remove(_reviews.keys.first);
      _reviews[match.id] = result;
    } catch (error) {
      if (isCurrent(epoch)) {
        _reviews.remove(match.id);
        reviewErrors[match.id] = apiMessage(error);
      }
    } finally {
      if (isCurrent(epoch)) {
        reviewing.remove(match.id);
        notify();
      }
    }
  }

  Future<void> reviewVisible() async {
    if (isReviewingBatch || !canReview) return;
    final epoch = generation;
    final candidates = visibleItems
        .where((m) =>
            m.myReport.image != null &&
            m.candidateReport.image != null &&
            visualReviewFor(m) == null)
        .take(5)
        .toList();
    isReviewingBatch = true;
    batchCompleted = 0;
    batchTotal = candidates.length;
    notify();
    try {
      for (final match in candidates) {
        if (!isCurrent(epoch)) break;
        await review(match);
        if (isCurrent(epoch)) {
          batchCompleted++;
          notify();
        }
      }
    } finally {
      if (isCurrent(epoch)) {
        isReviewingBatch = false;
        notify();
      }
    }
  }

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
      limit: limit,
      offset: offset,
      level: levelFilter,
      status: statusFilter,
      reportId: reportId);
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
      notify();
      if (visualReviewFor(result) == null) await review(result);
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
    section = MatchSection.candidates;
    _reviews.clear();
    reviewing.clear();
    reviewErrors.clear();
    isReviewingBatch = false;
    batchCompleted = batchTotal = 0;
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
