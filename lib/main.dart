// ГЛАВНЫЙ ФАЙЛ ПРИЛОЖЕНИЯ
// Содержит маршруты для всех экранов и логику таймаута сеанса (3 минуты)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Экраны верификации и регистрации
import 'screens/verification/verification_screen.dart';
import 'screens/registration/registration_screen.dart';
import 'screens/registration/registration_confirm_screen.dart';
import 'screens/registration/registration_success_screen.dart';

// Экраны восстановления пароля
import 'screens/password_recovery/recovery_email_screen.dart';
import 'screens/password_recovery/recovery_check_email_screen.dart';
import 'screens/password_recovery/recovery_new_password_screen.dart';
import 'screens/password_recovery/recovery_success_screen.dart';

// Основные экраны приложения
import 'screens/monitor/monitor_screen.dart';
import 'screens/devices/devices_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/charts/charts_screen.dart';

// Модели
import 'models/device_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _backgroundTime;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Проверка авторизации при запуске
  Future<void> _checkInitialAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuth = prefs.getBool('is_authenticated') ?? false;
    final token = prefs.getString('auth_token');

    if (isAuth && token != null) {
      navigatorKey.currentState?.pushReplacementNamed('/monitor');
    } else {
      navigatorKey.currentState?.pushReplacementNamed('/verification');
    }
  }

  // Обработка жизненного цикла приложения (таймаут сеанса 3 минуты)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      _backgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundTime != null) {
        final difference = DateTime.now().difference(_backgroundTime!);
        if (difference.inMinutes >= 3) {
          _sessionTimeout();
        }
        _backgroundTime = null;
      }
    }
  }

  // Обработка таймаута сеанса
  Future<void> _sessionTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.setBool('is_authenticated', false);

    if (navigatorKey.currentContext != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Сеанс завершен'),
          content: const Text('Ваш сеанс был автоматически завершен из-за неактивности (3 минуты).'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                navigatorKey.currentState?.pushReplacementNamed('/verification');
              },
              child: const Text('Войти снова'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radio Monitor',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/verification',
      routes: {
        // Экраны авторизации и регистрации
        '/verification': (context) => const VerificationScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/registration/confirm': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return RegistrationConfirmScreen(email: email);
        },
        '/registration/success': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return RegistrationSuccessScreen(email: email);
        },

        // Экраны восстановления пароля
        '/recovery/email': (context) => const RecoveryEmailScreen(),
        '/recovery/check-email': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return RecoveryCheckEmailScreen(email: email);
        },
        '/recovery/new-password': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return RecoveryNewPasswordScreen(email: email);
        },
        '/recovery/success': (context) => const RecoverySuccessScreen(),

        // Основные экраны приложения
        '/monitor': (context) => const MonitorScreen(),
        '/devices': (context) => const DevicesScreen(),
        '/profile': (context) => const ProfileScreen(),

        // Экран графиков (требует передачи device)
        '/charts': (context) {
          // ВНИМАНИЕ: этот маршрут больше не используется напрямую
          // Графики открываются через Navigator.push с передачей device и frequency
          // Оставляем для обратной совместимости
          final device = ModalRoute.of(context)?.settings.arguments as Device;
          return const SizedBox.shrink(); // или можно вернуть заглушку
        },
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const VerificationScreen(),
        );
      },
    );
  }
}
