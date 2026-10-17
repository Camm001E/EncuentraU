import '../../../../core/domain/page.dart';
import 'object_match.dart';

class MatchPage extends Page<ObjectMatch> {
  const MatchPage(
      {required super.items,
      required super.total,
      required super.limit,
      required super.offset});
}
