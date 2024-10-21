import 'package:flutter/material.dart';
import 'package:golden_test/src/utils/route_stack_widget.dart';

/// Allows to simulate a widget in route stack.
Widget simulateRouteStack(Widget child) => RouteStackWidget(child: child);
