import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/question_model.dart';
import '../../presentation/providers/chat_provider.dart';
import '../../presentation/providers/language_provider.dart';
import '../../presentation/widgets/chat_input_bar.dart';
import '../../presentation/widgets/chat_message_bubble.dart';

/// Màn hình chat AI tutor: người dùng gõ câu hỏi, AI trả lời trực tiếp (streaming).
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final chat = context.watch<ChatProvider>();
    final isVi = lang.code == 'vi';

    return Localizations(
      locale: Locale(lang.code),
      delegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isVi ? 'Trợ lý AI Tutor' : 'AI Tutor',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: AppColors.aiGradient,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: isVi ? 'Xóa lịch sử' : 'Clear history',
            onPressed: chat.isStreaming ? null : () => _showClearDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header thông báo trạng thái kết nối
          if (!chat.isConnected) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppColors.warningLight,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isVi
                          ? 'Chế độ demo offline — chỉ trả lời dựa trên dữ liệu trong app'
                          : 'Demo offline mode — answers based on app data only',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Danh sách tin nhắn
          Expanded(
            child: chat.messages.isEmpty
                ? const Center(child: Text('...'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) {
                      return ChatMessageBubble(
                        message: chat.messages[index],
                      );
                    },
                  ),
          ),

          // Hiệu ứng gõ chữ khi đang stream
          if (chat.isStreaming)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isVi ? 'AI đang trả lời...' : 'AI is responding...',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
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

          // Ô nhập tin nhắn
          ChatInputBar(
            langCode: lang.code,
            isStreaming: chat.isStreaming,
            errorMessage: chat.errorMessage,
            onSend: () {},
            onRetry: () => chat.clearError(),
            onSubmitted: (text) async {
              await chat.sendMessage(content: text, langCode: lang.code);
              _scrollToBottom();
            },
          ),
        ],
      ),
    ),
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
              ? 'Bạn có chắc muốn xóa toàn bộ cuộc hội thoại với AI?'
              : 'Are you sure you want to clear the entire AI conversation?',
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
