import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../data/dm_providers.dart';
import '../../domain/dm_models.dart';

class DmListScreen extends ConsumerWidget {
  const DmListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final convsAsync = ref.watch(dmConversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: convsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Erreur : $e', textAlign: TextAlign.center),
          ),
        ),
        data: (convs) {
          if (convs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Aucune conversation',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Ouvre un groupe d\'étude et clique sur 👥\n'
                      'pour discuter avec un membre en privé.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dmConversationsProvider),
            child: ListView.separated(
              itemCount: convs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _DmTile(conv: convs[i]),
            ),
          );
        },
      ),
    );
  }
}

class _DmTile extends StatelessWidget {
  const _DmTile({required this.conv});
  final DirectConversation conv;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(conv.peer.displayName);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
        backgroundImage:
            conv.peer.avatarUrl != null ? NetworkImage(conv.peer.avatarUrl!) : null,
        child: conv.peer.avatarUrl == null
            ? Text(initials,
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600))
            : null,
      ),
      title: Text(conv.peer.displayName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight:
                conv.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
          )),
      subtitle: conv.lastMessagePreview != null
          ? Text(
              conv.lastMessagePreview!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight:
                    conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
              ),
            )
          : null,
      trailing: conv.unreadCount > 0
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            )
          : null,
      onTap: () => context.push('/messages/${conv.id}'),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
