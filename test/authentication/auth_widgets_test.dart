import '../premium/support.dart';
import 'dart:async';
import 'dart:convert';

import 'package:encuentra_u/app/app.dart';
import 'package:encuentra_u/app/dependency_container.dart';
import 'package:encuentra_u/app/routes.dart';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/core/constants/app_strings.dart';
import 'package:encuentra_u/features/authentication/domain/entities/app_user.dart';
import 'package:encuentra_u/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:encuentra_u/features/authentication/presentation/pages/login_page.dart';
import 'package:encuentra_u/features/authentication/presentation/pages/register_page.dart';
import 'package:encuentra_u/features/objects/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'auth_test_support.dart';

Future<void> largeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> fillLogin(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), testUser.email);
  await tester.enterText(find.byType(TextFormField).at(1), testPassword);
}

Widget loginApplication(FakeAuthRepository repo) {
  final controller = makeAuthController(repo);
  addTearDown(controller.dispose);
  return MaterialApp(
    home: LoginPage(controller: controller),
    routes: {
      AppRoutes.login: (_) => LoginPage(controller: controller),
      AppRoutes.home: (_) => const Scaffold(body: Text('test-home')),
      AppRoutes.register: (_) => RegisterPage(controller: controller),
    },
  );
}

Future<void> fillRegistration(WidgetTester tester,
    {String? confirmation}) async {
  final values = [
    testUser.fullName,
    testUser.email,
    testUser.studentCode,
    testPassword,
    confirmation ?? testPassword
  ];
  for (var index = 0; index < values.length; index++) {
    final field = find.byType(TextFormField).at(index);
    await tester.ensureVisible(field);
    await tester.enterText(field, values[index]);
  }
  await tester.ensureVisible(
      find.widgetWithText(FilledButton, AppStrings.registerButton));
}

http.Response emptyReports() => http.Response(
    jsonEncode({
      'items': [],
      'total': 0,
      'limit': ApiConstants.defaultPageSize,
      'offset': 0,
    }),
    ApiConstants.ok);
DependencyContainer fakeDependencies(FakeAuthRepository repository) {
  final client = MockClient((request) async {
    expect(request.url.path, ApiConstants.myReportsPath);
    expect(request.headers['authorization'], 'Bearer $testToken');
    return emptyReports();
  });
  addTearDown(client.close);
  return DependencyContainer.create(
      dashboardRepository: TestDashboardRepository(),
      authRepository: repository,
      client: client,
      tokenStorage: MemoryTokenStorage(testToken));
}

void main() {
  testWidgets('cerrar sesión permanece visible en Home con ancho de móvil',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = FakeAuthRepository()..onRestore = () async => testUser;
    final dependencies = fakeDependencies(repo);
    addTearDown(dependencies.dispose);
    await tester.pumpWidget(EncuentraUApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text(AppStrings.signOut), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login HTTP valida JWT con /me, guarda token y abre Home',
      (tester) async {
    await largeSurface(tester);
    final storage = MemoryTokenStorage();
    final requests = <String>[];
    final client = MockClient((request) async {
      requests.add(request.url.path);
      if (request.url.path == ApiConstants.myConversationsPath) {
        expect(request.headers['authorization'], 'Bearer $testToken');
        return emptyReports();
      }
      if (request.url.path == ApiConstants.myReportsPath) {
        expect(request.headers['authorization'], 'Bearer $testToken');
        return emptyReports();
      }
      if (request.url.path == ApiConstants.authLoginPath) {
        expect(request.method, 'POST');
        return http.Response(jsonEncode(sessionJson), 200);
      }
      expect(request.url.path, ApiConstants.authMePath);
      expect(request.headers['authorization'], 'Bearer $testToken');
      if (request.url.path == ApiConstants.myReportsPath) return emptyReports();
      return http.Response(jsonEncode(userJson), 200);
    });
    addTearDown(client.close);
    final dependencies = DependencyContainer.create(
        dashboardRepository: TestDashboardRepository(),
        client: client,
        tokenStorage: storage);
    addTearDown(dependencies.dispose);
    await tester.pumpWidget(EncuentraUApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await fillLogin(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(requests, [
      ApiConstants.authLoginPath,
      ApiConstants.authMePath,
      ApiConstants.myReportsPath,
      ApiConstants.myConversationsPath
    ]);
    expect(storage.token, testToken);
    expect(find.byType(HomePage), findsOneWidget);
    expect(
        Navigator.of(tester.element(find.byType(HomePage))).canPop(), isFalse);
  });

  testWidgets('login empieza vacío y permite mostrar/ocultar contraseña',
      (tester) async {
    await largeSurface(tester);
    await tester.pumpWidget(loginApplication(FakeAuthRepository()));
    for (final field
        in tester.widgetList<TextFormField>(find.byType(TextFormField))) {
      expect(field.controller?.text, isEmpty);
    }
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isTrue);
    await tester.tap(find.byTooltip(AppStrings.showPassword));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isFalse);
  });

  testWidgets('login bloquea botón y dobles envíos mientras carga',
      (tester) async {
    await largeSurface(tester);
    final pending = Completer<AppUser>();
    final repo = FakeAuthRepository()..onLogin = () => pending.future;
    await tester.pumpWidget(loginApplication(repo));
    await fillLogin(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.text(AppStrings.signingIn), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(repo.loginCalls, 1);
    pending.complete(testUser);
    await tester.pumpAndSettle();
    expect(find.text('test-home'), findsOneWidget);
    expect(
        Navigator.of(tester.element(find.text('test-home'))).canPop(), isFalse);
  });

  for (final entry in {
    AuthFailure.invalidCredentials: AppStrings.invalidCredentials,
    AuthFailure.inactiveAccount: AppStrings.inactiveAccount,
    AuthFailure.connection: AppStrings.authConnectionError,
    AuthFailure.server: AppStrings.authServerError,
  }.entries) {
    testWidgets('login muestra ${entry.key.name} sin navegar', (tester) async {
      await largeSurface(tester);
      final repo = FakeAuthRepository()
        ..onLogin = () async => throw AuthException(entry.key);
      await tester.pumpWidget(loginApplication(repo));
      await fillLogin(tester);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('test-home'), findsNothing);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull);
    });
  }

  testWidgets('registro exitoso vuelve a login con mensaje y sin autologin',
      (tester) async {
    await largeSurface(tester);
    final repo = FakeAuthRepository();
    await tester.pumpWidget(loginApplication(repo));
    await tester
        .tap(find.widgetWithText(TextButton, AppStrings.registrationTitle));
    await tester.pumpAndSettle();
    await fillRegistration(tester);
    await tester
        .tap(find.widgetWithText(FilledButton, AppStrings.registerButton));
    await tester.pumpAndSettle();
    expect(repo.registerCalls, 1);
    expect(repo.loginCalls, 0);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(RegisterPage), findsNothing);
    expect(find.text(AppStrings.accountCreated), findsOneWidget);
    expect(
        Navigator.of(tester.element(find.byType(LoginPage))).canPop(), isFalse);
  });

  testWidgets('confirmación diferente bloquea registro', (tester) async {
    await largeSurface(tester);
    final repo = FakeAuthRepository();
    await tester.pumpWidget(loginApplication(repo));
    await tester
        .tap(find.widgetWithText(TextButton, AppStrings.registrationTitle));
    await tester.pumpAndSettle();
    await fillRegistration(tester, confirmation: 'another-test-password');
    await tester
        .tap(find.widgetWithText(FilledButton, AppStrings.registerButton));
    await tester.pumpAndSettle();
    expect(repo.registerCalls, 0);
    expect(find.text(AppStrings.passwordsDoNotMatch), findsOneWidget);
  });

  testWidgets('inicio muestra identidad visual mientras restaura y luego Home',
      (tester) async {
    await largeSurface(tester);
    final pending = Completer<AppUser?>();
    final repo = FakeAuthRepository()..onRestore = () => pending.future;
    final dependencies = fakeDependencies(repo);
    addTearDown(dependencies.dispose);
    await tester.pumpWidget(EncuentraUApp(dependencies: dependencies));
    expect(find.text(AppStrings.restoringSession), findsOneWidget);
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    pending.complete(testUser);
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text(AppStrings.signOut), findsOneWidget);
  });

  testWidgets('inicio sin token abre Login y protege acceso directo a Home',
      (tester) async {
    await largeSurface(tester);
    final dependencies = fakeDependencies(FakeAuthRepository());
    addTearDown(dependencies.dispose);
    await tester.pumpWidget(EncuentraUApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    Navigator.of(tester.element(find.byType(LoginPage)))
        .pushNamed(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('logout de sesión restaurada borra token y elimina historial',
      (tester) async {
    await largeSurface(tester);
    final storage = MemoryTokenStorage(testToken);
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer $testToken');
      if (request.url.path == ApiConstants.myReportsPath) return emptyReports();
      return http.Response(jsonEncode(userJson), 200);
    });
    addTearDown(client.close);
    final dependencies = DependencyContainer.create(
        dashboardRepository: TestDashboardRepository(),
        client: client,
        tokenStorage: storage);
    addTearDown(dependencies.dispose);
    await tester.pumpWidget(EncuentraUApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    Navigator.of(tester.element(find.byType(HomePage)))
        .pushNamed(AppRoutes.home);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, AppStrings.signOut));
    await tester.pumpAndSettle();
    expect(storage.token, isNull);
    expect(storage.deletes, 1);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    expect(
        Navigator.of(tester.element(find.byType(LoginPage))).canPop(), isFalse);
  });
}
