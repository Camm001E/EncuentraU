import '../entities/object_report.dart';

abstract interface class ObjectRepository {
  Future<List<ObjectReport>> getObjects();

  Future<void> registerObject(ObjectReport report);
}
