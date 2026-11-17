import 'package:flutter/widgets.dart';
import '../controllers/delivery_controller.dart';

class DeliveryScope extends InheritedWidget {
  const DeliveryScope(
      {required this.student,
      required this.admin,
      required super.child,
      super.key});
  final DeliveryController student, admin;
  static DeliveryScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DeliveryScope>();
  @override
  bool updateShouldNotify(DeliveryScope oldWidget) =>
      oldWidget.student != student || oldWidget.admin != admin;
}
