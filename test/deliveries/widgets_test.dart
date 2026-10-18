import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:encuentra_u/core/constants/app_strings.dart';
import 'package:encuentra_u/core/theme/app_theme.dart';
import 'package:encuentra_u/features/deliveries/data/models/delivery_model.dart';
import 'package:encuentra_u/features/deliveries/domain/entities/delivery.dart';
import 'package:encuentra_u/features/deliveries/presentation/widgets/delivery_widgets.dart';
import 'package:encuentra_u/features/deliveries/presentation/pages/deliveries_page.dart';
import 'support.dart';

Widget app(Widget child, {double scale = 1, bool reduced = false}) =>
    MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
            textScaler: TextScaler.linear(scale), disableAnimations: reduced),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
void main() {
  for (final status in DeliveryStatus.values)
    testWidgets('línea de tiempo ${status.name} y semántica', (t) async {
      final semantics = t.ensureSemantics();
      final c = deliveryController(TestDeliveries());
      await t.pumpWidget(app(
          DeliveryContent(
              delivery: DeliveryModel.fromJson(deliveryJson(status: status)),
              controller: c),
          reduced: true));
      await t.pumpAndSettle();
      expect(find.byType(DeliveryTimeline), findsOneWidget);
      expect(find.text(AppStrings.custodianConfirmed), findsOneWidget);
      if (status == DeliveryStatus.completed)
        expect(find.text(AppStrings.deliveryClosedMessage), findsOneWidget);
      expect(t.takeException(), isNull);
      semantics.dispose();
      await t.pumpWidget(const SizedBox.shrink());
      c.dispose();
    });
  for (final role in ['claimant', 'custodian'])
    testWidgets('confirmación correcta para $role', (t) async {
      final c = deliveryController(TestDeliveries());
      await t.pumpWidget(app(DeliveryContent(
          delivery: DeliveryModel.fromJson(deliveryJson(role: role)),
          controller: c)));
      expect(
          find.text(role == 'claimant'
              ? AppStrings.confirmClaimantDelivery
              : AppStrings.confirmCustodianDelivery),
          findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
      c.dispose();
    });
  for (final width in [360.0, 390.0, 768.0, 1200.0])
    testWidgets('responsive $width con texto ampliado', (t) async {
      await t.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final c = deliveryController(TestDeliveries());
      await t.pumpWidget(app(
          DeliveryContent(
              delivery: DeliveryModel.fromJson(
                  deliveryJson(status: DeliveryStatus.completed)),
              controller: c),
          scale: 2,
          reduced: true));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      c.dispose();
    });
  testWidgets('formulario disputa rechaza motivo corto', (t) async {
    await t.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
            body: DeliveryDecisionDialog(DeliveryDecision.dispute))));
    await t.tap(
        find.widgetWithText(FilledButton, AppStrings.reportDeliveryProblem));
    await t.pumpAndSettle();
    expect(find.text(AppStrings.disputeValidation), findsOneWidget);
  });
  testWidgets('lista administrativa incluye filtros y datos reales', (t) async {
    final c = deliveryController(TestDeliveries(), admin: true);
    await t.pumpWidget(MaterialApp(
        theme: AppTheme.light, home: DeliveriesPage(controller: c)));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('delivery-delivery-1')), findsOneWidget);
    expect(find.byType(DeliveryStatusPill), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
}
