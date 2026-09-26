import '../../../objects/domain/entities/object_report.dart';

class ObjectMatch {
  const ObjectMatch({
    required this.lostObject,
    required this.foundObject,
    required this.percentage,
  });

  final ObjectReport lostObject;
  final ObjectReport foundObject;
  final int percentage;

  String get level {
    if (percentage >= 90) return 'Coincidencia alta';
    if (percentage >= 70) return 'Coincidencia posible';
    return 'Coincidencia baja';
  }
}
