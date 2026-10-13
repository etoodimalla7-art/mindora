import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../data/chat_providers.dart';

class ConversationsDrawer extends ConsumerWidget {
  const ConversationsDrawer({
    super.key,
    required this.onOpenConversation,
    required this.onNewConversation,
  });

  final void Function(String id) onOpenConversation;
  final VoidCallback onNewConversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final conversationsAsync = ref.watch(conversationsProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'MINDORA AI',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'New conversation',
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onNewConversation();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: conversationsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Could not load conversations.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No conversations yet.\nStart chatting!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final c = list[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.chat_bubble_outline, size: 18),
                        title: Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          DateFormat.MMMd().add_Hm().format(c.updatedAt),
                          style: theme.textTheme.labelSmall,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          onOpenConversation(c.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
