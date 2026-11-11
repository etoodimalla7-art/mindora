import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/dm_providers.dart';
import '../../data/dm_repository.dart';
import '../../domain/dm_models.dart';

class DmChatScreen extends ConsumerStatefulWidget {
  const DmChatScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  ConsumerState<DmChatScreen> createState() => _DmChatScreenState();
}

class _DmChatScreenState extends ConsumerState<DmChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _inputFocus = FocusNode();

  final List<DirectMessage> _messages = [];
  StreamSubscription<DmSocketEvent>? _wsSub;
  bool _socketConnected = false;
  bool _sending = false;
  String? _loadError;

  String? _myUserId;

  @override
  void initState() {
    super.initState();
    final session = ref.read(authControllerProvider).session;
    _myUserId = session?.user.id;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadHistory();
    _connectSocket();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await ref
          .read(dmRepositoryProvider)
          .listMessages(widget.conversationId);
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
        .read(dmRepositoryProvider)
        .connectSocket(widget.conversationId)
        .listen(
      (event) {
        if (!mounted) return;
        if (event is DmSocketMessage) {
          if (_messages.any((m) => m.id == event.message.id)) return;
          setState(() {
            _messages.add(event.message);
            _socketConnected = true;
          });
          _scrollToBottom();
        } else if (event is DmSocketError) {
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
          .read(dmRepositoryProvider)
          .postMessage(widget.conversationId, text);
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
    final convAsync = ref.watch(dmDetailProvider(widget.conversationId));

    return Scaffold(
      appBar: AppBar(
        title: convAsync.maybeWhen(
          data: (c) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.peer.displayName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(
                children: [
                  Icon(
                    _socketConnected ? Icons.circle : Icons.circle_outlined,
                    size: 8,
                    color: _socketConnected ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _socketConnected ? 'connecté' : 'connexion...',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
          orElse: () => const Text('Chat'),
        ),
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
                      child: Text(_loadError!,
                          style: TextStyle(
                              color: theme.colorScheme.onErrorContainer)),
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
                      child: Text(
                        'Aucun message. Dis bonjour !',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final m = _messages[i];
                        final mine =
                            _myUserId != null && m.senderId == _myUserId;
                        return _DmBubble(message: m, isMine: mine);
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
}

class _DmBubble extends StatelessWidget {
  const _DmBubble({required this.message, required this.isMine});
  final DirectMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = isMine
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final fg = isMine
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isMine ? 14 : 2),
                bottomRight: Radius.circular(isMine ? 2 : 14),
              ),
            ),
            child: Text(
              message.content,
              style: theme.textTheme.bodyMedium?.copyWith(color: fg),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(
              _fmtTime(message.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
