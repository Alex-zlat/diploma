// ЭКРАН ВЕРИФИКАЦИИ (Войти)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../password_recovery/recovery_email_screen.dart';
import '../registration/registration_screen.dart';
import '../monitor/monitor_screen.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../services/local_storage_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  int _failedAttempts = 0;
  bool _isLoading = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();

  final DatabaseService _db = DatabaseService();
  final LocalStorageService _storage = LocalStorageService();

  Future<void> _saveUserSession(String email, String token, {int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', email);
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('auth_token');
    }
    await prefs.setBool('is_authenticated', true);
    await prefs.setString('user_email', email);
    if (userId != null) {
      await prefs.setInt('user_id', userId);
    }
  }

  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.setBool('is_authenticated', false);
    await prefs.remove('user_id');
  }

  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuth = prefs.getBool('is_authenticated') ?? false;
    final token = prefs.getString('auth_token');
    return isAuth && token != null;
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedToken = prefs.getString('auth_token');

    if (savedEmail != null && savedToken != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final user = await _db.getUser(email, password);

      if (user != null) {
        final userId = user['id'] as int;
        final dummyToken = 'token_${DateTime.now().millisecondsSinceEpoch}';

        await _saveUserSession(email, dummyToken, userId: userId);

        setState(() {
          _failedAttempts = 0;
          _errorMessage = null;
          _isLoading = false;
        });

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MonitorScreen()),
        );
      } else {
        setState(() {
          _failedAttempts++;
          _errorMessage = 'Неверные логин и/или пароль. Пожалуйста, введите корректные данные';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка соединения. Попробуйте позже.';
        _isLoading = false;
      });
      print('❌ Ошибка входа: $e');
    }
  }

  void _goToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    );
  }

  void _goToPasswordRecovery() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecoveryEmailScreen()),
    );
  }

  Future<void> _biometricLogin() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Биометрическая аутентификация будет доступна в следующей версии'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Войти',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person_add, size: 16, color: Colors.white),
            ),
            onSelected: (value) {
              if (value == 'register') {
                _goToRegistration();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'register',
                child: Text('Регистрация'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                'Введите свой e-mail',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'example@mail.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите e-mail';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Введите корректный e-mail';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              const Text(
                'Введите пароль',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: '••••••••',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),

              if (_failedAttempts >= 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _goToPasswordRecovery,
                        child: const Text(
                          'Забыли пароль?',
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: _goToRegistration,
                        child: const Text(
                          'Зарегистрироваться',
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Вход'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Запомнить'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Center(
                child: IconButton(
                  onPressed: _biometricLogin,
                  icon: const Icon(
                    Icons.fingerprint,
                    size: 48,
                    color: Colors.deepPurple,
                  ),
                  tooltip: 'Войти по отпечатку пальца / Face ID',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}