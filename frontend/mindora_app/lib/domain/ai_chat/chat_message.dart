/// A message in the local chat transcript. The backend persists its own
/// copy (with role/content/tool_trace) — this is the client-side view
/// model the chat screen renders from.
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.toolsUsed = const [],
    this.sourceDocumentId,
  });

  final String role; // "user" | "assistant"
  final String content;
  final List<String> toolsUsed;
  final String? sourceDocumentId;

  bool get isFromCourseMaterial => toolsUsed.contains('course_retriever');
}
