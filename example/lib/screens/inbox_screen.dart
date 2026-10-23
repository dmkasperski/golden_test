import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class InboxCubit extends Cubit<List<String>> {
  InboxCubit(super.messages);

  void deleteAll() => emit(const []);
}

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<InboxCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            tooltip: 'Delete all',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const DeleteMessagesDialog(),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final message in messages)
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: Text(message),
            ),
        ],
      ),
    );
  }
}

class DeleteMessagesDialog extends StatelessWidget {
  const DeleteMessagesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<InboxCubit>().state.length;

    return AlertDialog(
      title: Text('Delete $count messages?'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            context.read<InboxCubit>().deleteAll();
            Navigator.of(context).pop();
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
