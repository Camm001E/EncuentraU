import 'package:flutter/foundation.dart';

import '../../domain/entities/object_report.dart';
import '../../domain/usecases/get_objects.dart';
import '../../domain/usecases/register_object.dart';

enum ObjectViewStatus { initial, loading, ready, saving, success, failure }

class ObjectController extends ChangeNotifier {
  ObjectController({
    required GetObjects getObjects,
    required RegisterObject registerObject,
  })  : _getObjects = getObjects,
        _registerObject = registerObject;

  final GetObjects _getObjects;
  final RegisterObject _registerObject;

  List<ObjectReport> _items = const [];
  ObjectViewStatus _status = ObjectViewStatus.initial;
  String? _message;

  List<ObjectReport> get items => List<ObjectReport>.unmodifiable(_items);
  ObjectViewStatus get status => _status;
  String? get message => _message;
  bool get isSaving => _status == ObjectViewStatus.saving;

  Future<void> loadObjects() async {
    _status = ObjectViewStatus.loading;
    notifyListeners();

    try {
      _items = await _getObjects();
      _status = ObjectViewStatus.ready;
    } catch (_) {
      _status = ObjectViewStatus.failure;
      _message = 'No fue posible cargar los objetos simulados.';
    }
    notifyListeners();
  }

  Future<bool> register(ObjectReport report) async {
    _status = ObjectViewStatus.saving;
    _message = null;
    notifyListeners();

    try {
      await _registerObject(report);
      _items = await _getObjects();
      _status = ObjectViewStatus.success;
      _message = 'El reporte fue registrado en la simulación.';
      notifyListeners();
      return true;
    } catch (_) {
      _status = ObjectViewStatus.failure;
      _message = 'No fue posible registrar el reporte.';
      notifyListeners();
      return false;
    }
  }

  void clearMessage() {
    _message = null;
    if (_status == ObjectViewStatus.success) {
      _status = ObjectViewStatus.ready;
    }
  }
}
