import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dominio independiente y data sin importaciones de presentación', () {
    for (final file in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.replaceAll('\\', '/');
      final imports = RegExp(r"""import\s+['"]([^'"]+)['"]""")
          .allMatches(file.readAsStringSync())
          .map((m) => m.group(1)!);
      if (path.contains('/domain/')) {
        expect(
            imports.where((value) =>
                value.startsWith('package:flutter') ||
                value.startsWith('package:http') ||
                value.contains('/data/') ||
                value.contains('/presentation/')),
            isEmpty,
            reason: path);
      }
      if (path.contains('/data/'))
        expect(
            imports.where((value) => value.contains('/presentation/')), isEmpty,
            reason: path);
    }
  });
  test('se retiraron las fuentes y operaciones de coincidencia locales', () {
    expect(
        File('lib/features/objects/data/datasources/object_mock_datasource.dart')
            .existsSync(),
        isFalse);
    expect(
        File('lib/features/matching/domain/usecases/find_matches.dart')
            .existsSync(),
        isFalse);
    final forbidden = [
      'Find' + 'Matches',
      'calculate' + 'Score',
      'ReportStatus.' + 'matched',
      'ReportStatus.' + 'delivered'
    ];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      for (final term in forbidden)
        expect(source.contains(term), isFalse, reason: file.path);
    }
  });
}
