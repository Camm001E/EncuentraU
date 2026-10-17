import 'dart:convert';
import 'dart:io';
import '../lib/features/matching/data/models/object_match_model.dart';
import '../lib/features/matching/domain/entities/object_match.dart';

void main() {
  final json =
      jsonDecode(File('test/fixtures/match_91.json').readAsStringSync())
          as Map<String, dynamic>;
  final match = ObjectMatchModel.fromJson(json);
  if (match.percentage != 91 ||
      match.level != MatchLevel.high ||
      match.factors.length != 9) {
    throw StateError('El contrato del caso E2E no coincide.');
  }
  stdout.writeln('Contrato remoto verificado: 91%, high, nueve factores.');
}
