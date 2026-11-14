import 'object_match.dart';

enum VisualVerdict { consistent, different, uncertain }

class VisualReview {
  const VisualReview(
      {required this.verdict,
      required this.explanation,
      required this.agreements,
      required this.contradictions,
      required this.sourceSha256,
      required this.candidateSha256,
      this.suggestedPhoto,
      this.structuralAgreements = const []});
  final VisualVerdict verdict;
  final String explanation, sourceSha256, candidateSha256;
  final List<String> agreements, contradictions, structuralAgreements;
  final String? suggestedPhoto;
  bool appliesTo(ObjectMatch match) =>
      sourceSha256 == match.myReport.image?.sha256 &&
      candidateSha256 == match.candidateReport.image?.sha256;
}
