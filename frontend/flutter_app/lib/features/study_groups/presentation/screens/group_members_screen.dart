import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../data/study_group_providers.dart';
import '../../domain/study_group_models.dart';

class GroupMembersScreen extends ConsumerWidget {
  const GroupMembersScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.maybeWhen(
          data: (g) => Text('Membres • ${g.memberCount}'),
          orElse: () => const Text('Membres'),
        ),
      ),
      body: FutureBuilder<List<StudyGroupMember>>(
        future: ref.read(studyGroupRepositoryProvider).listMembers(groupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: AppSpacing.md),
                    Text('Erreur : ${snapshot.error}',
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          final members = snapshot.data ?? const <StudyGroupMember>[];
          if (members.isEmpty) {
            return const Center(child: Text('Aucun membre.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: members.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _MemberTile(member: members[i]),
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});
  final StudyGroupMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(member.displayName);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
        backgroundImage: member.avatarUrl != null
            ? NetworkImage(member.avatarUrl!)
            : null,
        child: member.avatarUrl == null
            ? Text(
                initials,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      title: Text(member.displayName,
          style: theme.textTheme.titleSmall),
      subtitle: Text(
        'Membre depuis ${_fmtDate(member.joinedAt)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: Icon(
        Icons.chat_bubble_outline,
        size: 20,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      // TODO 13.7: onTap → open DM with this member
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  static String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays < 1) return 'aujourd\'hui';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
