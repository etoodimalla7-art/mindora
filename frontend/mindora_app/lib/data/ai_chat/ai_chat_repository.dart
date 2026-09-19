import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class ChatSendResult {
  const ChatSendResult({
    required this.conversationId,
    required this.reply,
    required this.toolsUsed,
    this.sourceDocumentId,
    this.stylePreferences = const {},
  });
  final String conversationId;
  final String reply;
  final List<String> toolsUsed;
  final String? sourceDocumentId;
  final Map<String, dynamic> stylePreferences;
}

class VoiceSendResult {
  const VoiceSendResult({
    required this.conversationId, required this.transcript, required this.reply,
    required this.toolsUsed, this.sourceDocumentId, this.audioReplyBase64,
  });
  final String conversationId;
  final String transcript;
  final String reply;
  final List<String> toolsUsed;
  final String? sourceDocumentId;
  final String? audioReplyBase64;
}

class VisionSendResult {
  const VisionSendResult({
    required this.conversationId, required this.extractedQuestion, required this.usedVisionModel,
    required this.reply, required this.toolsUsed, this.sourceDocumentId,
  });
  final String conversationId;
  final String extractedQuestion;
  final bool usedVisionModel;
  final String reply;
  final List<String> toolsUsed;
  final String? sourceDocumentId;
}

class AiChatRepository {
  AiChatRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<ChatSendResult> sendMessage({
    required String message, String? conversationId, bool? socraticOverride,
  }) async {
    final response = await _apiClient.dio.post('/ai/chat', data: {
      'message': message,
      if (conversationId != null) 'conversation_id': conversationId,
      if (socraticOverride != null) 'socratic_override': socraticOverride,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return ChatSendResult(
      conversationId: data['conversation_id'] as String,
      reply: data['reply'] as String,
      toolsUsed: (data['tools_used'] as List).cast<String>(),
      sourceDocumentId: data['source_document_id'] as String?,
      stylePreferences: (data['style_preferences'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Section 43: uploads a recorded clip; the backend transcribes it
  /// and runs the transcript through the same tutor pipeline as typed
  /// text.
  Future<VoiceSendResult> sendVoiceMessage({required String filePath, String? conversationId}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'recording.m4a'),
      if (conversationId != null) 'conversation_id': conversationId,
    });
    final response = await _apiClient.dio.post('/ai/voice', data: formData);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return VoiceSendResult(
      conversationId: data['conversation_id'] as String,
      transcript: data['transcript'] as String,
      reply: data['reply'] as String,
      toolsUsed: (data['tools_used'] as List).cast<String>(),
      sourceDocumentId: data['source_document_id'] as String?,
      audioReplyBase64: data['audio_reply_base64'] as String?,
    );
  }

  /// Section 44: uploads a photo of a question; the backend OCRs it
  /// (falling back to a vision-capable model if OCR finds nothing) and
  /// runs the extracted question through the same tutor pipeline.
  Future<VisionSendResult> sendVisionMessage({required String filePath, String? conversationId}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'question.jpg'),
      if (conversationId != null) 'conversation_id': conversationId,
    });
    final response = await _apiClient.dio.post('/ai/vision', data: formData);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return VisionSendResult(
      conversationId: data['conversation_id'] as String,
      extractedQuestion: data['extracted_question'] as String,
      usedVisionModel: data['used_vision_model'] as bool,
      reply: data['reply'] as String,
      toolsUsed: (data['tools_used'] as List).cast<String>(),
      sourceDocumentId: data['source_document_id'] as String?,
    );
  }
}
