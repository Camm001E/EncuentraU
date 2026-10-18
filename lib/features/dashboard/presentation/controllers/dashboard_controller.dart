import 'package:flutter/foundation.dart';
import '../../../../core/presentation/paged_controller.dart';
import '../../../../core/presentation/api_message.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/usecases/get_dashboard_summary.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(this._get);
  final GetDashboardSummary _get;
  DashboardSummary? summary;
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
      final result = await _get();
      if (_disposed || epoch != _epoch) return;
      summary = result;
      status = LoadStatus.ready;
    } catch (error) {
      if (_disposed || epoch != _epoch) return;
      summary = null;
      status = LoadStatus.error;
      message = apiMessage(error);
    }
    if (!_disposed && epoch == _epoch) notifyListeners();
  }

  void clear() {
    _epoch++;
    summary = null;
    message = null;
    status = LoadStatus.initial;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
