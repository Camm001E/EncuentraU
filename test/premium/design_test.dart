import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:encuentra_u/core/theme/app_theme.dart';
import 'package:encuentra_u/core/theme/app_semantic_colors.dart';

double contrast(Color a, Color b) =>
    (math.max(a.computeLuminance(), b.computeLuminance()) + .05) /
    (math.min(a.computeLuminance(), b.computeLuminance()) + .05);

void main() {
  test('arquitectura: una sola paleta, sin colores directos en pantallas', () {
    const colorFiles = {
      'app_colors.dart',
      'app_theme.dart',
      'app_semantic_colors.dart',
      'app_gradients.dart'
    };
    final violations = <String>[];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final name = file.uri.pathSegments.last;
      final text = file.readAsStringSync();
      if (!colorFiles.contains(name) &&
          RegExp(r'Color\s*\(\s*0x|Color\.from(?:ARGB|RGBO)|\bColors\.(?!transparent\b)')
              .hasMatch(text)) violations.add(file.path);
      if (file.path.replaceAll('\\', '/').contains('/features/') &&
          RegExp(r'\bAppColors\.').hasMatch(text)) violations.add(file.path);
    }
    expect(violations, isEmpty);
  });
  test('contraste AA en textos y todos los estados semánticos', () {
    final theme = AppTheme.light;
    final scheme = theme.colorScheme;
    expect(
        contrast(scheme.onSurface, scheme.surface), greaterThanOrEqualTo(4.5));
    expect(contrast(scheme.onSurfaceVariant, scheme.surface),
        greaterThanOrEqualTo(4.5));
    expect(
        contrast(scheme.onPrimary, scheme.primary), greaterThanOrEqualTo(4.5));
    expect(
        contrast(theme.inputDecorationTheme.enabledBorder!.borderSide.color,
            scheme.surface),
        greaterThanOrEqualTo(3));
    final semantic = theme.extension<AppSemanticColors>()!;
    for (final tone in [
      semantic.lost,
      semantic.found,
      semantic.high,
      semantic.possible,
      semantic.low,
      semantic.information,
      semantic.warning,
      semantic.success,
      semantic.error
    ]) {
      expect(contrast(tone.foreground, tone.background),
          greaterThanOrEqualTo(4.5));
    }
  });
  test('botones tienen objetivos táctiles de 48 px', () {
    final style = AppTheme.light.filledButtonTheme.style!;
    expect(style.minimumSize!.resolve({})!.height, greaterThanOrEqualTo(48));
  });
}
