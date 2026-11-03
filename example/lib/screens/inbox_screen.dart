import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:golden_test_example/widgets/list_detail_layout.dart';
import 'package:material_ui/material_ui.dart';

class Message {
  const Message({
    required this.subject,
    required this.sender,
    required this.body,
  });

  final String subject;
  final String sender;
  final String body;
}

class InboxCubit extends Cubit<List<Message>> {
  InboxCubit(super.messages);

  void deleteAll() => emit(const []);
}

/// The inbox, prepared for iPhone Duo: the open message next to the list
/// when the screen has room, split at the fold when the device is half open,
/// dialogs and sheets in the right half, and snackbars in their own pane.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<InboxCubit>().state;
    final bool showsDetail =
        ListDetailLayout.panesOf(context) != ListDetailPanes.single;
    final int selected = messages.isEmpty
        ? 0
        : _selected.clamp(0, messages.length - 1);

    return ListDetailLayout(
      list: Scaffold(
        appBar: AppBar(
          title: const Text('Inbox'),
          actions: [
            IconButton(
              tooltip: 'Delete all',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => showDialog<void>(
                context: context,
                anchorPoint: contentAnchorOf(context),
                builder: (_) => const DeleteMessagesDialog(),
              ),
            ),
          ],
        ),
        body: ListView(
          children: [
            for (final (index, message) in messages.indexed)
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(message.subject),
                selected: showsDetail && index == selected,
                onTap: () {
                  if (showsDetail) {
                    setState(() => _selected = index);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MessageScreen(message: message),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
      detail: messages.isEmpty
          ? const Scaffold(body: Center(child: Text('No messages')))
          : MessageScreen(message: messages[selected], showsBackButton: false),
    );
  }
}

class MessageScreen extends StatelessWidget {
  const MessageScreen({
    super.key,
    required this.message,
    this.showsBackButton = true,
  });

  final Message message;
  final bool showsBackButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showsBackButton,
        actions: [
          IconButton(
            tooltip: 'Reply',
            icon: const Icon(Icons.reply),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              anchorPoint: controlsAnchorOf(context),
              // Half open like a laptop, the sheet gets only the half below
              // the fold. A sheet that is not scroll controlled takes at most
              // 9/16 of that, too little for the replies.
              isScrollControlled: true,
              builder: (_) => ReplySheet(message: message),
            ),
          ),
          IconButton(
            tooltip: 'Archive',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Message archived'))),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'forward', child: Text('Forward')),
              PopupMenuItem(value: 'unread', child: Text('Mark as unread')),
              PopupMenuItem(value: 'block', child: Text('Block sender')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(message.subject, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: Text(message.sender.characters.first),
                ),
                const SizedBox(width: 12),
                Text(message.sender, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 24),
            Text(message.body, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class ReplySheet extends StatelessWidget {
  const ReplySheet({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reply to ${message.sender}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            for (final reply in const ['Thanks!', 'Sounds good', 'Call me'])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(reply),
              ),
          ],
        ),
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
