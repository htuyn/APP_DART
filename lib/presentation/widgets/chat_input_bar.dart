import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ChatInputBar extends StatefulWidget {
  final String langCode;
  final bool isStreaming;
  final String errorMessage;
  final VoidCallback onSend;
  final VoidCallback onRetry;
  final ValueChanged<String> onSubmitted;

  const ChatInputBar({
    super.key,
    required this.langCode,
    required this.isStreaming,
    required this.errorMessage,
    required this.onSend,
    required this.onRetry,
    required this.onSubmitted,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Nút retry khi lỗi
            if (widget.errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Thử lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),

            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !widget.isStreaming,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: widget.langCode == 'vi'
                      ? 'Nhập câu hỏi...'
                      : 'Ask a question...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  suffixIcon: widget.isStreaming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.accentPurple),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: AppColors.primary,
                          ),
                          onPressed: _send,
                        ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _controller.clear();
      widget.onSubmitted(text);
    }
  }
}
