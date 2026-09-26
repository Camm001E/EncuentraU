enum ReportType { lost, found }

enum ReportStatus { active, matched, delivered }

extension ReportTypeLabel on ReportType {
  String get label => this == ReportType.lost ? 'Perdido' : 'Encontrado';
}

extension ReportStatusLabel on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.active:
        return 'Activo';
      case ReportStatus.matched:
        return 'Con coincidencia';
      case ReportStatus.delivered:
        return 'Entregado';
    }
  }
}

class ObjectReport {
  const ObjectReport({
    required this.id,
    required this.type,
    required this.category,
    required this.color,
    required this.brand,
    required this.description,
    required this.location,
    required this.eventDate,
    required this.privateFeature,
    required this.status,
    this.imageLabel,
  });

  final String id;
  final ReportType type;
  final String category;
  final String color;
  final String brand;
  final String description;
  final String location;
  final DateTime eventDate;
  final String privateFeature;
  final ReportStatus status;
  final String? imageLabel;
}
