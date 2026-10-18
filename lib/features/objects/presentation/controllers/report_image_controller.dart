import 'package:flutter/foundation.dart';
import '../../../../core/cache/image_byte_cache.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/presentation/api_message.dart';
import '../../domain/entities/report_image.dart';
import '../../domain/usecases/report_images.dart';

class ReportImageController extends ChangeNotifier {
  ReportImageController(
      {required UploadReportImage upload,
      required GetReportImage metadata,
      required DownloadReportImage download,
      required DeleteReportImage delete,
      ImageByteCache? cache})
      : _upload = upload,
        _metadata = metadata,
        _download = download,
        _delete = delete,
        cache = cache ?? ImageByteCache();
  final UploadReportImage _upload;
  final GetReportImage _metadata;
  final DownloadReportImage _download;
  final DeleteReportImage _delete;
  final ImageByteCache cache;
  final _pending = <String, Future<Uint8List>>{};
  final _busy = <String>{};
  final _messages = <String, String>{};
  final _versions = <String, int>{};
  int _epoch = 0;
  bool _disposed = false;
  bool _active = true;
  void activate() {
    _active = true;
  }

  int get generation => _epoch;
  int revision(String id) => _versions[id] ?? 0;
  bool isBusy(String id) => _busy.contains(id);
  String? message(String id) => _messages[id];
  bool _current(int epoch) => !_disposed && _active && epoch == _epoch;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void invalidate(String id) {
    _versions[id] = revision(id) + 1;
    cache.removeReport(id);
    _notify();
  }

  Future<Uint8List> content(ReportImageReference image) async {
    if (!_active) throw const ApiException(ApiFailure.unauthorized);
    final epoch = _epoch, version = revision(image.reportId);
    final key = '${image.reportId}:${image.version}:$version';
    final saved = cache.get(key);
    if (saved != null) return saved;
    final current = _pending[key];
    if (current != null) return current;
    final future = _download(image.reportId).then((value) {
      if (!_current(epoch)) throw const ApiException(ApiFailure.unauthorized);
      if (version != revision(image.reportId))
        throw const ApiException(ApiFailure.invalidResponse);
      cache.put(key, value);
      return value;
    });
    _pending[key] = future;
    try {
      return await future;
    } finally {
      if (_pending[key] == future) _pending.remove(key);
    }
  }

  Future<ReportImageReference?> metadata(String id) async {
    final epoch = _epoch;
    try {
      final image = await _metadata(id);
      return _current(epoch) ? image : null;
    } catch (error) {
      if (_current(epoch) &&
          !(error is ApiException && error.failure == ApiFailure.notFound)) {
        _messages[id] = apiMessage(error);
        _notify();
      }
      return null;
    }
  }

  Future<ReportImageReference?> upload(
      String id, ReportImageUpload image) async {
    if (isBusy(id)) return null;
    final epoch = _epoch;
    _busy.add(id);
    _messages.remove(id);
    _notify();
    try {
      final result = await _upload(id, image);
      if (!_current(epoch)) return null;
      invalidate(id);
      return result;
    } catch (error) {
      if (_current(epoch)) _messages[id] = apiMessage(error);
      return null;
    } finally {
      if (_current(epoch)) {
        _busy.remove(id);
        _notify();
      }
    }
  }

  Future<bool> delete(String id) async {
    if (isBusy(id)) return false;
    final epoch = _epoch;
    _busy.add(id);
    _messages.remove(id);
    _notify();
    try {
      await _delete(id);
      if (!_current(epoch)) return false;
      invalidate(id);
      return true;
    } catch (error) {
      if (_current(epoch)) _messages[id] = apiMessage(error);
      return false;
    } finally {
      if (_current(epoch)) {
        _busy.remove(id);
        _notify();
      }
    }
  }

  void clear() {
    _active = false;
    _epoch++;
    cache.clear();
    _pending.clear();
    _busy.clear();
    _messages.clear();
    _versions.clear();
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    cache.clear();
    super.dispose();
  }
}
