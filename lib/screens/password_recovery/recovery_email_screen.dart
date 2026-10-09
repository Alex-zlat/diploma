// ЭКРАН ВОССТАНОВЛЕНИЯ ПАРОЛЯ 1
// Заголовок "Восстановим пароль"
// Поле для ввода зарегистрированного e-mail
// Кнопка "Выслать пароль"

import 'package:flutter/material.dart';
import 'recovery_check_email_screen.dart';
import '../../services/database_service.dart';

class RecoveryEmailScreen extends StatefulWidget {
  const RecoveryEmailScreen({Key? key}) : super(key: key);

  @override
  State<RecoveryEmailScreen> createState() => _RecoveryEmailScreenState();
}

class _RecoveryEmailScreenState extends State<RecoveryEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();

    try {
      final db = DatabaseService();
      final exists = await db.userExists(email);

      if (exists) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecoveryCheckEmailScreen(email: email),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Введите корректный адрес почты, указанный при регистрации';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка соединения. Попробуйте позже.';
        _isLoading = false;
      });
      print('❌ Ошибка восстановления пароля: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Восстановим пароль',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
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
                'Введите зарегистрированный e-mail',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Почтовый адрес',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                maxLength: 255,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите адрес электронной почты';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Введите корректный email адрес';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetCode,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Выслать пароль'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}