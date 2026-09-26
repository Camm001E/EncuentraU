import '../lib/features/matching/domain/usecases/find_matches.dart';
import '../lib/features/objects/domain/entities/object_report.dart';

void main() {
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

  final result = const FindMatches()(reports);
  if (result.length != 1 || result.first.percentage != 92) {
    throw StateError('La coincidencia esperada era 92%.');
  }

  print('Verificación correcta: ${result.first.percentage}%');
}
