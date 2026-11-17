import '../../../../core/network/json_reader.dart';
import '../../domain/entities/visual_review.dart';

abstract final class VisualReviewModel {
  static VisualReview fromJson(Map<String, dynamic> json) {
    final data = JsonReader.object(json['comparison']);
    return VisualReview(
        verdict: JsonReader.enumeration(data['verdict'], VisualVerdict.values),
        explanation: JsonReader.string(data['explanation']),
        agreements: JsonReader.strings(data['agreements']),
        contradictions: JsonReader.strings(data['contradictions']),
        structuralAgreements: data.containsKey('structural_agreements')
            ? JsonReader.strings(data['structural_agreements'])
            : const [],
        suggestedPhoto: JsonReader.optionalString(data['suggested_photo']),
        sourceSha256: JsonReader.string(json['source_sha256']),
        candidateSha256: JsonReader.string(json['candidate_sha256']));
  }
}
