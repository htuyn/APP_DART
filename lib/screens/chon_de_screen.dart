import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/navigation/app_page_route.dart';
import '../presentation/providers/exam_provider.dart';
import '../presentation/providers/language_provider.dart';
import '../presentation/providers/quiz_provider.dart';
import '../presentation/screens/diep_exam_screen.dart';
import '../presentation/widgets/language_button.dart';
import '../presentation/widgets/responsive_body.dart';
import '../presentation/widgets/state_views.dart';

class ChonDeScreen extends StatelessWidget {
  const ChonDeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('exam_sets')),
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
    if (quiz.allQuestions.isEmpty) {
      return EmptyView(
        title: lang.t('empty_blocks'),
        message: lang.t('empty_blocks_hint'),
        actionText: lang.t('go_home'),
        onAction: () => Navigator.of(context).pop(),
      );
    }

    final perPaper = quiz.allQuestions.length >= ExamProvider.paperSize
        ? ExamProvider.paperSize
        : quiz.allQuestions.length;
    final meta = '$perPaper ${lang.t('questions')} Â· ${ExamProvider.paperMinutes} ${lang.t('minutes')}';

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lang.t('exam_sets_hint'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PaperCard(
          icon: Icons.shuffle_rounded,
          title: lang.t('random_exam'),
          subtitle: lang.t('random_exam_hint'),
          meta: meta,
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          action: lang.t('start_exam'),
          onTap: () {
            Navigator.of(context).push(openAppPage(const ExamScreen()));
          },
        ),
        const SizedBox(height: 20),
        Text(
          lang.t('exam_sets'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ExamProvider.paperCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: wide ? 2 : 1,
                mainAxisExtent: 104,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (context, index) {
                final paper = index + 1;
                final number = paper.toString().padLeft(2, '0');
                return _PaperCard(
                  icon: Icons.assignment_outlined,
                  title: '${lang.t('paper')} $number',
                  subtitle: '${lang.t('mock_exam')} #$number',
                  meta: meta,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  action: lang.t('start_exam'),
                  onTap: () {
                    Navigator.of(context).push(
                      openAppPage(ExamScreen(paperIndex: paper)),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _PaperCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final LinearGradient gradient;
  final String action;
  final VoidCallback onTap;

  const _PaperCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.gradient,
    required this.action,
    required this.onTap,
  });

  @override
  State<_PaperCard> createState() => _PaperCardState();
}

class _PaperCardState extends State<_PaperCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            setState(() => _pressed = false);
            widget.onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.meta,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonal(
                  onPressed: widget.onTap,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.action, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      const Icon(Icons.play_arrow_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}