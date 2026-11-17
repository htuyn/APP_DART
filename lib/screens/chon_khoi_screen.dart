import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/navigation/app_page_route.dart';
import '../presentation/providers/language_provider.dart';
import '../presentation/providers/quiz_provider.dart';
import '../presentation/screens/diep_practice_screen.dart';
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
              FilterChip(
                avatar: const Icon(Icons.grid_view_rounded, size: 16),
                label: Text(lang.t('all')),
                selected: !_needsReview,
                onSelected: (_) => setState(() => _needsReview = false),
              ),
              const SizedBox(width: 8),
              FilterChip(
                avatar: const Icon(Icons.warning_amber_rounded, size: 16),
                label: Text(lang.t('needs_review')),
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
                          onTap: () {
                            Navigator.of(context).push(
                              openAppPage(PracticeScreen(initialBlockId: blockId)),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
        ),
      ],
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
