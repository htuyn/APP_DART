import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/providers/blockchain_provider.dart';
import '../../presentation/providers/course_progress_provider.dart';
import '../../presentation/providers/gamification_provider.dart';
import '../../presentation/providers/quiz_provider.dart';
import '../../presentation/providers/stats_provider.dart';

Future<void> reloadUserScopedProviders(BuildContext context) async {
  await context.read<GamificationProvider>().initialize();
  await context.read<QuizProvider>().reloadProgress();
  await context.read<CourseProgressProvider>().initialize();
  await context.read<StatsProvider>().loadHistory();
  await context.read<BlockchainProvider>().initialize();
}
