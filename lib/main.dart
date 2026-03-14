import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ai_chat_screen.dart';

// ── App State ─────────────────────────────────────────────────────────────────
// 앱의 전역 상태를 관리하는 클래스들

// 1. Theme Provider: 다크/라이트 모드 상태 및 테마 데이터 관리
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// 2. Auth State Provider: Firebase 인증 상태를 실시간으로 감지
class AuthProvider with ChangeNotifier {
  StreamSubscription<User?>? _authStateSubscription;
  User? _user;
  User? get user => _user;

  AuthProvider() {
    _authStateSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

// ── Entry Point ───────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드 (API 키 등 환경변수 읽기)
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const AidingApp(),
    ),
  );
}

// ── Main App Widget ───────────────────────────────────────────────────────────

class AidingApp extends StatefulWidget {
  const AidingApp({super.key});

  @override
  State<AidingApp> createState() => _AidingAppState();
}

class _AidingAppState extends State<AidingApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _router = GoRouter(
      // AuthProvider의 상태가 변경될 때마다 라우팅 로직을 다시 실행
      refreshListenable: authProvider,
      
      // 초기 경로
      initialLocation: '/splash',

      // ── 라우팅 규칙 정의 ──
      routes: [
        GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/', // 홈 화면
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/ai-chat', // AI 상담 화면
          builder: (context, state) => const AiChatScreen(),
        ),
      ],

      // ── 리다이렉션 로직 ──
      // 사용자의 상태(로그인 여부, 아이 정보 여부)에 따라 적절한 화면으로 자동 이동
      redirect: (BuildContext context, GoRouterState state) async {
        final isLoggedIn = authProvider.user != null;
        final currentPath = state.matchedLocation;

        // 스플래시 화면 → 항상 다음 화면으로 이동
        if (currentPath == '/splash') {
          if (!isLoggedIn) return '/login';
          final hasChildren = await _checkIfUserHasChildren(authProvider.user!);
          return hasChildren ? '/' : '/onboarding';
        }

        // 로그인 안 된 상태에서 로그인 페이지 외 접근 → 로그인으로
        if (!isLoggedIn && currentPath != '/login') {
          return '/login';
        }

        // 로그인한 상태에서 로그인 페이지 접근 → 홈 또는 온보딩으로
        if (isLoggedIn && currentPath == '/login') {
          final hasChildren = await _checkIfUserHasChildren(authProvider.user!);
          return hasChildren ? '/' : '/onboarding';
        }

        // 그 외의 경우는 그대로 둠
        return null;
      },
    );
  }
  
  // Firestore에서 아이 정보 존재 여부 확인
  Future<bool> _checkIfUserHasChildren(User user) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('children')
        .limit(1)
        .get();
    return doc.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        const Color primarySeedColor = Color(0xFF4ECDC4);
        final TextTheme appTextTheme = TextTheme(
          displayLarge: GoogleFonts.barlow(fontSize: 57, fontWeight: FontWeight.bold),
          titleLarge: GoogleFonts.notoSansKr(fontSize: 22, fontWeight: FontWeight.w500),
          bodyMedium: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.normal),
          labelLarge: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.w600),
        );

        final lightTheme = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primarySeedColor,
            brightness: Brightness.light,
          ),
          textTheme: appTextTheme,
        );

        final darkTheme = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primarySeedColor,
            brightness: Brightness.dark,
          ),
          textTheme: appTextTheme,
        );

        return MaterialApp.router(
          routerConfig: _router,
          title: '아이딩',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
        );
      },
    );
  }
}

// ── 스플래시 화면 ─────────────────────────────────────────────────────────────
// 앱이 시작될 때 잠깐 보여지는 로딩 화면
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF4ECDC4),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '아이딩',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 6,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '육아용품 AI 추천',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
