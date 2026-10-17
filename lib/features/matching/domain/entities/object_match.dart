import '../../../objects/domain/entities/object_report.dart';

enum MatchLevel { high, possible, low }

enum MatchStatus { pending, accepted, rejected }

enum MatchFactorGroup { identity, context }

enum MatchFactorStatus { match, partial, different, unknown }

/// Deliberately independent of the owner's full report and raw analysis.
class MatchReportSummary {
  const MatchReportSummary(
      {required this.id,
      required this.reportType,
      required this.status,
      required this.objectType,
      required this.category,
      required this.description,
      required this.location,
      required this.eventDate,
      this.primaryColor,
      this.secondaryColors = const [],
      this.brand,
      this.shape});
  final String id, objectType, category, description, location;
  final ReportType reportType;
  final ReportStatus status;
  final DateTime eventDate;
  final String? primaryColor, brand, shape;
  final List<String> secondaryColors;
}

class MatchFactor {
  const MatchFactor(
      {required this.name,
      required this.group,
      required this.label,
      required this.weight,
      required this.evaluableWeight,
      required this.score,
      required this.status,
      required this.explanation});
  final String name, label, explanation;
  final MatchFactorGroup group;
  final MatchFactorStatus status;
  final int weight;
  final double evaluableWeight, score;
}

class ObjectMatch {
  const ObjectMatch(
      {required this.id,
      required this.percentage,
      required this.identityPercentage,
      required this.contextPercentage,
      required this.evidenceCoverage,
      required this.compatible,
      required this.level,
      required this.status,
      required this.factors,
      required this.warnings,
      required this.createdAt,
      required this.updatedAt,
      required this.myReport,
      required this.candidateReport});
  final String id;
  final int percentage;
  final double identityPercentage, contextPercentage, evidenceCoverage;
  final bool compatible;
  final MatchLevel level;
  final MatchStatus status;
  final List<MatchFactor> factors;
  final List<String> warnings;
  final DateTime createdAt, updatedAt;
  final MatchReportSummary myReport, candidateReport;
}

class GeneratedMatches {
  const GeneratedMatches({required this.reportId, required this.items});
  final String reportId;
  final List<ObjectMatch> items;
}
