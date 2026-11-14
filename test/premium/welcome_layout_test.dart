import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:encuentra_u/core/theme/app_theme.dart';
import 'package:encuentra_u/features/authentication/presentation/widgets/auth_layout.dart';

void main() {
  for (final width in [320.0, 390.0, 1280.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('welcome fits width $width and text scale $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
                body: MediaQuery(
                    data: MediaQueryData(
                        size: Size(width, 844),
                        textScaler: TextScaler.linear(scale)),
                    child: const AuthLayout(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Inicia sesión para continuar'),
                      TextField(
                          decoration: InputDecoration(
                              labelText: 'Correo institucional')),
                      SizedBox(height: 16),
                      TextField(
                          decoration: InputDecoration(labelText: 'Contraseña'))
                    ]))))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Correo institucional'), findsOneWidget);
      });
    }
  }
}
