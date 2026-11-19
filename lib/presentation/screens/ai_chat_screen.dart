import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../providers/chat_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';

/// Màn hình chat AI tutor: trải nghiệm hội thoại tự nhiên, phong cách ChatGPT hiện đại.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final ScrollController _scrollController = ScrollController();
  ChatProvider? _chat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _chat = context.read<ChatProvider>()..addListener(_onChatChanged);
      _scrollToBottom(animate: false);
    });
  }

  @override
  void dispose() {
    _chat?.removeListener(_onChatChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onChatChanged() {
    _scrollToBottom(animate: true);
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _send(
    ChatProvider chat,
    LanguageProvider lang,
    String text,
  ) async {
    await chat.sendMessage(content: text, langCode: lang.code);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final chat = context.watch<ChatProvider>();
    final isVi = lang.code == 'vi';

    final visibleMessages = chat.messages
        .where(
          (m) =>
              m.role != 'system' &&
              !(m.role == 'assistant' &&
                  m.content.trim().isEmpty &&
                  chat.isStreaming),
        )
        .toList();

    final latestAssistantIndex = visibleMessages.lastIndexWhere(
      (m) => m.role == 'assistant' && !chat.isStreaming,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.aiGradient,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPurple.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AI Tutor',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6.5,
                      height: 6.5,
                      decoration: BoxDecoration(
                        color: chat.isStreaming
                            ? AppColors.accentPurple
                            : (chat.isConnected
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4.5),
                    Text(
                      chat.isStreaming
                          ? (isVi ? 'Đang trả lời...' : 'Responding...')
                          : (chat.aiProvider == AiProvider.openrouter &&
                                  chat.hasOpenRouterKey
                              ? (isVi
                                  ? 'OpenRouter AI Sẵn sàng'
                                  : 'OpenRouter AI Ready')
                              : (chat.hasApiKey
                                  ? (isVi
                                      ? 'Gemini AI Sẵn sàng'
                                      : 'Gemini AI Ready')
                                  : (isVi ? 'Gia sư Offline' : 'Offline Tutor'))),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : IconButton(
                icon: const Icon(Icons.home_rounded),
                tooltip: isVi ? 'Trang chủ' : 'Home',
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/'),
              ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
            height: 1.5,
            decoration: const BoxDecoration(
              gradient: AppColors.aiGradient,
            ),
          ),
        ),
        actions: [
          // Nút Cuộc hội thoại mới (New Chat)
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, size: 20),
            tooltip: isVi ? 'Cuộc hội thoại mới' : 'New chat',
            onPressed: () => chat.startNewChat(),
          ),
          // Nút Cài đặt API Key
          IconButton(
            icon: Icon(
              chat.isConnected
                  ? Icons.vpn_key_rounded
                  : Icons.key_off_outlined,
              size: 20,
              color: chat.isConnected ? AppColors.accentPurple : Colors.grey,
            ),
            tooltip:
                isVi ? 'Cài đặt AI Provider & API Key' : 'Configure AI Provider & API Key',
            onPressed: () => _showApiKeyDialog(context),
          ),
          // Nút Xóa lịch sử
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            tooltip: isVi ? 'Xóa lịch sử chat' : 'Clear history',
            onPressed:
                chat.isStreaming ? null : () => _showClearDialog(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              children: [
                // Banner trạng thái nếu cần lưu ý
                if (chat.usedFallback && chat.hasApiKey)
                  _StatusBanner(
                    color: AppColors.warning,
                    background: AppColors.warningLight,
                    icon: Icons.cloud_off_rounded,
                    text: isVi
                        ? 'Mạng bận — đang phân tích theo dữ liệu câu hỏi trong app'
                        : 'Network busy — answering from app quiz data',
                  )
                else if (!chat.hasApiKey)
                  _StatusBanner(
                    color: const Color(0xFF7C3AED),
                    background: const Color(0xFFF3E8FF),
                    icon: Icons.auto_awesome,
                    text: isVi
                        ? 'Chế độ Gia sư Offline. Nhấn vào đây để kết nối Gemini AI miễn phí'
                        : 'Offline Tutor Mode. Tap here to connect free Gemini AI',
                    onTap: () => _showApiKeyDialog(context),
                  ),

                // Danh sách tin nhắn hoặc Welcome Screen
                Expanded(
                  child: visibleMessages.isEmpty
                      ? _WelcomePanel(
                          lang: lang,
                          onSuggestionTap: (text) => _send(chat, lang, text),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          itemCount: visibleMessages.length,
                          itemBuilder: (context, index) {
                            return ChatMessageBubble(
                              message: visibleMessages[index],
                              langCode: lang.code,
                              isLatestAssistant:
                                  index == latestAssistantIndex,
                              onRegenerate: () =>
                                  chat.regenerateLastResponse(),
                            );
                          },
                        ),
                ),

                // Hiệu ứng đang gõ chữ
                if (chat.isStreaming)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isVi ? 'AI đang suy nghĩ...' : 'AI is thinking...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Lỗi nếu có
                if (chat.errorMessage.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              chat.errorMessage,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Ô nhập prompt cố định ở cuối màn hình
                ChatInputBar(
                  langCode: lang.code,
                  isStreaming: chat.isStreaming,
                  errorMessage: chat.errorMessage,
                  onRetry: chat.retryLastMessage,
                  onStop: chat.stopStreaming,
                  onSubmitted: (text) => _send(chat, lang, text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showApiKeyDialog(BuildContext context) async {
    final lang = context.read<LanguageProvider>();
    final chat = context.read<ChatProvider>();
    final isVi = lang.code == 'vi';

    await showDialog(
      context: context,
      builder: (ctx) => _AiProviderDialog(chat: chat, isVi: isVi),
    );
  }

  Future<void> _showClearDialog(BuildContext context) async {
    final lang = context.read<LanguageProvider>();
    final isVi = lang.code == 'vi';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isVi ? 'Xóa lịch sử?' : 'Clear history?'),
        content: Text(
          isVi
              ? 'Bạn có chắc muốn xóa toàn bộ cuộc hội thoại hiện tại?'
              : 'Are you sure you want to clear the entire current conversation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isVi ? 'Hủy' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ChatProvider>().clearChat();
              Navigator.of(context).pop();
            },
            child: Text(isVi ? 'Xóa' : 'Clear'),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Color color;
  final Color background;
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _StatusBanner({
    required this.color,
    required this.background,
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: background,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: onTap != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded, color: color, size: 18),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

class _WelcomePanel extends StatelessWidget {
  final LanguageProvider lang;
  final ValueChanged<String> onSuggestionTap;

  const _WelcomePanel({
    required this.lang,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVi = lang.code == 'vi';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final suggestions = isVi
        ? [
            (
              icon: Icons.lightbulb_outline_rounded,
              color: const Color(0xFFF59E0B),
              category: 'Giải thích một khái niệm',
              prompt: 'Phân biệt const và final trong Dart?'
            ),
            (
              icon: Icons.code_rounded,
              color: const Color(0xFF3B82F6),
              category: 'Hỗ trợ viết code',
              prompt:
                  'Viết một widget custom Button có hiệu ứng gradient và ripple animation?'
            ),
            (
              icon: Icons.bug_report_outlined,
              color: const Color(0xFFEF4444),
              category: 'Giải thích lỗi',
              prompt:
                  'Tại sao gặp lỗi "setState() called after dispose()" và cách sửa?'
            ),
            (
              icon: Icons.menu_book_rounded,
              color: const Color(0xFF10B981),
              category: 'Ôn tập kiến thức',
              prompt:
                  'Tóm tắt các giai đoạn chính trong vòng đời của StatefulWidget?'
            ),
            (
              icon: Icons.rocket_launch_outlined,
              color: const Color(0xFF8B5CF6),
              category: 'Tạo ví dụ thực tế',
              prompt:
                  'Cho ví dụ thực tế sử dụng FutureBuilder kết hợp RefreshIndicator?'
            ),
          ]
        : [
            (
              icon: Icons.lightbulb_outline_rounded,
              color: const Color(0xFFF59E0B),
              category: 'Explain a concept',
              prompt: 'Difference between const and final in Dart?'
            ),
            (
              icon: Icons.code_rounded,
              color: const Color(0xFF3B82F6),
              category: 'Code assistance',
              prompt:
                  'Write a custom Button widget with gradient and ripple effect?'
            ),
            (
              icon: Icons.bug_report_outlined,
              color: const Color(0xFFEF4444),
              category: 'Debug an issue',
              prompt:
                  'Why does "setState() called after dispose()" occur and how to fix it?'
            ),
            (
              icon: Icons.menu_book_rounded,
              color: const Color(0xFF10B981),
              category: 'Review knowledge',
              prompt: 'Summarize the lifecycle stages of StatefulWidget?'
            ),
            (
              icon: Icons.rocket_launch_outlined,
              color: const Color(0xFF8B5CF6),
              category: 'Real-world example',
              prompt:
                  'Provide a real-world example of FutureBuilder with RefreshIndicator?'
            ),
          ];

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.aiGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPurple.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isVi
                    ? 'Xin chào! Mình là AI Tutor 👋'
                    : 'Hello! I am your AI Tutor 👋',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 21,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isVi
                    ? 'Bạn muốn tìm hiểu điều gì hôm nay?'
                    : 'What would you like to explore today?',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 24),

              // Danh sách gợi ý kiểu ChatGPT
              for (final item in suggestions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => onSuggestionTap(item.prompt),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.icon,
                              color: item.color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: item.color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.prompt,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dialog Cài đặt AI Provider ─────────────────────────────────────────────

class _AiProviderDialog extends StatefulWidget {
  final ChatProvider chat;
  final bool isVi;

  const _AiProviderDialog({required this.chat, required this.isVi});

  @override
  State<_AiProviderDialog> createState() => _AiProviderDialogState();
}

class _AiProviderDialogState extends State<_AiProviderDialog> {
  late AiProvider _selectedProvider;
  late TextEditingController _geminiKeyCtrl;
  late TextEditingController _orKeyCtrl;
  late TextEditingController _orModelCtrl;

  @override
  void initState() {
    super.initState();
    _selectedProvider = widget.chat.aiProvider;
    _geminiKeyCtrl = TextEditingController(text: widget.chat.apiKey);
    _orKeyCtrl = TextEditingController(text: widget.chat.openRouterKey);
    _orModelCtrl = TextEditingController(text: widget.chat.openRouterModel);
  }

  @override
  void dispose() {
    _geminiKeyCtrl.dispose();
    _orKeyCtrl.dispose();
    _orModelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final chat = widget.chat;
    await chat.setAiProvider(_selectedProvider);
    if (_selectedProvider == AiProvider.gemini) {
      await chat.setApiKey(_geminiKeyCtrl.text.trim());
    } else if (_selectedProvider == AiProvider.openrouter) {
      await chat.setOpenRouterConfig(
        key: _orKeyCtrl.text.trim(),
        model: _orModelCtrl.text.trim(),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isVi = widget.isVi;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.settings_rounded, color: AppColors.accentPurple),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              isVi ? 'Cài đặt AI Provider' : 'AI Provider Settings',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isVi ? 'Chọn nguồn AI:' : 'Select AI provider:',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // Selector
            ...AiProvider.values.map((p) {
              final label = switch (p) {
                AiProvider.gemini =>
                  isVi ? '🔵 Google Gemini' : '🔵 Google Gemini',
                AiProvider.openrouter =>
                  isVi ? '🟣 OpenRouter' : '🟣 OpenRouter',
                AiProvider.offline =>
                  isVi ? '⚫ Gia sư Offline' : '⚫ Offline Demo',
              };
              final selected = _selectedProvider == p;
              return InkWell(
                onTap: () => setState(() => _selectedProvider = p),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? AppColors.accentPurple
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accentPurple,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(label, style: const TextStyle(fontSize: 13.5)),
                    ],
                  ),
                ),
              );
            }),
            const Divider(height: 20),

            // Gemini fields
            if (_selectedProvider == AiProvider.gemini) ...[
              Text(
                isVi ? 'Gemini API Key:' : 'Gemini API Key:',
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _geminiKeyCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'AIzaSy...',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isVi
                    ? '💡 Lấy key tại: aistudio.google.com'
                    : '💡 Get key at: aistudio.google.com',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic),
              ),
            ],

            // OpenRouter fields
            if (_selectedProvider == AiProvider.openrouter) ...[
              Text(
                isVi ? 'OpenRouter API Key:' : 'OpenRouter API Key:',
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _orKeyCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'sk-or-v1-...',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isVi ? 'Model ID:' : 'Model ID:',
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _orModelCtrl,
                decoration: InputDecoration(
                  hintText: 'meta-llama/llama-3.1-8b-instruct:free',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isVi
                    ? '💡 Lấy key tại: openrouter.ai/keys\nModel Free Tier gợi ý:'
                    : '💡 Get key at: openrouter.ai/keys\nSuggested Free Tier models:',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  'meta-llama/llama-3.1-8b-instruct:free',
                  'google/gemma-2-9b-it:free',
                  'mistralai/mistral-7b-instruct:free',
                ].map((m) => ActionChip(
                      label: Text(m.split('/').last,
                          style: const TextStyle(fontSize: 10)),
                      onPressed: () =>
                          setState(() => _orModelCtrl.text = m),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
              ),
            ],

            // Offline
            if (_selectedProvider == AiProvider.offline)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  isVi
                      ? 'Chế độ Offline sử dụng ngân hàng câu hỏi có sẵn trong app.\nKhông cần API Key.'
                      : 'Offline mode uses the built-in quiz question bank.\nNo API Key required.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ),

            // Security notice
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                isVi
                    ? '⚠️ Lưu ý: Đây là ứng dụng Web, API Key được lưu trong bộ nhớ trình duyệt. Chỉ dùng cho mục đích cá nhân. Không chia sẻ màn hình hoặc thiết bị.'
                    : '⚠️ Note: This is a Web app. API Keys are stored in browser storage. Use for personal purposes only. Do not share your screen or device.',
                style: TextStyle(fontSize: 10.5, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isVi ? 'Hủy' : 'Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded, size: 16),
          label: Text(isVi ? 'Lưu' : 'Save'),
        ),
      ],
    );
  }
}

