import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/media/image_picker_helper.dart';
import '../../data/chat_providers.dart';
import '../widgets/chat_bubble.dart';
import 'conversations_drawer.dart';
import '../../../../core/design/widgets/mindora_app_bar.dart';
import '../../../../core/voice/voice_input_button.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _inputFocus = FocusNode();

  PickedImage? _pendingImage;

  @override
  void dispose() {
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
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text;
    final image = _pendingImage;
    if (text.trim().isEmpty && image == null) return;

    _input.clear();
    setState(() => _pendingImage = null);
    await ref.read(chatControllerProvider.notifier).send(
          text,
          imageBase64: image?.base64,
          imageMimeType: image?.mimeType,
        );
    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ImagePickerHelper.pick(source: source);
    if (picked == null) return;
    if (picked.isTooLarge) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Image trop lourde (max 5 Mo).')),
      );
      return;
    }
    setState(() => _pendingImage = picked);
    _inputFocus.requestFocus();
  }

  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              subtitle: const Text('Photographie un exercice ou une page'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source != null) await _pickImage(source);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);

    ref.listen(chatControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
        controller.clearError();
      }
    });

    return Scaffold(
      drawer: ConversationsDrawer(
        onOpenConversation: (id) =>
            ref.read(chatControllerProvider.notifier).loadConversation(id),
        onNewConversation: () =>
            ref.read(chatControllerProvider.notifier).startNew(),
      ),
      appBar: const MindoraAppBar(showWordmark: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.messages.isEmpty
                  ? _EmptyState(onExampleTap: (text) {
                      _input.text = text;
                      _inputFocus.requestFocus();
                    })
                  : ListView.builder(
                      controller: _scroll,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      itemCount: state.messages.length +
                          (state.sending ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i >= state.messages.length) {
                          return const _TypingIndicator();
                        }
                        return ChatBubble(message: state.messages[i]);
                      },
                    ),
            ),
            if (_pendingImage != null)
              _PendingImagePreview(
                image: _pendingImage!,
                onRemove: () => setState(() => _pendingImage = null),
              ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                  IconButton(
                    onPressed: state.sending ? null : _showImageSourceSheet,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    tooltip: 'Joindre une image',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _inputFocus,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask anything, or about your course...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  VoiceInputButton(
                    onTranscribed: (text) {
                      _input.text = text;
                      _input.selection = TextSelection.fromPosition(
                        TextPosition(offset: text.length),
                      );
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: state.sending ? null : _send,
                    icon: state.sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
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

class _PendingImagePreview extends StatelessWidget {
  const _PendingImagePreview({required this.image, required this.onRemove});
  final PickedImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              Uint8List.fromList(image.bytes),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  image.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${(image.sizeBytes / 1024).toStringAsFixed(0)} Ko — '
                  'prête à envoyer',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close),
            tooltip: 'Retirer',
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onExampleTap});
  final void Function(String) onExampleTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final examples = const [
      'Explain the derivative of x² step by step.',
      'What does my course say about differential equations?',
      'Give me 3 practice questions on integration by parts.',
      'sqrt(144) + 8*3',
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Icon(Icons.auto_awesome,
            size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Ask me anything',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'I can explain concepts, solve problems, and answer questions '
          'about the documents you uploaded. You can also send a photo '
          'of an exercise — I will read it and solve it.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Text('Try one of these',
            style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.md),
        for (final ex in examples) ...[
          _ExampleTile(text: ex, onTap: () => onExampleTap(ex)),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _ExampleTile extends StatelessWidget {
  const _ExampleTile({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.arrow_forward, size: 16,
                color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(text, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.auto_awesome,
                size: 16, color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 40,
              height: 16,
              child: _Dots(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final phase = (_c.value + i * 0.2) % 1.0;
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2)
                .clamp(0.2, 1.0);
            return Opacity(
              opacity: opacity,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
