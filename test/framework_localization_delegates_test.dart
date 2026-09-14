import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late MaterialLocalizations material;
  late WidgetsLocalizations widgets;
  late CupertinoLocalizations cupertino;

  goldenTestDifferenceTolerance(0.05);

  goldenTest(
    name: 'FrameworkLocalizationDelegates',
    supportedLocales: [const Locale('es')],
    supportedThemes: [Brightness.light],
    supportedDevices: [const Device.iphone15Pro()],
    builder: (_) => Builder(
      builder: (context) {
        material = MaterialLocalizations.of(context);
        widgets = WidgetsLocalizations.of(context);
        cupertino = CupertinoLocalizations.of(context);
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('material.backButtonTooltip: ${material.backButtonTooltip}'),
              Text('material.okButtonLabel: ${material.okButtonLabel}'),
              Text('cupertino.todayLabel: ${cupertino.todayLabel}'),
              Text('widgets.textDirection: ${widgets.textDirection}'),
            ],
          ),
        );
      },
    ),
    tearDown: (_) async {
      expect(material.backButtonTooltip, 'Atrás');
      expect(material.okButtonLabel, 'ACEPTAR');
      expect(cupertino.todayLabel, 'Hoy');
      expect(widgets.textDirection, TextDirection.ltr);
    },
  );
}
