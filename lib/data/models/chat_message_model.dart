/// Mô hình tin nhắn trong cuộc hội thoại AI chat.
class ChatMessageModel {
  const ChatMessageModel({
    required this.role, // 'user' | 'assistant' | 'system'
    required this.content,
    required this.timestamp,
    this.langCode,
  });

  final String role;
  final String content;
  final DateTime timestamp;
  final String? langCode;

  /// Chuyển từ JSON sang model.
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      langCode: json['langCode'] as String?,
    );
  }

  /// Chuyển từ model sang JSON.
  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      if (langCode != null) 'langCode': langCode,
    };
  }
}
