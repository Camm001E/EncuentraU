import '../../../../core/presentation/api_message.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../domain/entities/object_report.dart';
import '../../domain/entities/report_page.dart';
import '../../domain/usecases/get_my_reports.dart';
import '../../domain/usecases/get_my_report.dart';
import '../../domain/usecases/register_object.dart';
import '../../domain/usecases/update_object_report.dart';
import '../../domain/usecases/cancel_object_report.dart';

class ObjectController extends PagedController<ObjectReport> {
  ObjectController(
      {required GetMyReports getMyReports,
      required GetMyReport getMyReport,
      required RegisterObject registerObject,
      required UpdateObjectReport updateReport,
      required CancelObjectReport cancelReport,
      this.onReportsChanged})
      : _list = getMyReports,
        _get = getMyReport,
        _create = registerObject,
        _update = updateReport,
        _cancel = cancelReport;
  final GetMyReports _list;
  final GetMyReport _get;
  final RegisterObject _create;
  final UpdateObjectReport _update;
  final CancelObjectReport _cancel;
  final void Function()? onReportsChanged;
  ReportType? reportTypeFilter;
  ReportStatus? statusFilter;
  ObjectReport? detail;
  LoadStatus detailStatus = LoadStatus.initial;
  String? detailMessage;
  String? actionMessage;
  bool isSaving = false;
  bool isUpdating = false;
  bool isCancelling = false;
  int _detailRequest = 0;
  @override
  String itemId(ObjectReport item) => item.id;
  @override
  Future<ReportPage> fetchPage(int limit, int offset) => _list(
      limit: limit,
      offset: offset,
      reportType: reportTypeFilter,
      status: statusFilter);
  Future<void> setFilters(
      {ReportType? reportType, ReportStatus? status}) async {
    reportTypeFilter = reportType;
    statusFilter = status;
    await refresh();
  }

  Future<void> loadDetail(String id) async {
    final epoch = generation, request = ++_detailRequest;
    detail = null;
    detailMessage = null;
    detailStatus = LoadStatus.loading;
    notify();
    try {
      final report = await _get(id);
      if (!isCurrent(epoch) || request != _detailRequest) return;
      detail = report;
      detailStatus = LoadStatus.ready;
    } catch (error) {
      if (!isCurrent(epoch) || request != _detailRequest) return;
      detailStatus = LoadStatus.error;
      detailMessage = apiMessage(error);
    } finally {
      if (isCurrent(epoch) && request == _detailRequest) notify();
    }
  }

  Future<ObjectReport?> register(ObjectReportDraft draft) async {
    if (isSaving) return null;
    final epoch = generation;
    isSaving = true;
    actionMessage = null;
    notify();
    try {
      final report = await _create(draft);
      if (!isCurrent(epoch)) return null;
      detail = report;
      detailStatus = LoadStatus.ready;
      await refresh();
      if (isCurrent(epoch)) onReportsChanged?.call();
      return isCurrent(epoch) ? report : null;
    } catch (error) {
      if (isCurrent(epoch)) actionMessage = apiMessage(error);
      return null;
    } finally {
      if (isCurrent(epoch)) {
        isSaving = false;
        notify();
      }
    }
  }

  Future<bool> update(String id, ObjectReportUpdate update) async {
    if (isUpdating || isCancelling) return false;
    final epoch = generation;
    isUpdating = true;
    actionMessage = null;
    notify();
    try {
      final report = await _update(id, update);
      if (!isCurrent(epoch)) return false;
      detail = report;
      detailStatus = LoadStatus.ready;
      await refresh();
      if (isCurrent(epoch)) onReportsChanged?.call();
      return isCurrent(epoch);
    } catch (error) {
      if (isCurrent(epoch)) actionMessage = apiMessage(error);
      return false;
    } finally {
      if (isCurrent(epoch)) {
        isUpdating = false;
        notify();
      }
    }
  }

  Future<bool> cancel(String id) async {
    if (isCancelling || isUpdating) return false;
    final epoch = generation;
    isCancelling = true;
    actionMessage = null;
    notify();
    try {
      await _cancel(id);
      if (!isCurrent(epoch)) return false;
      detail = null;
      detailStatus = LoadStatus.loading;
      notify();
      await Future.wait([refresh(), loadDetail(id)]);
      if (isCurrent(epoch)) onReportsChanged?.call();
      return isCurrent(epoch);
    } catch (error) {
      if (isCurrent(epoch)) actionMessage = apiMessage(error);
      return false;
    } finally {
      if (isCurrent(epoch)) {
        isCancelling = false;
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
    isSaving = false;
    isUpdating = false;
    isCancelling = false;
    reportTypeFilter = null;
    statusFilter = null;
    super.clear();
  }
}
