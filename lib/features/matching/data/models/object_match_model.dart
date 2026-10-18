import '../../../objects/data/models/report_image_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/json_reader.dart';
import '../../../objects/domain/entities/object_report.dart';
import '../../domain/entities/object_match.dart';
import '../../domain/entities/match_page.dart';

abstract final class ObjectMatchModel {
  static double _percentage(dynamic value) {
    final result = JsonReader.number(value);
    if (result < 0 || result > ApiConstants.maxPercentage)
      throw const FormatException();
    return result;
  }

  static MatchReportSummary summary(Map<String, dynamic> json) =>
      MatchReportSummary(
          id: JsonReader.string(json['id']),
          reportType:
              JsonReader.enumeration(json['report_type'], ReportType.values),
          status: JsonReader.enumeration(json['status'], ReportStatus.values),
          objectType: JsonReader.string(json['object_type']),
          category: JsonReader.string(json['category']),
          primaryColor: JsonReader.optionalString(json['primary_color']),
          secondaryColors: JsonReader.strings(json['secondary_colors']),
          brand: JsonReader.optionalString(json['brand']),
          shape: JsonReader.optionalString(json['shape']),
          description: JsonReader.string(json['description']),
          location: JsonReader.string(json['location']),
          eventDate: JsonReader.date(json['event_date']),
          image: ReportImageModel.forReport(
              json['image'], JsonReader.string(json['id'])));
  static MatchFactor factor(Map<String, dynamic> json) => MatchFactor(
      name: JsonReader.string(json['name']),
      group: JsonReader.enumeration(json['group'], MatchFactorGroup.values),
      label: JsonReader.string(json['label']),
      weight: JsonReader.integer(json['weight']),
      evaluableWeight: _percentage(json['evaluable_weight']),
      score: _percentage(json['score']),
      status: JsonReader.enumeration(json['status'], MatchFactorStatus.values),
      explanation: JsonReader.string(json['explanation']));
  static ObjectMatch fromJson(Map<String, dynamic> json) {
    final percentage = JsonReader.integer(json['percentage']);
    _percentage(percentage);
    return ObjectMatch(
        id: JsonReader.string(json['id']),
        percentage: percentage,
        identityPercentage: _percentage(json['identity_percentage']),
        contextPercentage: _percentage(json['context_percentage']),
        evidenceCoverage: _percentage(json['evidence_coverage']),
        compatible: JsonReader.boolean(json['compatible']),
        level: JsonReader.enumeration(json['level'], MatchLevel.values),
        status: JsonReader.enumeration(json['status'], MatchStatus.values),
        factors: JsonReader.list(
            json['factors'], (value) => factor(JsonReader.object(value))),
        warnings: JsonReader.strings(json['warnings']),
        createdAt: JsonReader.date(json['created_at']),
        updatedAt: JsonReader.date(json['updated_at']),
        myReport: summary(JsonReader.object(json['my_report'])),
        candidateReport: summary(JsonReader.object(json['candidate_report'])));
  }

  static MatchPage page(Map<String, dynamic> json) => MatchPage(
      items: JsonReader.list(
          json['items'], (item) => fromJson(JsonReader.object(item))),
      total: JsonReader.integer(json['total']),
      limit: JsonReader.integer(json['limit']),
      offset: JsonReader.integer(json['offset']));
  static GeneratedMatches generated(Map<String, dynamic> json) {
    final items = JsonReader.list(
        json['items'], (item) => fromJson(JsonReader.object(item)));
    if (JsonReader.integer(json['total']) != items.length)
      throw const FormatException();
    return GeneratedMatches(
        reportId: JsonReader.string(json['report_id']), items: items);
  }
}
