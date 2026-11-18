import 'package:flutter/foundation.dart';

import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/datasources/demo_chat_datasource.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/repositories/ai_repository.dart';

enum ChatState { idle, streaming, done, error }

class ChatProvider extends ChangeNotifier {
  final IAiRepository repository;

  final List<ChatMessageModel> _messages = [];
  ChatState _state = ChatState.idle;
  String _errorMessage = '';
  String _streamingText = '';
  bool _isConnected = false;

  ChatProvider({
    IAiRepository? customRepository,
    String? serverUrl,
  }) : repository = customRepository ??
            AiRepositoryImpl(
              remoteDataSource: serverUrl != null && serverUrl.isNotEmpty
                  ? ChatRemoteDataSource(baseUrl: serverUrl)
                  : null,
              demoDataSource: DemoChatDataSource(),
            ) {
    _isConnected = repository.isConnected;
    _addSystemMessage();
  }

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  ChatState get state => _state;
  String get errorMessage => _errorMessage;
  String get streamingText => _streamingText;
  bool get isConnected => _isConnected;
  bool get isStreaming => _state == ChatState.streaming;

  void _addSystemMessage() {
    _messages.add(
      ChatMessageModel(
        role: 'system',
        content: '',
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Gửi tin nhắn người dùng và bắt đầu stream phản hồi AI.
  Future<void> sendMessage({
    required String content,
    required String langCode,
  }) async {
    if (content.trim().isEmpty || _state == ChatState.streaming) return;

    _state = ChatState.streaming;
    _errorMessage = '';
    _streamingText = '';
    notifyListeners();

    final userMsg = ChatMessageModel(
      role: 'user',
      content: content.trim(),
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    notifyListeners();

    try {
      final aiMsg = ChatMessageModel(
        role: 'assistant',
        content: '',
        timestamp: DateTime.now(),
      );
      _messages.add(aiMsg);
      notifyListeners();

      await for (final chunk in repository.sendMessageStream(
        messages: List.of(_messages),
        langCode: langCode,
      )) {
        _streamingText += chunk;

        // Cập nhật tin nhắn assistant cuối cùng
        _messages[_messages.length - 1] = ChatMessageModel(
          role: 'assistant',
          content: _streamingText,
          timestamp: DateTime.now(),
        );
        notifyListeners();
      }

      _state = ChatState.done;
    } catch (e) {
      _state = ChatState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Xóa toàn bộ lịch sử chat và bắt đầu phiên mới.
  void clearChat() {
    _messages.clear();
    _streamingText = '';
    _errorMessage = '';
    _state = ChatState.idle;
    _addSystemMessage();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    _state = ChatState.idle;
    notifyListeners();
  }
}
