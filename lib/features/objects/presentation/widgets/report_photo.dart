import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/report_image.dart';
import '../controllers/report_image_controller.dart';
import 'report_image_scope.dart';

class ReportPhoto extends StatefulWidget {
  const ReportPhoto(
      {required this.image,
      this.height = AppSizes.imagePreviewHeight,
      this.thumbnail = false,
      super.key});
  final ReportImageReference? image;
  final double height;
  final bool thumbnail;
  @override
  State<ReportPhoto> createState() => _ReportPhotoState();
}

class _ReportPhotoState extends State<ReportPhoto> {
  ReportImageController? _controller;
  ImageProvider? _provider;
  String? _key;
  bool _loading = false, _error = false;
  int _request = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = ReportImageScope.maybeOf(context);
    if (_controller != controller) {
      _controller?.removeListener(_changed);
      _key = null;
      _request++;
      _evict();
      _controller = controller;
      controller?.addListener(_changed);
    }
    _load();
  }

  @override
  void didUpdateWidget(ReportPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  void _changed() {
    if (mounted) _load(notify: true);
  }

  void _evict() {
    final old = _provider;
    _provider = null;
    if (old != null) unawaited(old.evict());
  }

  void _load({bool notify = false, bool force = false}) {
    final image = widget.image, controller = _controller;
    final next = image == null || controller == null
        ? null
        : '${controller.generation}:${image.version}:${controller.revision(image.reportId)}';
    if (!force && next == _key) return;
    _key = next;
    final request = ++_request;
    _evict();
    _error = false;
    _loading = next != null;
    if (notify) setState(() {});
    if (next == null) return;
    controller!.content(image!).then((bytes) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _provider = ResizeImage(MemoryImage(bytes),
            width: AppSizes.photoDecodeWidth, policy: ResizeImagePolicy.fit);
      });
    }, onError: (Object _) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    });
  }

  @override
  void dispose() {
    _request++;
    _controller?.removeListener(_changed);
    _evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
      label: AppStrings.reportPhoto,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          child: SizedBox(
              height: widget.height,
              width: widget.thumbnail ? widget.height : double.infinity,
              child: ColoredBox(
                  color: AppColors.foundBackground,
                  child: _provider != null
                      ? Image(
                          image: _provider!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _placeholder(error: true))
                      : _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _placeholder(error: _error)))));
  Widget _placeholder({required bool error}) => Center(
      child: widget.thumbnail
          ? Icon(error ? Icons.broken_image_outlined : Icons.photo_outlined,
              color: AppColors.primary)
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.photo_outlined,
                  color: AppColors.primary, size: AppSizes.iconLarge),
              Text(
                  error
                      ? AppStrings.photoUnavailable
                      : AppStrings.noReportPhoto,
                  textAlign: TextAlign.center),
              if (error)
                TextButton(
                    onPressed: () => _load(notify: true, force: true),
                    child: const Text(AppStrings.retry)),
            ]));
}
