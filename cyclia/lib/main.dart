import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize local date formatting for French calendar
    await initializeDateFormatting('fr_FR', null);
    
    // Initialize Notifications
    await NotificationService().init();
  } catch (e) {
    debugPrint("Initialization error: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cyclia',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'), // French
        Locale('en', 'US'), // English
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E24AA), // Purple
          primary: const Color(0xFF8E24AA),
          secondary: const Color(0xFFE91E63), // Pink
        ),
        fontFamily: 'Outfit', // Uses fallback system font if not loaded, clean rounded style
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  
  bool _checking = true;
  Widget _targetScreen = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        // Attempt to fetch cycles with a slight retry logic
        List<dynamic>? cycles = await _apiService.getCycles();
        if (cycles == null) {
           await Future.delayed(const Duration(milliseconds: 800));
           cycles = await _apiService.getCycles();
        }

        if (cycles != null && cycles.isNotEmpty) {
          _targetScreen = DashboardScreen();
        } else if (cycles != null && cycles.isEmpty) {
          _targetScreen = OnboardingScreen();
        } else {
          // If still null, might be a token issue, go to Login
          _targetScreen = LoginScreen();
        }
      } else {
        _targetScreen = LoginScreen();
      }
    } catch (e) {
      debugPrint("Auth check error: $e");
      _targetScreen = LoginScreen();
    }
    
    if (mounted) {
      setState(() {
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF7FC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo placeholder
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.8, end: 1.1),
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOutSine,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                onEnd: () {
                  // This creates a breathing effect while checking status
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E24AA).withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.spa_rounded,
                        size: 60,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  color: Color(0xFF8E24AA),
                  backgroundColor: Colors.white,
                  minHeight: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _targetScreen;
  }
}
