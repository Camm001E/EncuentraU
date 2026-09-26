import 'package:flutter/material.dart';

import '../../domain/entities/object_report.dart';
import '../controllers/object_controller.dart';
import '../widgets/object_report_card.dart';

enum _ObjectFilter { all, lost, found }

class ObjectsPage extends StatefulWidget {
  const ObjectsPage({required this.controller, super.key});

  final ObjectController controller;

  @override
  State<ObjectsPage> createState() => _ObjectsPageState();
}

class _ObjectsPageState extends State<ObjectsPage> {
  _ObjectFilter _filter = _ObjectFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Objetos registrados')),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final items = widget.controller.items.where((report) {
            switch (_filter) {
              case _ObjectFilter.all:
                return true;
              case _ObjectFilter.lost:
                return report.type == ReportType.lost;
              case _ObjectFilter.found:
                return report.type == ReportType.found;
            }
          }).toList();

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: _filter == _ObjectFilter.all,
                      onSelected: (_) =>
                          setState(() => _filter = _ObjectFilter.all),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Perdidos'),
                      selected: _filter == _ObjectFilter.lost,
                      onSelected: (_) =>
                          setState(() => _filter = _ObjectFilter.lost),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Encontrados'),
                      selected: _filter == _ObjectFilter.found,
                      onSelected: (_) =>
                          setState(() => _filter = _ObjectFilter.found),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text('No hay reportes en este filtro.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          return ObjectReportCard(report: items[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
