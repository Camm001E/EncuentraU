import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/object_match.dart';

extension MatchLevelLabel on MatchLevel {
  String get label => switch (this) {
        MatchLevel.high => AppStrings.highMatch,
        MatchLevel.possible => AppStrings.possibleMatch,
        MatchLevel.low => AppStrings.lowMatch
      };
}

extension MatchStatusLabel on MatchStatus {
  String get label => switch (this) {
        MatchStatus.pending => AppStrings.pending,
        MatchStatus.accepted => AppStrings.accepted,
        MatchStatus.rejected => AppStrings.rejected
      };
}

extension MatchGroupLabel on MatchFactorGroup {
  String get label => this == MatchFactorGroup.identity
      ? AppStrings.identity
      : AppStrings.context;
}

extension FactorStatusLabel on MatchFactorStatus {
  String get label => switch (this) {
        MatchFactorStatus.match => AppStrings.matchingFactor,
        MatchFactorStatus.partial => AppStrings.partialFactor,
        MatchFactorStatus.different => AppStrings.differentFactor,
        MatchFactorStatus.unknown => AppStrings.unknownFactor
      };
}
