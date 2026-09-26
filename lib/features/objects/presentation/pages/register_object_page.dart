import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/object_report.dart';
import '../controllers/object_controller.dart';

class RegisterObjectPage extends StatefulWidget {
  const RegisterObjectPage({
    required this.type,
    required this.controller,
    super.key,
  });

  final ReportType type;
  final ObjectController controller;

  @override
  State<RegisterObjectPage> createState() => _RegisterObjectPageState();
}

class _RegisterObjectPageState extends State<RegisterObjectPage> {
  static const _categories = [
    'Audífonos',
    'Calculadora',
    'Carné',
    'Celular',
    'Chaqueta',
    'Documento',
    'Llaves',
    'Morral',
    'Otro',
  ];
  static const _colors = [
    'Negro',
    'Blanco',
    'Azul',
    'Rojo',
    'Gris',
    'Verde',
    'Café',
    'Otro',
  ];

  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _privateFeatureController = TextEditingController();

  String _category = _categories.first;
  String _color = _colors.first;
  DateTime _eventDate = DateTime.now();
  bool _imageSelected = false;

  bool get _isLost => widget.type == ReportType.lost;

  @override
  void dispose() {
    _brandController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _privateFeatureController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => _eventDate = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final report = ObjectReport(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      type: widget.type,
      category: _category,
      color: _color,
      brand: _brandController.text.trim().isEmpty
          ? 'Sin identificar'
          : _brandController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      eventDate: _eventDate,
      privateFeature: _privateFeatureController.text.trim(),
      status: ReportStatus.active,
      imageLabel: _imageSelected
          ? 'Imagen seleccionada en la simulación'
          : null,
    );

    final success = await widget.controller.register(report);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.controller.message ?? 'Proceso terminado.'),
      ),
    );
    if (success) {
      widget.controller.clearMessage();
      Navigator.pushReplacementNamed(context, AppRoutes.objects);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLost
        ? 'Reportar objeto perdido'
        : 'Reportar objeto encontrado';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FormIntro(isLost: _isLost),
                      const SizedBox(height: 20),
                      _ImageSelector(
                        selected: _imageSelected,
                        onPressed: () => setState(() => _imageSelected = true),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _category,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de objeto',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: _categories
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _category = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _color,
                              decoration: const InputDecoration(
                                labelText: 'Color principal',
                                prefixIcon: Icon(Icons.palette_outlined),
                              ),
                              items: _colors
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null)
                                  setState(() => _color = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Marca (opcional)',
                          prefixIcon: Icon(Icons.sell_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText:
                              'Ejemplo: audífonos negros con estuche ovalado',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        validator: _requiredField,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: _isLost
                              ? 'Lugar aproximado donde se perdió'
                              : 'Lugar donde se encontró',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                        validator: _requiredField,
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha del suceso',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(formatDate(_eventDate)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _privateFeatureController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Característica privada',
                          hintText: _isLost
                              ? 'Algo que solo el propietario conozca'
                              : 'Detalle que no se publicará abiertamente',
                          alignLabelWithHint: true,
                          prefixIcon: const Icon(Icons.shield_outlined),
                        ),
                        validator: _requiredField,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: widget.controller.isSaving ? null : _submit,
                        icon: widget.controller.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          widget.controller.isSaving
                              ? 'Guardando simulación...'
                              : 'Registrar reporte',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Este campo es obligatorio.';
    return null;
  }
}

class _FormIntro extends StatelessWidget {
  const _FormIntro({required this.isLost});

  final bool isLost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLost ? const Color(0xFFF9E9E5) : const Color(0xFFE5F0EC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            isLost
                ? Icons.search_off_rounded
                : Icons.volunteer_activism_rounded,
            color: isLost ? const Color(0xFFB4513E) : AppTheme.primary,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isLost ? 'Describe el objeto con el mayor detalle posible.' : 'Registra el objeto sin revelar públicamente sus detalles privados.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSelector extends StatelessWidget {
  const _ImageSelector({required this.selected, required this.onPressed});

  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E2DE)),
      ),
      child: Column(
        children: [
          Icon(
            selected ? Icons.image_rounded : Icons.add_photo_alternate_outlined,
            size: 48,
            color: selected ? AppTheme.primary : const Color(0xFF587068),
          ),
          const SizedBox(height: 10),
          Text(
            selected ? 'Imagen simulada seleccionada' : 'Agrega una fotografía',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'En la versión final se utilizará cámara o galería.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF587068)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(selected ? 'Cambiar imagen' : 'Seleccionar imagen'),
          ),
        ],
      ),
    );
  }
}
