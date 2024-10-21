import 'package:flutter/material.dart';

class RouteStackWidget extends StatefulWidget {
  final Widget child;

  const RouteStackWidget({
    super.key,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() => _RouteStackWidgetState();
}

class _RouteStackWidgetState extends State<RouteStackWidget> {
  static final _widgetKey = GlobalKey(debugLabel: 'Route Widget');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => Navigator.push(context, MaterialPageRoute(builder: (context) => widget.child)));
  }

  @override
  Widget build(BuildContext context) => SizedBox(key: _widgetKey);
}
