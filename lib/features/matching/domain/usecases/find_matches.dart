import '../../../objects/domain/entities/object_report.dart';
import '../entities/object_match.dart';

class FindMatches {
  const FindMatches();

  List<ObjectMatch> call(List<ObjectReport> reports) {
    final lostObjects = reports.where((item) => item.type == ReportType.lost);
    final foundObjects = reports.where((item) => item.type == ReportType.found);
    final matches = <ObjectMatch>[];

    for (final lost in lostObjects) {
      for (final found in foundObjects) {
        final percentage = _calculateScore(lost, found);
        if (percentage >= 30) {
          matches.add(
            ObjectMatch(
              lostObject: lost,
              foundObject: found,
              percentage: percentage,
            ),
          );
        }
      }
    }

    matches.sort((a, b) => b.percentage.compareTo(a.percentage));
    return matches;
  }

  int _calculateScore(ObjectReport lost, ObjectReport found) {
    var score = 0.0;

    if (_same(lost.category, found.category)) score += 25;
    if (_same(lost.color, found.color)) score += 15;
    if (lost.brand.trim().isNotEmpty && _same(lost.brand, found.brand)) {
      score += 15;
    }
    if (_similarPlace(lost.location, found.location)) score += 20;

    final difference = lost.eventDate.difference(found.eventDate).inDays.abs();
    if (difference <= 1) {
      score += 10;
    } else if (difference <= 3) {
      score += 6;
    } else if (difference <= 7) {
      score += 3;
    }

    score += _textSimilarity(lost.description, found.description) * 15;
    return score.clamp(0, 100).floor();
  }

  bool _same(String first, String second) {
    return first.trim().toLowerCase() == second.trim().toLowerCase();
  }

  bool _similarPlace(String first, String second) {
    final normalizedFirst = first.trim().toLowerCase();
    final normalizedSecond = second.trim().toLowerCase();
    return normalizedFirst == normalizedSecond ||
        normalizedFirst.contains(normalizedSecond) ||
        normalizedSecond.contains(normalizedFirst);
  }

  double _textSimilarity(String first, String second) {
    final firstTokens = _tokens(first);
    final secondTokens = _tokens(second);
    if (firstTokens.isEmpty || secondTokens.isEmpty) return 0;

    final intersection = firstTokens.intersection(secondTokens).length;
    final union = firstTokens.union(secondTokens).length;
    return intersection / union;
  }

  Set<String> _tokens(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúüñ ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toSet();
  }
}
