import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/ai_config.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/datasources/demo_chat_datasource.dart';
import '../../data/datasources/gemini_direct_datasource.dart';
import '../../data/datasources/openrouter_datasource.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/question_model.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/repositories/ai_repository.dart';

enum ChatState { idle, streaming, done, error }

/// Provider AI đang sử dụng
enum AiProvider { gemini, openrouter, offline }

class ChatProvider extends ChangeNotifier {
  IAiRepository _repository;
  final DemoChatDataSource demoDataSource;
  final String? _serverUrl;

  final List<ChatMessageModel> _messages = [];
  ChatState _state = ChatState.idle;
  String _errorMessage = '';
  String _streamingText = '';
  bool _isConnected = false;
  bool _usedFallback = false;
  String? _currentQuestionId;
  QuestionModel? _activeQuestion;
  int? _userChoiceIndex;
  String _lastUserContent = '';
  String _lastLangCode = 'vi';
  int _requestId = 0;
  bool _disposed = false;

  // Gemini
  String _apiKey = '';

  // OpenRouter
  String _openRouterKey = '';
  String _openRouterModel = AiConfig.defaultOpenRouterModel;

  // Lựa chọn provider
  AiProvider _aiProvider = AiProvider.gemini;

  final bool _hasCustomRepository;

  ChatProvider({
    IAiRepository? customRepository,
    String? serverUrl,
    DemoChatDataSource? demoDataSource,
  })  : _serverUrl = serverUrl,
        _hasCustomRepository = customRepository != null,
        demoDataSource = demoDataSource ?? const DemoChatDataSource(),
        _repository = customRepository ??
            AiRepositoryImpl(
              remoteDataSource: serverUrl != null && serverUrl.isNotEmpty
                  ? ChatRemoteDataSource(baseUrl: serverUrl)
                  : null,
              demoDataSource: demoDataSource ?? const DemoChatDataSource(),
            ) {
    _isConnected = _repository.isConnected;
    _addSystemMessage();
    unawaited(_initSettings());
  }

  IAiRepository get repository => _repository;
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  ChatState get state => _state;
  String get errorMessage => _errorMessage;
  String get streamingText => _streamingText;
  bool get isConnected => _isConnected;
  bool get hasApiKey => _apiKey.trim().isNotEmpty;
  String get apiKey => _apiKey;

  // OpenRouter getters
  bool get hasOpenRouterKey => _openRouterKey.trim().isNotEmpty;
  String get openRouterKey => _openRouterKey;
  String get openRouterModel => _openRouterModel;

  // Provider getter
  AiProvider get aiProvider => _aiProvider;

  bool get usedFallback => _usedFallback;
  bool get isStreaming => _state == ChatState.streaming;
  bool get hasConversation => _messages.any((m) => m.role != 'system');

  /// Khởi tạo tất cả settings từ SharedPreferences khi mở app.
  Future<void> _initSettings() async {
    // Khi dùng customRepository (testing), không override repository
    if (_hasCustomRepository) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Gemini Key
      final savedGemini = prefs.getString(AiConfig.prefsApiKey);
      if (savedGemini != null && savedGemini.trim().isNotEmpty) {
        _apiKey = savedGemini.trim();
      } else if (AiConfig.envApiKey.isNotEmpty) {
        _apiKey = AiConfig.envApiKey;
      }

      // OpenRouter Key + Model
      final savedOrKey = prefs.getString(AiConfig.prefsOpenRouterKey);
      if (savedOrKey != null && savedOrKey.trim().isNotEmpty) {
        _openRouterKey = savedOrKey.trim();
      }
      final savedOrModel = prefs.getString(AiConfig.prefsOpenRouterModel);
      if (savedOrModel != null && savedOrModel.trim().isNotEmpty) {
        _openRouterModel = savedOrModel.trim();
      }

      // AI Provider đã chọn
      final savedProvider = prefs.getString(AiConfig.prefsAiProvider);
      _aiProvider = _parseProvider(savedProvider);

      _rebuildRepository();
      _notify();
    } catch (_) {}
  }

  AiProvider _parseProvider(String? raw) {
    switch (raw) {
      case 'openrouter':
        return AiProvider.openrouter;
      case 'offline':
        return AiProvider.offline;
      default:
        return AiProvider.gemini;
    }
  }

  String _providerKey(AiProvider p) {
    switch (p) {
      case AiProvider.openrouter:
        return 'openrouter';
      case AiProvider.offline:
        return 'offline';
      case AiProvider.gemini:
        return 'gemini';
    }
  }

  /// Đổi AI Provider và rebuild repository.
  Future<void> setAiProvider(AiProvider provider) async {
    _aiProvider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AiConfig.prefsAiProvider, _providerKey(provider));
    _rebuildRepository();
    _notify();
  }

  /// Cập nhật và lưu Gemini API Key.
  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_apiKey.isEmpty) {
      await prefs.remove(AiConfig.prefsApiKey);
    } else {
      await prefs.setString(AiConfig.prefsApiKey, _apiKey);
    }
    _rebuildRepository();
    _notify();
  }

  /// Cập nhật và lưu OpenRouter API Key + Model.
  Future<void> setOpenRouterConfig({
    required String key,
    required String model,
  }) async {
    _openRouterKey = key.trim();
    _openRouterModel =
        model.trim().isEmpty ? AiConfig.defaultOpenRouterModel : model.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_openRouterKey.isEmpty) {
      await prefs.remove(AiConfig.prefsOpenRouterKey);
    } else {
      await prefs.setString(AiConfig.prefsOpenRouterKey, _openRouterKey);
    }
    await prefs.setString(AiConfig.prefsOpenRouterModel, _openRouterModel);
    _rebuildRepository();
    _notify();
  }

  void _rebuildRepository() {
    // Nếu đang dùng customRepository (testing), không override
    if (_hasCustomRepository) return;
    final serverUrl = _serverUrl;
    _repository = AiRepositoryImpl(
      openRouterDataSource:
          (_aiProvider == AiProvider.openrouter && _openRouterKey.isNotEmpty)
              ? OpenRouterDataSource(
                  apiKey: _openRouterKey,
                  model: _openRouterModel,
                )
              : null,
      directDataSource:
          (_aiProvider == AiProvider.gemini && _apiKey.isNotEmpty)
              ? GeminiDirectDataSource(apiKey: _apiKey)
              : null,
      remoteDataSource: (serverUrl != null && serverUrl.isNotEmpty)
          ? ChatRemoteDataSource(baseUrl: serverUrl)
          : null,
      demoDataSource: demoDataSource,
    );
    _isConnected = _repository.isConnected;
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _addSystemMessage() {
    _messages.add(
      ChatMessageModel(
        role: 'system',
        content: '',
        timestamp: DateTime.now(),
      ),
    );
  }

  ChatMessageModel _emptyAssistant() => ChatMessageModel(
        role: 'assistant',
        content: '',
        timestamp: DateTime.now(),
      );

  void _replaceLastAssistant(String content) {
    if (_messages.isEmpty || _messages.last.role != 'assistant') return;
    _messages[_messages.length - 1] = ChatMessageModel(
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  void _removeTrailingAssistantIfEmpty() {
    if (_messages.isNotEmpty &&
        _messages.last.role == 'assistant' &&
        _messages.last.content.trim().isEmpty) {
      _messages.removeLast();
    }
  }

  /// Dừng streaming phản hồi AI ngay lập tức (giữ lại nội dung đã stream).
  void stopStreaming() {
    if (_state != ChatState.streaming) return;
    _requestId++;
    _state = ChatState.done;
    _removeTrailingAssistantIfEmpty();
    _notify();
  }

  /// Tạo cuộc trò chuyện mới hoàn toàn (New Chat).
  void startNewChat() {
    stopStreaming();
    clearChat();
  }

  /// Gửi tin nhắn người dùng và bắt đầu stream phản hồi AI.
  Future<void> sendMessage({
    required String content,
    required String langCode,
    bool fromQuestionContext = false,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || _state == ChatState.streaming) return;

    if (!fromQuestionContext) {
      // Người dùng gõ tin nhắn tự do -> xóa ngữ cảnh câu hỏi cũ để đàm thoại tự nhiên
      _activeQuestion = null;
      _userChoiceIndex = null;
    }

    _lastUserContent = trimmed;
    _lastLangCode = langCode;
    _messages.add(
      ChatMessageModel(
        role: 'user',
        content: trimmed,
        timestamp: DateTime.now(),
        langCode: langCode,
      ),
    );
    await _streamAnswer(langCode: langCode);
  }

  Future<void> _streamAnswer({required String langCode}) async {
    final requestId = ++_requestId;

    _state = ChatState.streaming;
    _errorMessage = '';
    _streamingText = '';
    _usedFallback = false;
    _messages.add(_emptyAssistant());
    _notify();

    // Chỉ gửi lịch sử có nội dung thật: bỏ system và bubble assistant rỗng.
    final requestMessages = _messages
        .where((m) => m.role != 'system' && m.content.trim().isNotEmpty)
        .toList();

    try {
      // Nếu chưa có API key và chưa có server url, chuyển thẳng sang offline fallback
      if (!_isConnected) {
        throw Exception('Chưa cấu hình API Key');
      }

      await for (final chunk in _repository.sendMessageStream(
        messages: requestMessages,
        langCode: langCode,
        activeQuestion: _activeQuestion,
        userChoiceIndex: _userChoiceIndex,
      )) {
        if (requestId != _requestId) return;
        _streamingText += chunk;
        _replaceLastAssistant(_streamingText);
        _notify();
      }

      if (requestId != _requestId) return;
      if (_streamingText.trim().isEmpty) {
        throw Exception('AI không trả về nội dung.');
      }
      _state = ChatState.done;
    } catch (e) {
      if (requestId != _requestId) return;
      debugPrint('AI Chat Error [$_aiProvider]: $e');

      // Nếu đang dùng provider có cấu hình (Gemini / OpenRouter), hiển thị lỗi rõ ràng
      if (_isConnected) {
        _errorMessage = _friendlyError(e);
        _state = ChatState.error;
        _removeTrailingAssistantIfEmpty();
        _notify();
        return;
      }

      // Chỉ fallback về Demo khi chưa có API Key
      final recovered = await _streamDemoAnswer(
        requestId: requestId,
        langCode: langCode,
      );
      if (requestId != _requestId) return;

      if (!recovered) {
        _errorMessage = _friendlyError(e);
        _state = ChatState.error;
        _removeTrailingAssistantIfEmpty();
      }
    }

    _notify();
  }

  /// Trả lời dự phòng thông minh (offline) khi chưa có key hoặc AI không phản hồi.
  Future<bool> _streamDemoAnswer({
    required int requestId,
    required String langCode,
  }) async {
    try {
      _usedFallback = true;
      _streamingText = '';
      _replaceLastAssistant('');
      _notify();

      final answer = await demoDataSource.getDemoAnswer(
        userMessage: _lastUserContent,
        langCode: langCode,
        activeQuestion: _activeQuestion,
        userChoiceIndex: _userChoiceIndex,
      );
      if (requestId != _requestId) return true;

      final words = answer.split(' ');
      for (var i = 0; i < words.length; i++) {
        if (requestId != _requestId) return true;
        _streamingText += words[i] + (i < words.length - 1 ? ' ' : '');
        _replaceLastAssistant(_streamingText);
        _notify();
        await Future.delayed(const Duration(milliseconds: 25));
      }

      _state = ChatState.done;
      return true;
    } catch (_) {
      return false;
    }
  }

  String _friendlyError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '');

    // Lỗi chung kết nối
    if (raw.contains('TimeoutException') || raw.contains('quá thời gian')) {
      return 'Kết nối tới AI quá lâu. Vui lòng kiểm tra mạng và thử lại.';
    }
    if (raw.contains('XMLHttpRequest') || raw.contains('ClientException')) {
      return 'Lỗi kết nối mạng từ trình duyệt Web. Vui lòng kiểm tra kết nối và thử lại.';
    }

    // Lỗi đặc trưng AI Provider – đã được format sẵn từ datasource
    // Chỉ cần trả nguyên văn vì đã thân thiện
    return raw.isEmpty ? 'Không thể kết nối AI. Vui lòng thử lại.' : raw;
  }

  /// Sinh lại câu trả lời AI gần nhất (Regenerate).
  Future<void> regenerateLastResponse() async {
    if (_state == ChatState.streaming) return;
    if (_messages.isEmpty) return;

    if (_messages.last.role == 'assistant') {
      _messages.removeLast();
    }
    _removeTrailingAssistantIfEmpty();
    _errorMessage = '';
    _state = ChatState.idle;
    _notify();

    final lastUserIndex = _messages.lastIndexWhere((m) => m.role == 'user');
    if (lastUserIndex == -1) return;
    _lastUserContent = _messages[lastUserIndex].content;
    _lastLangCode = _messages[lastUserIndex].langCode ?? _lastLangCode;

    await _streamAnswer(langCode: _lastLangCode);
  }

  /// Gửi lại câu hỏi cuối cùng khi lần trước bị lỗi (Retry).
  Future<void> retryLastMessage() async {
    if (_lastUserContent.isEmpty || _state == ChatState.streaming) return;

    _removeTrailingAssistantIfEmpty();
    if (_messages.isNotEmpty && _messages.last.role == 'assistant') {
      _messages.removeLast();
    }
    await _streamAnswer(langCode: _lastLangCode);
  }

  /// Bắt đầu phiên chat với ngữ cảnh câu hỏi luyện tập (văn phong tự nhiên).
  void askAboutQuestion({
    required QuestionModel question,
    int? userChoiceIndex,
    required String langCode,
  }) {
    final isSameQuestion = _currentQuestionId == question.id;
    _currentQuestionId = question.id;
    _activeQuestion = question;
    _userChoiceIndex = userChoiceIndex;

    if (isSameQuestion && hasConversation) {
      // Đã có ngữ cảnh của đúng câu hỏi này -> giữ nguyên hội thoại.
      return;
    }

    if (!isSameQuestion) {
      _resetConversation();
      _activeQuestion = question;
      _userChoiceIndex = userChoiceIndex;
    } else if (_state == ChatState.streaming) {
      _requestId++;
      _removeTrailingAssistantIfEmpty();
      _state = ChatState.idle;
      _streamingText = '';
    }

    final isVi = langCode == 'vi';
    final userOpt = userChoiceIndex != null &&
            userChoiceIndex < question.getOptions(langCode).length
        ? question.getOptions(langCode)[userChoiceIndex]
        : null;

    final prompt = isVi
        ? 'Chào bạn! Mình có câu hỏi này trong bài học cần bạn hỗ trợ giải thích giúp mình:\n\n'
            '• **Khối kiến thức:** ${question.blockName.getText(langCode)}\n'
            '• **Câu hỏi:** ${question.question.getText(langCode)}\n'
            '${userOpt != null ? '• **Lựa chọn của mình:** `$userOpt`\n' : ''}'
            '• **Đáp án chuẩn:** `${question.getOptions(langCode)[question.correctIndex]}`\n\n'
            'Nhờ bạn phân tích giúp mình vì sao đáp án đúng lại như vậy${userOpt != null ? ', và điểm mình dễ bị nhầm lẫn ở lựa chọn đã chọn' : ''} nhé!'
        : 'Hello! I have a question from the quiz and need your help:\n\n'
            '• **Topic:** ${question.blockName.getText(langCode)}\n'
            '• **Question:** ${question.question.getText(langCode)}\n'
            '${userOpt != null ? '• **My Choice:** `$userOpt`\n' : ''}'
            '• **Correct Answer:** `${question.getOptions(langCode)[question.correctIndex]}`\n\n'
            'Could you break down why the correct answer is right${userOpt != null ? ', and what made my choice tricky' : ''}?';

    sendMessage(
      content: prompt,
      langCode: langCode,
      fromQuestionContext: true,
    );
  }

  void _resetConversation() {
    _requestId++;
    _messages.clear();
    _streamingText = '';
    _errorMessage = '';
    _state = ChatState.idle;
    _usedFallback = false;
    _lastUserContent = '';
    _addSystemMessage();
  }

  /// Xóa toàn bộ lịch sử chat và bắt đầu phiên mới.
  void clearChat() {
    _resetConversation();
    _currentQuestionId = null;
    _activeQuestion = null;
    _userChoiceIndex = null;
    _notify();
  }

  void clearError() {
    _errorMessage = '';
    if (_state == ChatState.error) {
      _state = ChatState.idle;
    }
    _notify();
  }
}
