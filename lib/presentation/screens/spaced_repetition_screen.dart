import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/question_model.dart';
import '../../data/models/spaced_repetition_model.dart';
import '../providers/language_provider.dart';
import '../providers/spaced_repetition_provider.dart';
import '../widgets/option_tile.dart';
import '../widgets/responsive_body.dart';
import '../widgets/state_views.dart';

class SpacedRepetitionScreen extends StatefulWidget {
  const SpacedRepetitionScreen({super.key});

  @override
  State<SpacedRepetitionScreen> createState() =>
      _SpacedRepetitionScreenState();
}

class _SpacedRepetitionScreenState extends State<SpacedRepetitionScreen> {
  // questionId -> selected option index (after user picks an answer)
  final Map<String, int> _selectedAnswers = {};
  // questionId -> whether the answer row is expanded/showing options
  final Map<String, bool> _expanded = {};

  String optionLabel(int index) {
    const labels = ['A', 'B', 'C', 'D', 'E', 'F'];
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return '${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final sr = context.watch<SpacedRepetitionProvider>();
    final lang = context.watch<LanguageProvider>();
    final questions = sr.sortedReviewQuestions;
    final dueCount = sr.dueTodayCount;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🧠 Ôn tập thông minh'),
            const SizedBox(width: 10),
            if (dueCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$dueCount câu cần ôn hôm nay',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: ResponsiveBody(
        child: questions.isEmpty
            ? EmptyView(
                icon: Icons.psychology_rounded,
                title: 'Chưa có câu nào cần ôn',
                message:
                    'Hãy bookmark câu hỏi từ các bài luyện tập để AI sắp xếp lịch ôn theo đường cong lãng quên.',
                actionText: 'Quay về',
                onAction: () => Navigator.pop(context),
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                itemCount: questions.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildHeaderCard(dueCount);
                  final q = questions[index - 1];
                  final entry = sr.entryFor(q.id);
                  return _buildQuestionItem(context, q, entry, sr, lang);
                },
              ),
      ),
    );
  }

  // ─── Header info card ──────────────────────────────────────────────────────

  Widget _buildHeaderCard(int dueCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.aiGradient,
        borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Spaced Repetition',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hệ thống tự động sắp xếp câu hỏi theo đường cong lãng quên Ebbinghaus — ôn đúng lúc, nhớ lâu hơn.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Question card ─────────────────────────────────────────────────────────

  Widget _buildQuestionItem(
    BuildContext context,
    QuestionModel q,
    SpacedRepetitionEntry? entry,
    SpacedRepetitionProvider sr,
    LanguageProvider lang,
  ) {
    final theme = Theme.of(context);
    final isExpanded = _expanded[q.id] ?? false;
    final isAnswered = _selectedAnswers.containsKey(q.id);
    final userChoice = _selectedAnswers[q.id];
    final options = q.getOptions(lang.code);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top row: ID + status chip ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${q.id} • ${q.blockName.getText(lang.code)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (entry != null) _buildStatusChip(entry),
              ],
            ),
            const SizedBox(height: 10),

            // ── Question text ──────────────────────────────────────────
            Text(
              q.question.getText(lang.code),
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                height: 1.46,
              ),
            ),
            const SizedBox(height: 10),

            // ── Stats row ──────────────────────────────────────────────
            if (entry != null) _buildStatsRow(entry, theme),

            const SizedBox(height: 12),

            // ── Expand / options ───────────────────────────────────────
            if (!isExpanded && !isAnswered)
              OutlinedButton.icon(
                onPressed: () => setState(() => _expanded[q.id] = true),
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text('Làm lại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),

            if (isExpanded || isAnswered) ...[
              ...List.generate(options.length, (optIdx) {
                OptionState state = OptionState.idle;
                if (isAnswered) {
                  if (optIdx == q.correctIndex) {
                    state = OptionState.correct;
                  } else if (optIdx == userChoice) {
                    state = OptionState.wrong;
                  }
                }
                return OptionTile(
                  label: optionLabel(optIdx),
                  text: options[optIdx],
                  state: state,
                  onTap: isAnswered
                      ? null
                      : () async {
                          final isCorrect = optIdx == q.correctIndex;
                          setState(() {
                            _selectedAnswers[q.id] = optIdx;
                            _expanded[q.id] = false;
                          });
                          await sr.recordAnswer(q.id, isCorrect);
                        },
                );
              }),
              if (isAnswered)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: userChoice == q.correctIndex
                          ? AppColors.successLight
                          : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          userChoice == q.correctIndex
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: userChoice == q.correctIndex
                              ? AppColors.success
                              : AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            userChoice == q.correctIndex
                                ? 'Chính xác! Lịch ôn tập đã được cập nhật.'
                                : 'Chưa đúng. AI sẽ nhắc bạn ôn lại sớm hơn.',
                            style: TextStyle(
                              fontSize: 13,
                              color: userChoice == q.correctIndex
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Status chip (overdue / due today / upcoming) ──────────────────────────

  Widget _buildStatusChip(SpacedRepetitionEntry entry) {
    final now = DateTime.now();
    final diff = now.difference(entry.nextReviewDate).inDays;

    Color bg;
    Color fg;
    String label;

    if (diff > 0) {
      bg = AppColors.errorLight;
      fg = AppColors.error;
      label = 'Quá hạn $diff ngày';
    } else if (diff == 0 ||
        entry.nextReviewDate
            .isBefore(now.add(const Duration(hours: 24)))) {
      bg = AppColors.successLight;
      fg = AppColors.success;
      label = 'Ôn hôm nay';
    } else {
      final remaining = entry.nextReviewDate.difference(now).inDays;
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
      label = 'Còn $remaining ngày';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  // ─── Stats row (wrong count + urgency score) ───────────────────────────────

  Widget _buildStatsRow(SpacedRepetitionEntry entry, ThemeData theme) {
    return Row(
      children: [
        _StatPill(
          icon: Icons.close_rounded,
          value: '${entry.wrongCount} lần sai',
          color: AppColors.error,
        ),
        const SizedBox(width: 8),
        _StatPill(
          icon: Icons.priority_high_rounded,
          value: 'Urgency: ${entry.urgencyScore.toStringAsFixed(1)}',
          color: AppColors.warning,
        ),
        const SizedBox(width: 8),
        _StatPill(
          icon: Icons.refresh_rounded,
          value: '${entry.reviewCount}× ôn',
          color: AppColors.accentIndigo,
        ),
      ],
    );
  }
}

// ─── Small helper widget ──────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
