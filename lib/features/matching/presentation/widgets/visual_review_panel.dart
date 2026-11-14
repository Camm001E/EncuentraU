import 'package:flutter/material.dart';
import '../../domain/entities/object_match.dart';
import '../../domain/entities/visual_review.dart';
import '../controllers/match_controller.dart';

extension VisualVerdictLabel on VisualVerdict {
  String get label => switch (this) {
        VisualVerdict.consistent => 'Coinciden detalles visibles',
        VisualVerdict.different => 'Hay diferencias visibles',
        VisualVerdict.uncertain => 'Hace falta comprobar detalles',
      };
  IconData get icon => switch (this) {
        VisualVerdict.consistent => Icons.check_circle_outline,
        VisualVerdict.different => Icons.difference_outlined,
        VisualVerdict.uncertain => Icons.photo_camera_outlined,
      };
}

class VisualReviewPanel extends StatelessWidget {
  const VisualReviewPanel(
      {required this.match,
      required this.controller,
      this.compact = false,
      super.key});
  final ObjectMatch match;
  final MatchController controller;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final review = controller.visualReviewFor(match);
    final busy = controller.reviewing.contains(match.id);
    final error = controller.reviewErrors[match.id];
    if (compact && review == null && !busy && error == null)
      return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final color = review?.verdict == VisualVerdict.different
        ? colors.error
        : review?.verdict == VisualVerdict.uncertain
            ? colors.tertiary
            : colors.primary;
    final hasPhotos =
        match.myReport.image != null && match.candidateReport.image != null;
    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outlineVariant)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(review?.verdict.icon ?? Icons.compare_outlined, color: color),
            const SizedBox(width: 12),
            Expanded(
                child: Text(review?.verdict.label ?? 'Revisa las dos fotos',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: color))),
          ]),
          if (compact && review != null) ...[
            const SizedBox(height: 8),
            const Text(
                'La similitud visual no confirma que sea el mismo ejemplar.'),
          ],
          if (busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Comparando detalles de ambas fotos...'),
          ],
          if (!compact) ...[
            const SizedBox(height: 12),
            Text(review?.explanation ??
                (hasPhotos
                    ? 'Compara formas, cierres, marcas y otros detalles antes de continuar.'
                    : 'Se necesita una foto en cada reporte para comparar los objetos.')),
            if (review != null) ...[
              if (review.structuralAgreements.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Detalles que sustentan la similitud',
                    style: Theme.of(context).textTheme.titleSmall),
                for (final text in review.structuralAgreements)
                  _Evidence(icon: Icons.compare_outlined, text: text),
              ],
              for (final text in review.agreements
                  .where((text) => !review.structuralAgreements.contains(text)))
                _Evidence(icon: Icons.add, text: text),
              for (final text in review.contradictions)
                _Evidence(icon: Icons.remove, text: text),
              if (review.suggestedPhoto case final photo?) ...[
                const SizedBox(height: 12),
                Text('Foto que puede ayudar',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(photo),
              ],
            ],
            const SizedBox(height: 12),
            Text(
                'La similitud visual orienta la revisión; no confirma la propiedad. '
                'El puntaje de compatibilidad se muestra por separado.',
                style: Theme.of(context).textTheme.bodySmall),
            if (controller.canReview && hasPhotos) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                  onPressed: busy ? null : () => controller.review(match),
                  icon: const Icon(Icons.compare_outlined),
                  label: Text(review == null
                      ? 'Comparar fotos con IA'
                      : 'Volver a comparar')),
            ],
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error, style: TextStyle(color: colors.error))
          ],
        ]));
  }
}

class _Evidence extends StatelessWidget {
  const _Evidence({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text))
      ]));
}
