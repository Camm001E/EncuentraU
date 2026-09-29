import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/object_controller.dart';
import '../widgets/object_report_card.dart';
import '../widgets/report_action_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.controller, super.key});

  final ObjectController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('EncuentraU'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'EncuentraU',
              applicationVersion: 'Prototipo 0.1.0',
              applicationLegalese:
                  'Simulación local construida con Clean Architecture.',
            ),
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Acerca del prototipo',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: controller.loadObjects,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const _WelcomeBanner(),
                const SizedBox(height: 22),
                Text(
                  '¿Qué deseas reportar?',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      ReportActionCard(
                        icon: Icons.search_off_rounded,
                        title: 'Perdí un objeto',
                        description:
                            'Registra sus características y ubicación.',
                        color: const Color(0xFFB4513E),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.registerLost,
                        ),
                      ),
                      ReportActionCard(
                        icon: Icons.volunteer_activism_rounded,
                        title: 'Encontré un objeto',
                        description: 'Ayuda a que regrese con su propietario.',
                        color: AppTheme.primary,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.registerFound,
                        ),
                      ),
                    ];

                    if (constraints.maxWidth >= 760) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 14),
                          Expanded(child: cards[1]),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        cards[0],
                        const SizedBox(height: 12),
                        cards[1],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.objects),
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('Ver reportes'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.matches),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Coincidencias'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Actividad reciente',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.objects),
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (controller.status == ObjectViewStatus.loading)
                  const Center(child: CircularProgressIndicator())
                else
                  ...controller.items.take(3).map(
                        (report) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ObjectReportCard(
                            report: report,
                            compact: true,
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, estudiante',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Reporta, compara y recupera objetos dentro de la universidad.',
                  style: TextStyle(color: Color(0xFFDDEFE9)),
                ),
              ],
            ),
          ),
          SizedBox(width: 14),
          Icon(Icons.school_rounded, color: Colors.white, size: 48),
        ],
      ),
    );
  }
}
