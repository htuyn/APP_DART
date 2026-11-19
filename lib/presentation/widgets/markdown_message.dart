import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;

import '../../core/constants/app_colors.dart';

/// Hiển thị nội dung markdown (in đậm, danh sách, code block có nút copy) cho tin nhắn AI.
class MarkdownMessage extends StatelessWidget {
  final String data;
  final bool selectable;
  final Color? textColor;

  const MarkdownMessage({
    super.key,
    required this.data,
    this.selectable = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = textColor ?? theme.textTheme.bodyMedium?.color;

    final styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: TextStyle(fontSize: 14.5, height: 1.6, color: color),
      a: TextStyle(
        color: AppColors.primaryLight,
        decoration: TextDecoration.underline,
      ),
      h1: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.4,
      ),
      h2: TextStyle(
        fontSize: 17.5,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.4,
      ),
      h3: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.4,
      ),
      strong: TextStyle(fontWeight: FontWeight.w700, color: color),
      em: TextStyle(fontStyle: FontStyle.italic, color: color),
      listBullet: TextStyle(fontSize: 14.5, height: 1.6, color: color),
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      ),
      blockquote: TextStyle(
        color: theme.textTheme.bodyMedium?.color,
        fontSize: 14,
        height: 1.5,
      ),
      blockquoteDecoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(color: AppColors.accentPurple, width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      listIndent: 20,
    );

    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: styleSheet,
      builders: {
        'pre': _CodeBlockBuilder(isDark: isDark),
      },
      onTapLink: (text, href, title) {},
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  final bool isDark;

  _CodeBlockBuilder({required this.isDark});

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    var language = '';
    if (element.children != null && element.children!.isNotEmpty) {
      final firstChild = element.children!.first;
      if (firstChild is md.Element &&
          firstChild.attributes['class'] != null) {
        final cl = firstChild.attributes['class']!;
        language = cl.replaceFirst('language-', '');
      }
    }

    final codeText = element.textContent.trimRight();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFF475569),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar của Code Block (tên ngôn ngữ + nút Copy)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF334155),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.isNotEmpty ? language.toUpperCase() : 'CODE',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                _CopyCodeButton(code: codeText),
              ],
            ),
          ),
          // Vùng hiển thị code với font monospace và cuộn ngang
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              codeText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyCodeButton extends StatefulWidget {
  final String code;

  const _CopyCodeButton({required this.code});

  @override
  State<_CopyCodeButton> createState() => _CopyCodeButtonState();
}

class _CopyCodeButtonState extends State<_CopyCodeButton> {
  bool _copied = false;

  void _onCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _onCopy,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 13,
              color: _copied ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 4),
            Text(
              _copied ? 'Đã chép' : 'Sao chép',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _copied ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
