import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/navigation/app_page_route.dart';
import '../presentation/providers/language_provider.dart';
import '../presentation/providers/quiz_provider.dart';
import '../presentation/screens/flashcard_screen.dart';
import '../presentation/screens/practice_screen.dart';
import '../presentation/widgets/language_button.dart';
import '../presentation/widgets/responsive_body.dart';
import '../presentation/widgets/state_views.dart';

class ChonKhoiScreen extends StatefulWidget {
  const ChonKhoiScreen({super.key});

  @override
  State<ChonKhoiScreen> createState() => _ChonKhoiScreenState();
}

class _ChonKhoiScreenState extends State<ChonKhoiScreen> {
  final TextEditingController _search = TextEditingController();
  bool _needsReview = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('choose_block')),
        actions: const [LanguageButton()],
      ),
      body: ResponsiveBody(child: _body(context, quiz, lang)),
    );
  }

  Widget _body(BuildContext context, QuizProvider quiz, LanguageProvider lang) {
    if (quiz.state == QuizLoadingState.loading ||
        quiz.state == QuizLoadingState.initial) {
      return LoadingView(message: lang.t('loading_questions'));
    }

    if (quiz.state == QuizLoadingState.error) {
      return ErrorView(
        message: quiz.errorMessage ?? lang.t('load_error'),
        retryText: lang.t('retry'),
        onRetry: quiz.initialize,
      );
    }

    final groups = quiz.groupedByBlock;
    final query = _search.text.trim().toLowerCase();
    final blockIds = groups.keys.toList()..sort();
    final visible = blockIds.where((id) {
      final questions = groups[id]!;
      if (questions.isEmpty) return false;
      final title = questions.first.blockName.getText(lang.code);
      final wrong = questions.where((q) => quiz.wrongQuestionIds.contains(q.id)).length;
      if (_needsReview && wrong == 0) return false;
      if (query.isEmpty) return true;
      return title.toLowerCase().contains(query) || '$id'.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: lang.t('search_blocks'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: lang.t('all'),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _buildFilterChip(
                context: context,
                label: lang.t('all'),
                icon: Icons.grid_view_rounded,
                selected: !_needsReview,
                onSelected: (_) => setState(() => _needsReview = false),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context: context,
                label: lang.t('needs_review'),
                icon: Icons.warning_amber_rounded,
                selected: _needsReview,
                onSelected: (_) => setState(() => _needsReview = true),
              ),
              const Spacer(),
              Text(
                '${visible.length}/${blockIds.length} ${lang.t('block').toLowerCase()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? EmptyView(
                  icon: Icons.search_off_rounded,
                  title: blockIds.isEmpty ? lang.t('empty_blocks') : lang.t('no_match'),
                  message: blockIds.isEmpty
                      ? lang.t('empty_blocks_hint')
                      : lang.t('no_match_hint'),
                  actionText: lang.t('go_home'),
                  onAction: () => Navigator.of(context).pop(),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    return GridView.builder(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: wide ? 2 : 1,
                        mainAxisExtent: 124,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final blockId = visible[index];
                        final questions = groups[blockId]!;
                        final title = questions.first.blockName.getText(lang.code);
                        final wrong = questions
                            .where((q) => quiz.wrongQuestionIds.contains(q.id))
                            .length;
                        final rate = (questions.length - wrong) / questions.length;
                        return _BlockTile(
                          blockId: blockId,
                          title: title.isEmpty ? '${lang.t('block')} $blockId' : title,
                          questionCount: questions.length,
                          wrongCount: wrong,
                          rate: rate,
                          questionLabel: lang.t('questions'),
                          onTap: () => _showStudyModeSelectionSheet(
                            context: context,
                            blockId: blockId,
                            blockTitle: title,
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Styled FilterChip ensuring high contrast in both Light & Dark themes
  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = selected
        ? scheme.primaryContainer
        : (isDark ? scheme.surfaceContainerHighest : scheme.surface);
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final border = selected ? scheme.primary : scheme.outlineVariant;

    return FilterChip(
      showCheckmark: false,
      avatar: Icon(icon, size: 16, color: fg),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.w600,
          color: fg,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: scheme.primaryContainer,
      backgroundColor: bg,
      side: BorderSide(
        color: border,
        width: selected ? 1.5 : 1.0,
      ),
    );
  }

  // Modal Bottom Sheet for selecting Traditional Quiz vs. Flashcard Mode
  void _showStudyModeSelectionSheet({
    required BuildContext context,
    required int blockId,
    required String blockTitle,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final lang = sheetContext.watch<LanguageProvider>();
        final scheme = Theme.of(sheetContext).colorScheme;
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: scheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${lang.t('block')} $blockId: $blockTitle',
                          style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: scheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lang.translate(
                            vi: 'Chọn phương thức ôn tập phù hợp với bạn',
                            en: 'Select your preferred study method',
                          ),
                          style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: 18),

              // Option 1: Traditional Mode
              _ModeOptionCard(
                title: lang.translate(
                  vi: 'Chế độ truyền thống (Trắc nghiệm)',
                  en: 'Traditional Mode (Quiz)',
                ),
                subtitle: lang.translate(
                  vi: 'Lựa chọn đáp án 4 phương án, tính điểm, xem giải thích và hỗ trợ AI',
                  en: '4-option quiz with scoring, explanations, and AI tutor support',
                ),
                icon: Icons.assignment_outlined,
                gradientColors: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    openAppPage(PracticeScreen(initialBlockId: blockId)),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Flashcard Mode
              _ModeOptionCard(
                title: lang.translate(
                  vi: 'Chế độ Flashcard (Lật thẻ thông minh)',
                  en: 'Flashcard Mode (Flip Cards)',
                ),
                subtitle: lang.translate(
                  vi: 'Lật thẻ xem câu hỏi, đáp án đúng và giải thích nhanh chóng',
                  en: 'Flip cards to quickly review questions, correct answers & explanations',
                ),
                icon: Icons.style_rounded,
                gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                badge: lang.translate(vi: 'Mới', en: 'New'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    openAppPage(FlashcardScreen(blockId: blockId)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String? badge;
  final VoidCallback onTap;

  const _ModeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? scheme.surfaceContainerHighest : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  final int blockId;
  final String title;
  final int questionCount;
  final int wrongCount;
  final double rate;
  final String questionLabel;
  final VoidCallback onTap;

  const _BlockTile({
    required this.blockId,
    required this.title,
    required this.questionCount,
    required this.wrongCount,
    required this.rate,
    required this.questionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = (rate * 100).round().clamp(0, 100);
    final color = percent >= 80
        ? AppColors.success
        : percent >= 50
            ? AppColors.warning
            : AppColors.error;

    const icons = [
      Icons.code_rounded,
      Icons.widgets_rounded,
      Icons.account_tree_rounded,
      Icons.layers_rounded,
      Icons.bolt_rounded,
      Icons.hub_rounded,
      Icons.schema_rounded,
      Icons.memory_rounded,
    ];

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icons[blockId.abs() % icons.length],
                  color: scheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$questionCount $questionLabel',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (wrongCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$wrongCount sai',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: rate.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
