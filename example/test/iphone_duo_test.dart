import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:golden_test_example/screens/inbox_screen.dart';
import 'package:material_ui/material_ui.dart';

import 'fixtures/inbox.dart';

/// An iPhone Duo golden shows the device closed, half open like a book and
/// like a laptop, and open flat, side by side in one image.
///
/// The inbox is laid out for the device, so these are what the screens should
/// look like.
void main() {
  Widget withInbox(BuildContext context, Widget navigator) =>
      BlocProvider<InboxCubit>(
        create: (_) => InboxCubit(sampleMessages),
        child: navigator,
      );

  Future<void> Function(WidgetTester) tapInMessage(String tooltip) =>
      (tester) async {
        // While the inbox shows the list alone, the message opens as a page.
        if (find.byTooltip(tooltip).evaluate().isEmpty) {
          await tester.tap(find.text('Your order has shipped'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byTooltip(tooltip));
        await tester.pumpAndSettle();
      };

  Future<void> deleteAll(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Delete all'));
    await tester.pumpAndSettle();
  }

  // The reference: an inbox prepared for iPhone Duo, in an app that publishes
  // the fold with a plugin such as foldable.
  group('reference', () {
    final duo = Device.iphoneDuo(reportsDisplayFeatures: true);

    void inboxGolden(
      String name, {
      List<Brightness> themes = const [Brightness.light],
      Future<void> Function(WidgetTester)? action,
    }) => goldenTest(
      name: 'iPhone Duo - Inbox$name',
      supportedDevices: [duo],
      supportedLocales: [const Locale('en')],
      supportedThemes: themes,
      navigatorBuilder: withInbox,
      builder: (_) => const InboxScreen(),
      action: action,
    );

    inboxGolden('', themes: [Brightness.light, Brightness.dark]);
    inboxGolden(' delete dialog', action: deleteAll);
    inboxGolden(' reply sheet', action: tapInMessage('Reply'));
    inboxGolden(' archived snackbar', action: tapInMessage('Archive'));
    inboxGolden(' more menu', action: tapInMessage('More'));
  });

  // The same inbox in an app without such a plugin: Flutter reports no fold
  // on iOS, so neither the layout nor the dialog can keep clear of it.
  group('fold not reported', () {
    goldenTest(
      name: 'iPhone Duo - Inbox delete dialog, fold not reported',
      supportedDevices: [Device.iphoneDuo()],
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      navigatorBuilder: withInbox,
      builder: (_) => const InboxScreen(),
      action: deleteAll,
    );
  });
}
