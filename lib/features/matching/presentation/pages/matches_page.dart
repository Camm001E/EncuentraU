import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../objects/presentation/controllers/object_controller.dart';
import '../../domain/entities/object_match.dart';
import '../../domain/usecases/find_matches.dart';

class MatchesPage extends StatelessWidget {
  const MatchesPage({
    required this.controller,
    required this.findMatches,
    super.key,
  });

  final ObjectController controller;
  final FindMatches findMatches;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coincidencias inteligentes')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final matches = findMatches(controller.items);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const _SimulationNotice(),
              const SizedBox(height: 18),
              Text(
                '${matches.length} coincidencias encontradas',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (matches.isEmpty)
                const Card(
                  elevation: 0,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Registra objetos perdidos y encontrados para generar comparaciones.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...matches.map(
                  (match) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MatchCard(match: match),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SimulationNotice extends StatelessWidget {
  const _SimulationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: Color(0xFF8A5B00)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Prototipo: los porcentajes se calculan localmente con tipo, color, marca, lugar, fecha y palabras coincidentes.',
              style: TextStyle(color: Color(0xFF674500)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final ObjectMatch match;

  @override
  Widget build(BuildContext context) {
    final percentage = match.percentage;
    final color = percentage >= 90
        ? AppTheme.primary
        : percentage >= 70
            ? const Color(0xFFC28316)
            : const Color(0xFF66736F);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.level,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${match.lostObject.category} · ${match.lostObject.color}',
                        style: const TextStyle(color: Color(0xFF587068)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                color: color,
                backgroundColor: const Color(0xFFE4EAE7),
              ),
            ),
            const SizedBox(height: 16),
            _ComparedObject(
              label: 'Objeto perdido',
              description: match.lostObject.description,
              location: match.lostObject.location,
            ),
            const Divider(height: 24),
            _ComparedObject(
              label: 'Objeto encontrado',
              description: match.foundObject.description,
              location: match.foundObject.location,
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => _showClaimDialog(context, match),
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Solicitar verificación'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClaimDialog(BuildContext context, ObjectMatch match) async {
    final answerController = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Validar propiedad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe una característica que solamente el propietario debería conocer.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: answerController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Respuesta privada',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (answerController.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
    answerController.dispose();

    if (accepted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solicitud simulada enviada al administrador para revisión.',
          ),
        ),
      );
    }
  }
}

class _ComparedObject extends StatelessWidget {
  const _ComparedObject({
    required this.label,
    required this.description,
    required this.location,
  });

  final String label;
  final String description;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(description),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: Color(0xFF587068),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                location,
                style: const TextStyle(color: Color(0xFF587068)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
