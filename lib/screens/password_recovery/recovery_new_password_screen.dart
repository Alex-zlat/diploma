// ЭКРАН ВОССТАНОВЛЕНИЯ ПАРОЛЯ 3
// Заголовок "Восстановим пароль"
// Поля: E-mail (заполнен автоматически), Новый пароль, Подтверждение пароля
// Кнопка "Обновить пароль"

import 'package:flutter/material.dart';
import 'recovery_success_screen.dart';

class RecoveryNewPasswordScreen extends StatefulWidget {
  final String email;

  const RecoveryNewPasswordScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<RecoveryNewPasswordScreen> createState() => _RecoveryNewPasswordScreenState();
}

class _RecoveryNewPasswordScreenState extends State<RecoveryNewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String? _passwordError;
  String? _cyrillicError;
  bool _isLoading = false;

  // Валидация: только латиница и цифры
  bool _isLatinAndDigitsOnly(String value) {
    return RegExp(r'^[a-zA-Z0-9!@#\$%\^&\*\(\)\-_=+\[\]{};:,.<>/?\\|`~]*$').hasMatch(value);
  }

  Future<void> _updatePassword() async {
    // Сбрасываем предыдущие ошибки
    setState(() {
      _passwordError = null;
      _cyrillicError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final newPassword = _passwordController.text.trim();

    // Проверка на кириллицу
    if (!_isLatinAndDigitsOnly(newPassword)) {
      setState(() {
        _cyrillicError = 'Введите пароль с использованием латиницы и/или цифр';
      });
      return;
    }

    // Проверка совпадения паролей
    if (newPassword != _confirmPasswordController.text.trim()) {
      setState(() {
        _passwordError = 'Пароли не совпадают';
      });
      // Очищаем поля паролей для нового ввода
      _passwordController.clear();
      _confirmPasswordController.clear();
      return;
    }

    setState(() => _isLoading = true);

    // ЗАГЛУШКА: имитация отправки на сервер
    await Future.delayed(const Duration(seconds: 1));
    print('Пароль обновлен для email: ${widget.email}');
    print('Новый пароль: $newPassword');

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RecoverySuccessScreen(),
      ),
    );
    // КОНЕЦ ЗАГЛУШКИ

    setState(() => _isLoading = false);
  }

  /* КОД ДЛЯ РЕАЛЬНОГО API
  Future<void> _updatePasswordReal() async {
    setState(() {
      _passwordError = null;
      _cyrillicError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final newPassword = _passwordController.text.trim();

    if (!_isLatinAndDigitsOnly(newPassword)) {
      setState(() {
        _cyrillicError = 'Введите пароль с использованием латиницы и/или цифр';
      });
      return;
    }

    if (newPassword != _confirmPasswordController.text.trim()) {
      setState(() {
        _passwordError = 'Пароли не совпадают';
      });
      _passwordController.clear();
      _confirmPasswordController.clear();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Отправка нового пароля на сервер
      // await dio.post('/api/auth/reset-password', data: {
      //   'email': widget.email,
      //   'password': newPassword,
      //   'token': _resetToken, // токен из deep link
      // });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RecoverySuccessScreen()),
      );
    } catch (e) {
      setState(() {
        _passwordError = 'Ошибка при обновлении пароля. Попробуйте позже.';
      });
    }

    setState(() => _isLoading = false);
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Восстановим пароль',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        // Стрелка назад → на экран 1 (согласно твоему ответу)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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

                // Поле E-mail (заполнено, неактивно)
                const Text(
                  'E-mail',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 20, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        widget.email,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Заголовок «Новый пароль»
                const Text(
                  'Новый пароль',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Поле «Новый пароль»
                const Text(
                  'Новый пароль',
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
                      return 'Введите новый пароль';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен содержать не менее 6 символов';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Поле «Подтверждение пароля»
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
                      return 'Подтвердите новый пароль';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // Ошибки (красные буквы)
                if (_cyrillicError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _cyrillicError!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),

                if (_passwordError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _passwordError!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),

                const SizedBox(height: 24),

                // Кнопка «Обновить пароль»
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePassword,
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Обновить пароль'),
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