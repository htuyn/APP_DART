import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/blockchain_storage_datasource.dart';
import 'data/datasources/course_progress_storage_datasource.dart';
import 'data/datasources/ethereum_blockchain_datasource.dart';
import 'data/datasources/quiz_local_datasource.dart';
import 'data/datasources/quiz_storage_datasource.dart';
import 'data/datasources/gamification_storage_datasource.dart';
import 'data/repositories/quiz_repository_impl.dart';
import 'data/repositories/blockchain_repository_impl.dart';
import 'data/repositories/gamification_repository_impl.dart';
import 'domain/repositories/quiz_repository.dart';
import 'domain/repositories/i_blockchain_repository.dart';
import 'domain/repositories/i_gamification_repository.dart';
import 'presentation/providers/ai_tutor_provider.dart';
import 'presentation/providers/blockchain_provider.dart';
import 'presentation/providers/course_progress_provider.dart';
import 'presentation/providers/exam_provider.dart';
import 'presentation/providers/gamification_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/providers/quiz_provider.dart';
import 'presentation/providers/diep_spaced_repetition_provider.dart';
import 'presentation/providers/stats_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/blockchain_certificates_screen.dart';
import 'presentation/screens/course_progress_screen.dart';
import 'core/navigation/app_page_route.dart';
import 'screens/trang_chu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final localDataSource = QuizLocalDataSource();
  final storageDataSource = QuizStorageDataSource();
  final IQuizRepository quizRepository = QuizRepositoryImpl(
    localDataSource: localDataSource,
    storageDataSource: storageDataSource,
  );
  final IGamificationRepository gamificationRepository =
      GamificationRepositoryImpl(GamificationStorageDataSource());
  final statsProvider = StatsProvider(repository: quizRepository);
  final courseProgressStorage = CourseProgressStorageDataSource();
  final blockchainStorage = BlockchainStorageDataSource();
  final ethereumDataSource = EthereumBlockchainDataSource();
  final IBlockchainRepository blockchainRepository = BlockchainRepositoryImpl(
    storage: blockchainStorage,
    ethereum: ethereumDataSource,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => GamificationProvider(repository: gamificationRepository)
            ..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => statsProvider),
        ChangeNotifierProvider(
          create: (_) => CourseProgressProvider(
            repository: quizRepository,
            statsProvider: statsProvider,
            storage: courseProgressStorage,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => QuizProvider(
            repository: quizRepository,
            gamificationProvider: context.read<GamificationProvider>(),
            courseProgressProvider: context.read<CourseProgressProvider>(),
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => ExamProvider(
            repository: quizRepository,
            gamificationProvider: context.read<GamificationProvider>(),
            courseProgressProvider: context.read<CourseProgressProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => BlockchainProvider(
            repository: blockchainRepository,
            gamificationProvider: context.read<GamificationProvider>(),
            courseProgressProvider: context.read<CourseProgressProvider>(),
          )..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => SpacedRepetitionProvider()),
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
        vi: 'Flutter Song Ngữ',
        en: 'Flutter Bilingual Quiz',
      ),
      debugShowCheckedModeBanner: false,
      locale: Locale(lang.code),
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme.mode,
      home: const TrangChuScreen(),
      routes: {
        AppPageRoutes.certificates: (_) => const BlockchainCertificatesScreen(),
        AppPageRoutes.courseProgress: (_) => const CourseProgressScreen(),
      },
    );
  }
}
