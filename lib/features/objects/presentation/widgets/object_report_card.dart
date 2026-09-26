import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/object_report.dart';

class ObjectReportCard extends StatelessWidget {
  const ObjectReportCard({
    required this.report,
    this.compact = false,
    super.key,
  });

  final ObjectReport report;
  final bool compact;

  IconData get _categoryIcon {
    final category = report.category.toLowerCase();
    if (category.contains('audífono')) return Icons.headphones_rounded;
    if (category.contains('calculadora')) return Icons.calculate_rounded;
    if (category.contains('morral') || category.contains('mochila')) {
      return Icons.backpack_rounded;
    }
    if (category.contains('celular')) return Icons.smartphone_rounded;
    if (category.contains('llave')) return Icons.key_rounded;
    return Icons.inventory_2_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isLost = report.type == ReportType.lost;
    final typeColor = isLost
        ? const Color(0xFFB4513E)
        : const Color(0xFF176B52);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 46 : 58,
              height: compact ? 46 : 58,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F0EC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_categoryIcon, color: const Color(0xFF176B52)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        report.category,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          report.type.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    report.description,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _Detail(
                        icon: Icons.palette_outlined,
                        text: '${report.color} · ${report.brand}',
                      ),
                      _Detail(
                        icon: Icons.location_on_outlined,
                        text: report.location,
                      ),
                      _Detail(
                        icon: Icons.calendar_today_outlined,
                        text: formatDate(report.eventDate),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF587068)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Color(0xFF587068), fontSize: 13),
        ),
      ],
    );
  }
}
