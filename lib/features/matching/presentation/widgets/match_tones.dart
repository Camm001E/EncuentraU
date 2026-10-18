import 'package:flutter/material.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../domain/entities/object_match.dart';

SemanticTone matchTone(BuildContext context, MatchLevel level) =>
    switch (level) {
      MatchLevel.high => AppSemanticColors.of(context).high,
      MatchLevel.possible => AppSemanticColors.of(context).possible,
      MatchLevel.low => AppSemanticColors.of(context).low,
    };
IconData factorIcon(MatchFactorStatus status) => switch (status) {
      MatchFactorStatus.match => Icons.check_circle_outline,
      MatchFactorStatus.partial => Icons.adjust_rounded,
      MatchFactorStatus.different => Icons.close_rounded,
      MatchFactorStatus.unknown => Icons.help_outline_rounded,
    };
SemanticTone factorTone(BuildContext context, MatchFactorStatus status) =>
    switch (status) {
      MatchFactorStatus.match => AppSemanticColors.of(context).success,
      MatchFactorStatus.partial => AppSemanticColors.of(context).warning,
      MatchFactorStatus.different => AppSemanticColors.of(context).error,
      MatchFactorStatus.unknown => AppSemanticColors.of(context).low,
    };
