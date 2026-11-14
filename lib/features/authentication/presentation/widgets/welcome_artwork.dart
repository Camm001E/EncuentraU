import 'package:flutter/material.dart';

/// Decorative object cards; no simulated matches or invented activity counts.
class WelcomeArtwork extends StatelessWidget {
  const WelcomeArtwork({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget card(IconData icon, String title, String subtitle, Color fill) =>
        Container(
            width: 245,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.outlineVariant),
                boxShadow: [
                  BoxShadow(
                      color: colors.primary.withValues(alpha: .08),
                      blurRadius: 28,
                      offset: const Offset(0, 10))
                ]),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: fill, borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: colors.primary, size: 28)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant))
                  ]))
            ]));
    return ExcludeSemantics(
        child: SizedBox(
            height: 216,
            child: Stack(children: [
              Positioned(
                  right: 30,
                  top: 12,
                  child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary.withValues(alpha: .07)))),
              Positioned(
                  left: 4,
                  top: 8,
                  child: Transform.rotate(
                      angle: -.055,
                      child: card(
                          Icons.headphones_rounded,
                          'Cada objeto importa',
                          'Una historia por continuar',
                          colors.primaryContainer))),
              Positioned(
                  right: 4,
                  bottom: 8,
                  child: Transform.rotate(
                      angle: .035,
                      child: card(Icons.key_rounded, 'Volver a encontrar',
                          'Empieza por conectar', colors.secondaryContainer))),
              Align(
                  alignment: Alignment.center,
                  child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 4)),
                      child: Icon(Icons.sync_alt_rounded,
                          color: colors.onPrimary, size: 22))),
            ])));
  }
}
