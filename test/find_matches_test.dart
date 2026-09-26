import 'package:encuentra_u/features/matching/domain/usecases/find_matches.dart';
import 'package:encuentra_u/features/objects/domain/entities/object_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcula 92% para los audífonos del escenario de demostración', () {
    final reports = [
      ObjectReport(
        id: 'lost',
        type: ReportType.lost,
        category: 'Audífonos',
        color: 'Negro',
        brand: 'JBL',
        description: 'Audífonos Bluetooth negros en estuche ovalado compacto.',
        location: 'Cafetería central',
        eventDate: DateTime(2026, 9, 1),
        privateFeature: 'Marca blanca',
        status: ReportStatus.active,
      ),
      ObjectReport(
        id: 'found',
        type: ReportType.found,
        category: 'Audífonos',
        color: 'Negro',
        brand: 'JBL',
        description: 'Audífonos inalámbricos negros con estuche ovalado.',
        location: 'Cafetería central',
        eventDate: DateTime(2026, 9, 1),
        privateFeature: 'Marca clara',
        status: ReportStatus.active,
      ),
    ];

    final matches = const FindMatches()(reports);

    expect(matches, hasLength(1));
    expect(matches.first.percentage, 92);
    expect(matches.first.level, 'Coincidencia alta');
  });
}
