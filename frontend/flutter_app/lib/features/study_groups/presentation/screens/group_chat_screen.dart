import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../data/study_group_providers.dart';
import '../../data/study_group_repository.dart';
import '../../domain/study_group_models.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  const GroupChatScreen({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _inputFocus = FocusNode();

  final List<GroupMessage> _messages = [];
  StreamSubscription<GroupSocketEvent>? _wsSub;
  bool _socketConnected = false;
  int _presenceCount = 0;
  bool _sending = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadHistory();
    _connectSocket();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await ref
          .read(studyGroupRepositoryProvider)
          .listMessages(widget.groupId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(history);
        _loadError = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) setState(() => _loadError = 'Erreur : $e');
    }
  }

  void _connectSocket() {
    _wsSub?.cancel();
    _wsSub = ref
        .read(studyGroupRepositoryProvider)
        .connectSocket(widget.groupId)
        .listen(
      (event) {
        if (!mounted) return;
        if (event is GroupSocketMessage) {
          if (_messages.any((m) => m.id == event.message.id)) return;
          setState(() {
            _messages.add(event.message);
            _socketConnected = true;
          });
          _scrollToBottom();
        } else if (event is GroupSocketPresence) {
          setState(() {
            _presenceCount = event.count;
            _socketConnected = true;
          });
        } else if (event is GroupSocketError) {
          setState(() => _socketConnected = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _socketConnected = false);
      },
      onDone: () {
        if (mounted) setState(() => _socketConnected = false);
      },
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _input.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    _scrollToBottom();
    try {
      final sent = await ref
          .read(studyGroupRepositoryProvider)
          .postMessage(widget.groupId, text);
      if (mounted && !_messages.any((m) => m.id == sent.id)) {
        setState(() => _messages.add(sent));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Envoi impossible : $e')));
        _input.text = text;
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.maybeWhen(
          data: (g) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(
                children: [
                  Icon(
                    _socketConnected ? Icons.circle : Icons.circle_outlined,
                    size: 8,
                    color: _socketConnected ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _presenceCount > 0
                        ? '$_presenceCount en ligne'
                        : (_socketConnected ? 'connecté' : 'connexion...'),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
          orElse: () => const Text('Groupe'),
        ),
        actions: [
          IconButton(
            tooltip: 'Voir les membres',
            icon: const Icon(Icons.people_outline),
            onPressed: () => context.push('/groups/${widget.groupId}/members'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_loadError != null)
              Container(
                color: theme.colorScheme.errorContainer,
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _loadError!,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadHistory,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          'Aucun message. Sois le premier à écrire !',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final m = _messages[i];
                        final showDate = i == 0 ||
                            !_sameDay(_messages[i - 1].createdAt, m.createdAt);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showDate) _DateDivider(date: m.createdAt),
                            _MessageBubble(message: m),
                          ],
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _inputFocus,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Écris un message...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    String label;
    if (d == today) {
      label = 'Aujourd\'hui';
    } else if (d == today.subtract(const Duration(days: 1))) {
      label = 'Hier';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final GroupMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.userName ?? 'Membre',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(message.content, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
