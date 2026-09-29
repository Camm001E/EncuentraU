import '../../domain/entities/object_image_analysis.dart';

abstract final class ObjectFormOptions {
  static const List<String> categories = [
    'Audífonos',
    'Calculadora',
    'Carné',
    'Celular',
    'Chaqueta',
    'Documento',
    'Llaves',
    'Morral',
    'Otro',
  ];

  static const List<String> colors = [
    'Negro',
    'Blanco',
    'Azul',
    'Rojo',
    'Gris',
    'Verde',
    'Café',
    'Otro',
  ];

  static String categoryFromAnalysis(
    ObjectImageAnalysis analysis,
  ) {
    final objectType = _normalize(
      analysis.objectType ?? '',
    );

    if (objectType.contains('audif')) {
      return 'Audífonos';
    }

    if (objectType.contains('calcul')) {
      return 'Calculadora';
    }

    if (objectType.contains('carne') || objectType.contains('carnet')) {
      return 'Carné';
    }

    if (objectType.contains('celular') ||
        objectType.contains('telefono') ||
        objectType.contains('movil')) {
      return 'Celular';
    }

    if (objectType.contains('chaqueta')) {
      return 'Chaqueta';
    }

    if (objectType.contains('document') || objectType.contains('cedula')) {
      return 'Documento';
    }

    if (objectType.contains('llave')) {
      return 'Llaves';
    }

    if (objectType.contains('morral') ||
        objectType.contains('mochila') ||
        objectType.contains('bolso')) {
      return 'Morral';
    }

    switch (analysis.category) {
      case 'llaves':
        return 'Llaves';
      case 'documentos':
        return 'Documento';
      case 'bolsos':
        return 'Morral';
      case 'ropa':
        return 'Chaqueta';
      default:
        return 'Otro';
    }
  }

  static String colorFromAnalysis(String? color) {
    final normalizedColor = _normalize(color ?? '');

    for (final option in colors) {
      if (option == 'Otro') {
        continue;
      }

      if (normalizedColor.contains(_normalize(option))) {
        return option;
      }
    }

    if (normalizedColor.contains('marron')) {
      return 'Café';
    }

    return 'Otro';
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }
}
