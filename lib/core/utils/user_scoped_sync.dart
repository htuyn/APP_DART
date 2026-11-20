import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/providers/blockchain_provider.dart';
import '../../presentation/providers/course_progress_provider.dart';
import '../../presentation/providers/gamification_provider.dart';
import '../../presentation/providers/quiz_provider.dart';
import '../../presentation/providers/stats_provider.dart';

Future<void> reloadUserScopedProviders(BuildContext context) async {
  final gamification = context.read<GamificationProvider>();
  final quiz = context.read<QuizProvider>();
  final courseProgress = context.read<CourseProgressProvider>();
  final stats = context.read<StatsProvider>();
  final blockchain = context.read<BlockchainProvider>();

  await Future.wait([
    gamification.initialize(),
    quiz.reloadProgress(),
    courseProgress.initialize(),
    stats.loadHistory(),
    blockchain.initialize(),
  ]);
}
