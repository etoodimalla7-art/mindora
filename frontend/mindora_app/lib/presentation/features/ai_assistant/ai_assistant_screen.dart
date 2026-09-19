import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../providers/ai_chat_providers.dart';
import 'widgets/chat_bubble.dart';

/// AI tutor chat (sections 14-17, 36-37, 43-44). Text, voice (record
/// -> upload -> transcribe -> reply) and vision (capture -> upload ->
/// OCR/vision -> reply) all funnel into the same transcript UI.
/// Includes a Socratic-mode toggle (section 37) and auto-sends a
/// topic-specific opener when handed off from a study session.
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _audioRecorder = AudioRecorder();
  bool _handledPendingPrompt = false;
  bool _isRecording = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingPrompt());
  }

  void _consumePendingPrompt() {
    if (_handledPendingPrompt) return;
    final pending = ref.read(pendingTutorPromptProvider);
    if (pending != null && pending.isNotEmpty) {
      _handledPendingPrompt = true;
      ref.read(pendingTutorPromptProvider.notifier).state = null;
      ref.read(chatControllerProvider.notifier).send(pending);
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    await ref.read(chatControllerProvider.notifier).send(text);
    _scrollToBottom();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        await ref.read(chatControllerProvider.notifier).sendVoice(path);
        _scrollToBottom();
      }
      return;
    }
    if (!await _audioRecorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is needed to ask by voice.')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/tutor_question_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(const RecordConfig(), path: _recordingPath!);
    setState(() => _isRecording = true);
  }

  Future<void> _captureImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;
    await ref.read(chatControllerProvider.notifier).sendImage(picked.path);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          AppBar(
            title: const Text('AI Tutor'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: chatState.socraticMode
                    ? 'Socratic mode on — guiding questions instead of answers'
                    : 'Turn on Socratic mode (guiding questions instead of answers)',
                icon: Icon(
                  Icons.lightbulb_rounded,
                  color: chatState.socraticMode ? theme.colorScheme.primary : null,
                ),
                onPressed: () {
                  final newValue = !chatState.socraticMode;
                  ref.read(chatControllerProvider.notifier).setSocraticMode(newValue);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(newValue ? 'Socratic mode on' : 'Socratic mode off')),
                  );
                },
              ),
            ],
          ),
          Expanded(
            child: chatState.messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'Ask about a course, paste an exercise, or use the camera '
                        'to scan a question.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: chatState.messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) => ChatBubble(message: chatState.messages[index]),
                  ),
          ),
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(Icons.fiber_manual_record_rounded, size: 14, color: theme.colorScheme.error),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Recording — tap the mic again to send', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          if (chatState.isSending)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
          if (chatState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(chatState.error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  onPressed: chatState.isSending ? null : _captureImage,
                ),
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop_circle_rounded : Icons.mic_none_rounded,
                    color: _isRecording ? theme.colorScheme.error : null,
                  ),
                  onPressed: chatState.isSending ? null : _toggleRecording,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask your AI tutor...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: chatState.isSending ? null : _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
