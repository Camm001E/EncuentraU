import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/object_image_analysis.dart';
import '../../domain/entities/object_image_input.dart';
import '../../domain/exceptions/object_analysis_exception.dart';
import '../../domain/usecases/analyze_object_image.dart';

enum ObjectAnalysisStatus {
  initial,
  analyzing,
  success,
  failure,
}

class ObjectAnalysisController extends ChangeNotifier {
  ObjectAnalysisController(this._analyzeObjectImage);

  final AnalyzeObjectImage _analyzeObjectImage;

  ObjectAnalysisStatus _status = ObjectAnalysisStatus.initial;

  ObjectImageAnalysis? _analysis;
  String? _message;

  ObjectAnalysisStatus get status => _status;
  ObjectImageAnalysis? get analysis => _analysis;
  String? get message => _message;

  bool get isAnalyzing => _status == ObjectAnalysisStatus.analyzing;

  bool get hasAnalysis => _analysis != null;

  Future<bool> analyze(ObjectImageInput input) async {
    _status = ObjectAnalysisStatus.analyzing;
    _analysis = null;
    _message = null;
    notifyListeners();

    try {
      _analysis = await _analyzeObjectImage(input);
      _status = ObjectAnalysisStatus.success;
      _message = AppStrings.analysisCompletedMessage;
      notifyListeners();

      return true;
    } on ObjectAnalysisException catch (error) {
      _status = ObjectAnalysisStatus.failure;
      _message = error.message;
      notifyListeners();

      return false;
    } catch (_) {
      _status = ObjectAnalysisStatus.failure;
      _message = AppStrings.analysisUnavailable;
      notifyListeners();

      return false;
    }
  }

  void reset() {
    _status = ObjectAnalysisStatus.initial;
    _analysis = null;
    _message = null;
    notifyListeners();
  }
}
