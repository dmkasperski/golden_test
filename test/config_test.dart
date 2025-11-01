import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/src/config.dart';

void main() {
  group('appBuilder', () {
    testWidgets('creates a MaterialApp widget', (WidgetTester tester) async {
      final widget = appBuilder(
        builder: (_) => const Text('Test'),
        theme: ThemeData.light(),
        supportedLocales: const [Locale('en', 'US')],
      );

      await tester.pumpWidget(widget);

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('applies the provided theme correctly', (WidgetTester tester) async {
      final customTheme = ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        useMaterial3: true,
      );

      final widget = appBuilder(
        builder: (context) {
          final theme = Theme.of(context);
          return Text(
            'Test',
            style: TextStyle(color: theme.primaryColor),
          );
        },
        theme: customTheme,
        supportedLocales: const [Locale('en', 'US')],
      );

      await tester.pumpWidget(widget);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, equals(customTheme));
    });

    testWidgets('sets supportedLocales correctly', (WidgetTester tester) async {
      const locales = [
        Locale('en', 'US'),
        Locale('es', 'ES'),
        Locale('fr', 'FR'),
      ];

      final widget = appBuilder(
        builder: (_) => const Text('Test'),
        theme: ThemeData.light(),
        supportedLocales: locales,
      );

      await tester.pumpWidget(widget);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.supportedLocales, equals(locales));
    });

    testWidgets('sets locale to first supported locale', (WidgetTester tester) async {
      const locales = [
        Locale('en', 'GB'),
        Locale('en', 'US'),
      ];

      final widget = appBuilder(
        builder: (_) => const Text('Test'),
        theme: ThemeData.light(),
        supportedLocales: locales,
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
      );

      await tester.pumpWidget(widget);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.locale, equals(locales.first));
    });

    testWidgets('sets localizationsDelegates when provided', (WidgetTester tester) async {
      final delegates = [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ];

      final widget = appBuilder(
        builder: (_) => const Text('Test'),
        theme: ThemeData.light(),
        supportedLocales: const [Locale('en', 'US')],
        localizationsDelegates: delegates,
      );

      await tester.pumpWidget(widget);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.localizationsDelegates, equals(delegates));
    });

    testWidgets('handles null localizationsDelegates', (WidgetTester tester) async {
      final widget = appBuilder(
        builder: (_) => const Text('Test'),
        theme: ThemeData.light(),
        supportedLocales: const [Locale('en', 'US')],
        localizationsDelegates: null,
      );

      await tester.pumpWidget(widget);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.localizationsDelegates, isNull);
    });

    testWidgets('wraps builder in Scaffold', (WidgetTester tester) async {
      final widget = appBuilder(
        builder: (_) => const Text('Test Content'),
        theme: ThemeData.light(),
        supportedLocales: const [Locale('en', 'US')],
      );

      await tester.pumpWidget(widget);

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('sets debugShowCheckedModeBanner to false', (WidgetTester tester) async {
      final widget = appBuilder(
        builder: (_) => const Text('Test'),
        theme: ThemeData.light(),
        supportedLocales: const [Locale('en', 'US')],
      );

      await tester.pumpWidget(widget);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('sets color to white', (WidgetTester tester) async {
      final widget = appBuilder(
        builder: (_) => const Text('Test'),
        theme: ThemeData.light(),
        supportedLocales: const [Locale('en', 'US')],
      );

      await tester.pumpWidget(widget);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.color, equals(Colors.white));
    });

    testWidgets('localeResolutionCallback returns first supported locale', (WidgetTester tester) async {
      const locales = [
        Locale('en', 'GB'),
        Locale('en', 'US'),
      ];

      final widget = appBuilder(
        builder: (_) => const Text('Test'),
        theme: ThemeData.light(),
        supportedLocales: locales,
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
      );

      await tester.pumpWidget(widget);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.localeResolutionCallback, isNotNull);

      final resolvedLocale = materialApp.localeResolutionCallback!(
        const Locale('unknown'),
        locales,
      );
      expect(resolvedLocale, equals(locales.first));
    });

    testWidgets('has onUnknownRoute handler', (WidgetTester tester) async {
      final widget = appBuilder(
        builder: (_) => const Text('Test'),
        theme: ThemeData.light(),
        supportedLocales: const [Locale('en', 'US')],
      );

      await tester.pumpWidget(widget);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.onUnknownRoute, isNotNull);
    });

    testWidgets('onUnknownRoute returns a route for unknown routes', (WidgetTester tester) async {
      final widget = appBuilder(
        builder: (_) => const Text('Test'),
        theme: ThemeData.light(),
        supportedLocales: const [Locale('en', 'US')],
      );

      await tester.pumpWidget(widget);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final route = materialApp.onUnknownRoute!(
        const RouteSettings(name: '/unknown'),
      ) as PageRouteBuilder<dynamic>;

      expect(route, isNotNull);
      expect(route, isA<PageRouteBuilder>());
      expect(route.settings.name, equals('/unknown'));
    });

    testWidgets('builder function correctly builds child widget', (WidgetTester tester) async {
      const testWidget = Text('Custom Widget Content');

      final widget = appBuilder(
        builder: (_) => testWidget,
        theme: ThemeData.light(),
        supportedLocales: const [Locale('en', 'US')],
      );

      await tester.pumpWidget(widget);

      expect(find.text('Custom Widget Content'), findsOneWidget);
    });
  });
}

