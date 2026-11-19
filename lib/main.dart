import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/auth_storage_datasource.dart';
import 'data/datasources/blockchain_storage_datasource.dart';
import 'data/datasources/course_progress_storage_datasource.dart';
import 'data/datasources/ethereum_blockchain_datasource.dart';
import 'data/datasources/quiz_local_datasource.dart';
import 'data/datasources/quiz_storage_datasource.dart';
import 'data/datasources/gamification_storage_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/quiz_repository_impl.dart';
import 'data/repositories/blockchain_repository_impl.dart';
import 'data/repositories/gamification_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/quiz_repository.dart';
import 'domain/repositories/i_blockchain_repository.dart';
import 'domain/repositories/i_gamification_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/blockchain_provider.dart';
import 'presentation/providers/course_progress_provider.dart';
import 'presentation/providers/exam_provider.dart';
import 'presentation/providers/gamification_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/providers/quiz_provider.dart';
import 'presentation/providers/stats_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/ai_chat_screen.dart';
import 'presentation/screens/blockchain_certificates_screen.dart';
import 'presentation/screens/cau_hoi_da_luu_screen.dart';
import 'presentation/screens/course_progress_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'core/navigation/app_page_route.dart';
import 'screens/trang_chu_screen.dart';

/// URL backend proxy AI. Có thể override khi build:
/// `flutter run --dart-define=AI_PROXY_URL=https://my-worker.workers.dev`
const String _aiProxyUrl = String.fromEnvironment(
  'AI_PROXY_URL',
  defaultValue: 'https://flutter-quiz-ai-proxy.trolyai.workers.dev',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final localDataSource = QuizLocalDataSource();
  final storageDataSource = QuizStorageDataSource();
  final IQuizRepository quizRepository = QuizRepositoryImpl(
    localDataSource: localDataSource,
    storageDataSource: storageDataSource,
  );
  final authStorageDataSource = AuthStorageDataSource();
  final IAuthRepository authRepository = AuthRepositoryImpl(
    storageDataSource: authStorageDataSource,
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
          create: (_) => AuthProvider(repository: authRepository)..initialize(),
        ),
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
        ChangeNotifierProvider(
          create: (_) => ChatProvider(serverUrl: _aiProxyUrl),
        ),
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) {
              return supported;
            }
          }
        }
        return supportedLocales.first;
      },
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme.mode,
      home: const AuthScopedGate(),
      routes: {
        AppPageRoutes.certificates: (_) => const BlockchainCertificatesScreen(),
        AppPageRoutes.courseProgress: (_) => const CourseProgressScreen(),
        AppPageRoutes.bookmarkedQuestions: (_) => const CauHoiDaLuuScreen(),
        AppPageRoutes.aiChat: (_) => const AiChatScreen(),
        AppPageRoutes.login: (_) => const LoginScreen(),
        AppPageRoutes.register: (_) => const RegisterScreen(),
      },
    );
  }
}

class AuthScopedGate extends StatefulWidget {
  const AuthScopedGate({super.key});

  @override
  State<AuthScopedGate> createState() => _AuthScopedGateState();
}

class _AuthScopedGateState extends State<AuthScopedGate> {
  String? _lastUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    final currentId = auth.currentUser?.id;

    if (currentId != _lastUserId) {
      _lastUserId = currentId;
      if (currentId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<GamificationProvider>().initialize();
          context.read<QuizProvider>().reloadProgress();
          context.read<CourseProgressProvider>().initialize();
          context.read<StatsProvider>().loadHistory();
          context.read<BlockchainProvider>().initialize();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    return const TrangChuScreen();
  }
}
