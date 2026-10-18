import 'package:flutter/material.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_gradients.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/presentation/app_motion.dart';
import '../../../objects/presentation/widgets/report_badges.dart';
import '../../../objects/presentation/widgets/report_photo.dart';
import '../../domain/entities/object_match.dart';

class MatchComparisonScene extends StatelessWidget {
  const MatchComparisonScene({required this.match, super.key});
  final ObjectMatch match;
  Widget photo(MatchReportSummary report, String label) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spacingRegular),
            child: Wrap(
                spacing: AppSizes.spacingSmall,
                runSpacing: AppSizes.spacingSmall,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [Text(label), ReportTypeBadge(report.reportType)])),
        ReportPhoto(
            image: report.image,
            height: AppSizes.comparisonPhotoHeight,
            fit: BoxFit.contain,
            label: label),
      ]);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      decoration: BoxDecoration(
          gradient: AppGradients.comparison,
          borderRadius: BorderRadius.circular(AppSizes.radiusXLarge)),
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppSizes.photoComparisonBreakpoint;
        final connector = Semantics(
            label: AppStrings.compareConnector,
            child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacingRegular),
                child: Icon(Icons.join_inner_rounded,
                    size: AppSizes.comparisonConnectorSize,
                    color: Theme.of(context).colorScheme.primary)));
        final photos = wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: photo(match.myReport, AppStrings.myReport)),
                connector,
                Expanded(
                    child: photo(
                        match.candidateReport, AppStrings.candidatePhotoLabel))
              ])
            : Column(children: [
                photo(match.myReport, AppStrings.myReport),
                connector,
                photo(match.candidateReport, AppStrings.candidatePhotoLabel)
              ]);
        if (AppMotion.reduced(context)) return photos;
        return Stack(children: [
          photos,
          Positioned.fill(
              child: IgnorePointer(
                  child: ExcludeSemantics(
                      child: RepaintBoundary(
                          child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: AppDurations.scan,
                              builder: (context, progress, _) => CustomPaint(
                                  painter: PhotoScanPainter(
                                      progress,
                                      Theme.of(context).colorScheme.primary,
                                      wide)))))))
        ]);
      }));
}

class PhotoScanPainter extends CustomPainter {
  PhotoScanPainter(this.progress, this.color, this.horizontal);
  final double progress;
  final Color color;
  final bool horizontal;
  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = AppSizes.scanStroke;
    if (horizontal) {
      final x = size.width * progress;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    } else {
      final y = size.height * progress;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(PhotoScanPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.horizontal != horizontal;
}
