import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependency_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = DependencyContainer.create();
  runApp(EncuentraUApp(dependencies: dependencies));
  unawaited(dependencies.objectController.loadObjects());
}
