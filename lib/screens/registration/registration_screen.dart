// ЭКРАН РЕГИСТРАЦИИ 1

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_service.dart';
import '../../services/local_storage_service.dart';
import 'registration_confirm_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();

  String? _emailError;
  String? _passwordMatchError;
  String? _latinError;
  String? _generalError;  // Общая ошибка (показываем у кнопки)
  bool _isLoading = false;

  bool _isLatinAndDigitsOnly(String value) {
    return RegExp(r'^[a-zA-Z0-9!@#\$%\^&\*\(\)\-_=+\[\]{};:,.<>/?\\|`~]*$').hasMatch(value);
  }

  Future<void> _register() async {
    // Сброс ошибок
    setState(() {
      _emailError = null;
      _passwordMatchError = null;
      _latinError = null;
      _generalError = null;
    });

    // Валидация формы
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Проверка на кириллицу в пароле
    if (!_isLatinAndDigitsOnly(password)) {
      setState(() {
        _latinError = 'Введите пароль с использованием латиницы и/или цифр';
      });
      return;
    }

    // Проверка совпадения паролей
    if (password != confirmPassword) {
      setState(() {
        _passwordMatchError = 'Пароли не совпадают';
      });
      _passwordController.clear();
      _confirmPasswordController.clear();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final exists = await _db.userExists(email);

      if (exists) {
        setState(() {
          _generalError = 'Пользователь с таким почтовым адресом уже зарегистрирован';
          _isLoading = false;
        });
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        return;
      }

      final created = await _db.createUser(email, password);

      if (!created) {
        setState(() {
          _generalError = 'Ошибка регистрации. Попробуйте позже.';
          _isLoading = false;
        });
        return;
      }

      // Успешная регистрация
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationConfirmScreen(email: email),
        ),
      );

      setState(() => _isLoading = false);

    } catch (e) {
      setState(() {
        _generalError = 'Ошибка соединения. Проверьте интернет и попробуйте позже.';
        _isLoading = false;
      });
      print('❌ Ошибка регистрации: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Регистрация',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Поле E-mail
                const Text(
                  'E-mail',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Введите адрес почты',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: _emailError,  // Ошибка только для email
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

                // Поле Пароль
                const Text(
                  'Пароль',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Придумайте пароль',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  maxLength: 255,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен содержать не менее 6 символов';
                    }
                    return null;
                  },
                ),

                if (_latinError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _latinError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),

                const SizedBox(height: 16),

                // Поле Подтверждение пароля
                const Text(
                  'Подтверждение пароля',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Повторно введите пароль',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  maxLength: 255,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Подтвердите пароль';
                    }
                    return null;
                  },
                ),

                if (_passwordMatchError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _passwordMatchError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),

                const SizedBox(height: 32),

                // === ОБЩАЯ ОШИБКА (НАД КНОПКОЙ) ===
                if (_generalError != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _generalError!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Кнопка «Зарегистрироваться»
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Зарегистрироваться'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}