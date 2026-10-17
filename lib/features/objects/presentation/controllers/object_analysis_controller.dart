import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/object_image_analysis.dart';
import '../../domain/entities/object_image_input.dart';
import '../../domain/exceptions/object_analysis_exception.dart';
import '../../domain/usecases/analyze_object_image.dart';

enum ObjectAnalysisStatus { initial, analyzing, success, failure }

class ObjectAnalysisController extends ChangeNotifier {
  ObjectAnalysisController(this._analyzeObjectImage);
  final AnalyzeObjectImage _analyzeObjectImage;
  ObjectAnalysisStatus _status = ObjectAnalysisStatus.initial;
  ObjectImageAnalysis? _analysis;
  String? _message;
  int _generation = 0;
  bool _disposed = false;
  ObjectAnalysisStatus get status => _status;
  ObjectImageAnalysis? get analysis => _analysis;
  String? get message => _message;
  bool get isAnalyzing => _status == ObjectAnalysisStatus.analyzing;
  bool get hasAnalysis => _analysis != null;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> analyze(ObjectImageInput input) async {
    if (isAnalyzing) return false;
    final generation = ++_generation;
    _status = ObjectAnalysisStatus.analyzing;
    _analysis = null;
    _message = null;
    _notify();
    try {
      final result = await _analyzeObjectImage(input);
      if (_disposed || generation != _generation) return false;
      _analysis = result;
      _status = ObjectAnalysisStatus.success;
      _message = AppStrings.analysisCompletedMessage;
      return true;
    } on ObjectAnalysisException catch (error) {
      if (_disposed || generation != _generation) return false;
      _status = ObjectAnalysisStatus.failure;
      _message = error.message;
      return false;
    } catch (_) {
      if (_disposed || generation != _generation) return false;
      _status = ObjectAnalysisStatus.failure;
      _message = AppStrings.analysisUnavailable;
      return false;
    } finally {
      if (!_disposed && generation == _generation) _notify();
    }
  }

  void reset() {
    _generation++;
    _status = ObjectAnalysisStatus.initial;
    _analysis = null;
    _message = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
