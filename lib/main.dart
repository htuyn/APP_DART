import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/quiz_local_datasource.dart';
import 'data/datasources/quiz_storage_datasource.dart';
import 'data/repositories/quiz_repository_impl.dart';
import 'domain/repositories/quiz_repository.dart';
import 'presentation/providers/ai_tutor_provider.dart';
import 'presentation/providers/exam_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/providers/quiz_provider.dart';
import 'presentation/providers/stats_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'screens/trang_chu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final localDataSource = QuizLocalDataSource();
  final storageDataSource = QuizStorageDataSource();
  final IQuizRepository quizRepository = QuizRepositoryImpl(
    localDataSource: localDataSource,
    storageDataSource: storageDataSource,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => QuizProvider(repository: quizRepository)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => ExamProvider(repository: quizRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => StatsProvider(repository: quizRepository),
        ),
        ChangeNotifierProvider(create: (_) => AiTutorProvider()),
      ],
      child: const QuizApp(),
    ),
  );
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final theme = context.watch<ThemeProvider>();

    return MaterialApp(
      title: lang.translate(
        vi: 'Ôn Tập Flutter Song Ngữ',
        en: 'Flutter Bilingual Quiz',
      ),
      debugShowCheckedModeBanner: false,
      locale: Locale(lang.code),
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme.mode,
      home: const TrangChuScreen(),
    );
  }
}
