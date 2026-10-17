import 'dart:convert';
import 'dart:io';
import 'package:encuentra_u/core/constants/api_constants.dart';
import 'package:encuentra_u/features/objects/data/models/object_image_analysis_model.dart';
import 'package:encuentra_u/features/objects/domain/entities/object_report.dart';
import 'package:http/http.dart' as http;

Map<String, dynamic> matchJson() =>
    jsonDecode(File('test/fixtures/match_91.json').readAsStringSync())
        as Map<String, dynamic>;
const analysisJson = {
  'object_detected': true,
  'object_type': 'audífonos de diadema',
  'category': 'electronica',
  'primary_color': 'negro',
  'secondary_colors': ['azul'],
  'brand': null,
  'shape': 'arqueada',
  'visible_features': ['diadema ajustable'],
  'visible_text': [],
  'image_quality': 'buena',
  'confidence': 'alta',
  'requires_another_photo': false,
  'warnings': [],
};
Map<String, dynamic> reportJson(
    {String? id, String status = 'active', bool analysis = false}) {
  final match = matchJson();
  return {
    ...match['my_report'] as Map<String, dynamic>,
    if (id != null) 'id': id,
    'user_id': '11111111-1111-4111-8111-111111111111',
    'status': status,
    'private_feature': 'Detalle privado de prueba',
    'created_at': match['created_at'],
    'updated_at': match['updated_at'],
    'analysis': analysis
        ? {
            'id': '22222222-2222-4222-8222-222222222222',
            'report_id': id ?? (match['my_report'] as Map)['id'],
            'provider': 'gemini',
            'model': 'fixture-model',
            'extracted_data': analysisJson,
            'confidence': 'alta',
            'created_at': match['created_at'],
          }
        : null,
  };
}

ObjectReportDraft draft({bool analysis = false}) => ObjectReportDraft(
    reportType: ReportType.lost,
    objectType: 'audífonos de diadema',
    category: 'electronica',
    primaryColor: 'negro',
    secondaryColors: const ['azul'],
    brand: null,
    shape: 'arqueada',
    description: 'Audífonos negros',
    location: 'Cafetería central',
    eventDate: DateTime(2026, 10, 17, 12, 30),
    privateFeature: 'Detalle privado de prueba',
    imageAnalysis:
        analysis ? ObjectImageAnalysisModel.fromJson(analysisJson) : null);
http.Response jsonResponse(Object value, [int status = ApiConstants.ok]) =>
    http.Response(jsonEncode(value), status,
        headers: {'content-type': 'application/json; charset=utf-8'});
Map<String, dynamic> pageJson(List<Map<String, dynamic>> items,
        {int? total, int limit = 20, int offset = 0}) =>
    {
      'items': items,
      'total': total ?? items.length,
      'limit': limit,
      'offset': offset,
    };
