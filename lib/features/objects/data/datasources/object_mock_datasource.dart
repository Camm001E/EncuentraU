import '../models/object_report_model.dart';
import '../../domain/entities/object_report.dart';

class ObjectMockDataSource {
  ObjectMockDataSource()
      : _objects = [
          ObjectReportModel(
            id: 'lost-001',
            type: ReportType.lost,
            category: 'Audífonos',
            color: 'Negro',
            brand: 'JBL',
            description:
                'Audífonos Bluetooth negros en estuche ovalado compacto.',
            location: 'Cafetería central',
            eventDate: DateTime(2026, 9, 1),
            privateFeature: 'El audífono izquierdo tiene una marca blanca.',
            status: ReportStatus.matched,
            imageLabel: 'Referencia de audífonos perdidos',
          ),
          ObjectReportModel(
            id: 'found-001',
            type: ReportType.found,
            category: 'Audífonos',
            color: 'Negro',
            brand: 'JBL',
            description: 'Audífonos inalámbricos negros con estuche ovalado.',
            location: 'Cafetería central',
            eventDate: DateTime(2026, 9, 1),
            privateFeature: 'Se observa una pequeña marca clara en un lado.',
            status: ReportStatus.matched,
            imageLabel: 'Foto simulada de audífonos encontrados',
          ),
          ObjectReportModel(
            id: 'found-002',
            type: ReportType.found,
            category: 'Calculadora',
            color: 'Gris',
            brand: 'Casio',
            description: 'Calculadora científica encontrada en un salón.',
            location: 'Bloque 3',
            eventDate: DateTime(2026, 9, 3),
            privateFeature: 'Tiene unas iniciales escritas en la tapa.',
            status: ReportStatus.active,
            imageLabel: 'Foto simulada de calculadora',
          ),
          ObjectReportModel(
            id: 'lost-002',
            type: ReportType.lost,
            category: 'Morral',
            color: 'Azul',
            brand: 'Nike',
            description: 'Morral deportivo azul con dos bolsillos.',
            location: 'Biblioteca',
            eventDate: DateTime(2026, 9, 4),
            privateFeature: 'Tiene un llavero pequeño en la cremallera.',
            status: ReportStatus.active,
            imageLabel: 'Referencia de morral perdido',
          ),
        ];

  final List<ObjectReportModel> _objects;

  Future<List<ObjectReportModel>> getObjects() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<ObjectReportModel>.unmodifiable(_objects.reversed);
  }

  Future<void> registerObject(ObjectReportModel report) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _objects.add(report);
  }
}
