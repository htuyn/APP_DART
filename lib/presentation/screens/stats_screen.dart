import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/stats_provider.dart';
import 'diep_practice_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final quiz = context.watch<QuizProvider>();
    final statsProv = context.watch<StatsProvider>();

    final blockStats = statsProv.calculateBlockStats(
      allQuestions: quiz.allQuestions,
      wrongIds: quiz.wrongQuestionIds,
      langCode: lang.code,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            lang.translate(
              vi: 'ThÃ¡Â»â€˜ng KÃƒÂª KiÃ¡ÂºÂ¿n ThÃ¡Â»Â©c',
              en: 'Knowledge Statistics',
            ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                text: lang.translate(
                  vi: '20 KhÃ¡Â»â€˜i KiÃ¡ÂºÂ¿n ThÃ¡Â»Â©c',
                  en: '20 Knowledge Blocks',
                ),
              ),
              Tab(
                text: lang.translate(
                  vi: 'LÃ¡Â»â€¹ch SÃ¡Â»Â­ Thi ThÃ¡Â»Â­',
                  en: 'Exam History',
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: 20 KhÃ¡Â»â€˜i
            ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: blockStats.length,
              itemBuilder: (context, index) {
                final stat = blockStats[index];
                final rate = stat.accuracyRate;
                final isWeak = stat.wrongQuestions > 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    title: Text(
                      'KhÃ¡Â»â€˜i ${stat.blockId}. ${stat.blockTitle}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: rate / 100.0,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            color: rate >= 80
                                ? Colors.green
                                : rate >= 50
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${lang.translate(vi: "Ã„ÂÃƒÂºng:", en: "Correct:")} ${stat.correctCount}/${stat.totalQuestions} (${rate.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if (isWeak)
                              Text(
                                '${stat.wrongQuestions} ${lang.translate(vi: "cÃƒÂ¢u sai", en: "incorrect")}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PracticeScreen(initialBlockId: stat.blockId),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Tab 2: LÃ¡Â»â€¹ch sÃ¡Â»Â­ thi
            statsProv.history.isEmpty
                ? Center(
                    child: Text(
                      lang.translate(
                        vi: 'ChÃ†Â°a cÃƒÂ³ lÃ¡Â»â€¹ch sÃ¡Â»Â­ lÃƒÂ m bÃƒÂ i thi thÃ¡Â»Â­ nÃƒÂ o.',
                        en: 'No mock exam history yet.',
                      ),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: statsProv.history.reversed.length,
                    itemBuilder: (context, index) {
                      final item = statsProv.history.reversed.toList()[index];
                      final isPassed = item.percentage >= 60.0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPassed
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              isPassed ? Icons.check : Icons.close,
                              color: isPassed
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                          title: Text(
                            '${lang.translate(vi: "Ã„ÂiÃ¡Â»Æ’m:", en: "Score:")} ${item.score}/${item.totalQuestions} (${item.percentage.toStringAsFixed(1)}%)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.timestamp.toLocal().toString().split(".")[0]} Ã¢â‚¬Â¢ ${item.timeSpentSeconds ~/ 60}m ${item.timeSpentSeconds % 60}s',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPassed
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPassed
                                  ? lang.translate(vi: 'Ã„ÂÃ¡ÂºÂ T', en: 'PASS')
                                  : lang.translate(vi: 'TRÃ†Â¯Ã¡Â»Â¢T', en: 'FAIL'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPassed
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
