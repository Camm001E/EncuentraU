import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../constants/app_durations.dart';
import '../../constants/app_gradients.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../theme/app_semantic_colors.dart';
import '../app_motion.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = AppSizes.brandMarkSize, super.key});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
      label: AppStrings.appName,
      image: true,
      child: DecoratedBox(
          decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge)),
          child: SizedBox.square(
              dimension: size,
              child: CustomPaint(
                  painter:
                      _BrandPainter(Theme.of(context).colorScheme.primary)))));
}

class _BrandPainter extends CustomPainter {
  _BrandPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .075;
    final rect = Rect.fromLTWH(size.width * .22, size.height * .18,
        size.width * .56, size.height * .58);
    canvas.drawArc(rect, -.25 * math.pi, 1.48 * math.pi, false, paint);
    final path = Path()
      ..moveTo(size.width * .47, size.height * .37)
      ..lineTo(size.width * .47, size.height * .53)
      ..quadraticBezierTo(size.width * .47, size.height * .67, size.width * .61,
          size.height * .67)
      ..quadraticBezierTo(size.width * .73, size.height * .67, size.width * .73,
          size.height * .53)
      ..lineTo(size.width * .73, size.height * .43);
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(size.width * .74, size.height * .23),
        size.width * .045, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BrandPainter oldDelegate) => oldDelegate.color != color;
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({this.compact = false, super.key});
  final bool compact;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < AppSizes.ringSize)
          return Align(
              alignment: Alignment.centerLeft,
              child: BrandMark(
                  size:
                      compact ? AppSizes.touchTarget : AppSizes.brandMarkSize));
        return Row(mainAxisSize: MainAxisSize.min, children: [
          ExcludeSemantics(
              child: BrandMark(
                  size:
                      compact ? AppSizes.touchTarget : AppSizes.brandMarkSize)),
          const SizedBox(width: AppSizes.spacingRegular),
          Flexible(
              child: Text(AppStrings.appName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: AppSizes.titleLetterSpacing))),
        ]);
      });
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
      {required this.title,
      this.eyebrow,
      this.subtitle,
      this.trailing,
      super.key});
  final String title;
  final String? eyebrow, subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingMedium),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (eyebrow != null)
          Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spacingSmall),
              child: Text(eyebrow!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: AppSizes.eyebrowLetterSpacing,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary))),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Semantics(
                  header: true,
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleLarge))),
          if (trailing != null) trailing!,
        ]),
        if (subtitle != null)
          Padding(
              padding: const EdgeInsets.only(top: AppSizes.spacingSmall),
              child: Text(subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
      ]));
}

class StatusPill extends StatelessWidget {
  const StatusPill(
      {required this.label, required this.icon, required this.tone, super.key});
  final String label;
  final IconData icon;
  final SemanticTone tone;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall)),
      child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingRegular,
              vertical: AppSizes.spacingSmall),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            ExcludeSemantics(
                child: Icon(icon,
                    size: AppSizes.iconSmall, color: tone.foreground)),
            const SizedBox(width: AppSizes.spacingTiny),
            Flexible(
                child: Text(label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: tone.foreground, fontWeight: FontWeight.w700))),
          ])));
}

class InformationPanel extends StatelessWidget {
  const InformationPanel(
      {required this.child, this.tone, this.icon, super.key});
  final Widget child;
  final SemanticTone? tone;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final colors = tone ?? AppSemanticColors.of(context).information;
    return DecoratedBox(
        decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge)),
        child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacingMedium),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (icon != null) ...[
                Icon(icon, color: colors.foreground),
                const SizedBox(width: AppSizes.spacingRegular)
              ],
              Expanded(
                  child: DefaultTextStyle.merge(
                      style: TextStyle(color: colors.foreground),
                      child: child)),
            ])));
  }
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction(
      {required this.label,
      required this.onPressed,
      this.icon = Icons.arrow_forward_rounded,
      this.busy = false,
      super.key});
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;
  @override
  Widget build(BuildContext context) => FilledButton(
      onPressed: busy ? null : onPressed,
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            busy
                ? SizedBox.square(
                    dimension: AppSizes.iconMedium,
                    child: CircularProgressIndicator(
                        strokeWidth: AppSizes.strokeWidth,
                        color: Theme.of(context).colorScheme.primary))
                : Icon(icon),
            const SizedBox(width: AppSizes.spacingSmall),
            Flexible(child: Text(label, textAlign: TextAlign.center))
          ]));
}

class SecondaryAction extends StatelessWidget {
  const SecondaryAction(
      {required this.label,
      required this.onPressed,
      this.icon = Icons.arrow_forward_rounded,
      super.key});
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) => OutlinedButton(
      onPressed: onPressed,
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: AppSizes.spacingSmall),
            Flexible(child: Text(label, textAlign: TextAlign.center))
          ]));
}

class ContentWidth extends StatelessWidget {
  const ContentWidth(
      {required this.child,
      this.maxWidth = AppSizes.contentMaxWidth,
      super.key});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth), child: child));
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({this.count = 3, super.key});
  final int count;
  @override
  Widget build(BuildContext context) => Semantics(
      label: AppStrings.loadingContent,
      child: ExcludeSemantics(
          child: TweenAnimationBuilder<double>(
              tween: Tween(begin: AppMotion.reduced(context) ? 1 : 0, end: 1),
              duration: AppMotion.duration(context, AppDurations.reveal),
              builder: (context, value, child) =>
                  Opacity(opacity: value, child: child),
              child: Column(children: [
                for (var i = 0; i < count; i++)
                  Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSizes.spacingMedium),
                      child: Container(
                          height: AppSizes.skeletonHeight,
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLarge)),
                          padding: const EdgeInsets.all(AppSizes.spacingMedium),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                  widthFactor: .65,
                                  child: Container(
                                      height: AppSizes.skeletonLine,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant)))))
              ]))));
}
