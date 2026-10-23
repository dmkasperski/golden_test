import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:golden_test_example/screens/inbox_screen.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  goldenTest(
    name: 'navigatorBuilder',
    supportedLocales: [const Locale('en')],
    supportedThemes: [Brightness.light],
    navigatorBuilder: (context, navigator) => BlocProvider<InboxCubit>(
      create: (_) => InboxCubit(const [
        'Your order has shipped',
        'Meeting moved to 3 PM',
        'Welcome to the team',
      ]),
      child: navigator!,
    ),
    builder: (_) => const InboxScreen(),
    action: (tester) async {
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Delete 3 messages?'), findsOneWidget);
    },
  );
}
