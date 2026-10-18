import 'package:flutter/material.dart';

/// Reports actual route and foreground visibility; does not own business timers.
class PageVisibility extends StatefulWidget {
  const PageVisibility(
      {required this.observer,
      required this.onChanged,
      required this.child,
      super.key});
  final RouteObserver<ModalRoute<dynamic>> observer;
  final ValueChanged<bool> onChanged;
  final Widget child;
  @override
  State<PageVisibility> createState() => _PageVisibilityState();
}

class _PageVisibilityState extends State<PageVisibility>
    with RouteAware, WidgetsBindingObserver {
  ModalRoute<dynamic>? _route;
  bool _routeVisible = false, _foreground = true;
  bool? _reported;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  void _report() {
    final visible = _routeVisible && _foreground;
    if (visible == _reported) return;
    _reported = visible;
    widget.onChanged(visible);
  }

  void _later() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _report();
      });
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      widget.observer.unsubscribe(this);
      _route = route;
      if (route != null) widget.observer.subscribe(this, route);
    }
    _routeVisible = route?.isCurrent ?? true;
    _later();
  }

  @override
  void didPush() {
    _routeVisible = true;
    _later();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _later();
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _report();
  }

  @override
  void didPop() {
    _routeVisible = false;
    _report();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _report();
  }

  @override
  void dispose() {
    widget.observer.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    widget.onChanged(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
