// ЭКРАН РЕГИСТРАЦИИ 3
// Сообщает, что email подтвержден
// Круглая иконка с выходом из приложения (ведет на экран верификации)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  final String email;

  const RegistrationSuccessScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  // Выход из приложения → экран верификации
  void _logoutToVerification(BuildContext context) async {
    // Очищаем возможные данные сессии (на всякий случай)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.setBool('is_authenticated', false);

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/verification', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Регистрация',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        // Круглая иконка справа вверху → выход
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: Icon(Icons.logout, size: 16, color: Colors.white),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _logoutToVerification(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Выйти из приложения'),
              ),
            ],
          ),
        ],
        // Стрелка назад → на экран верификации
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _logoutToVerification(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),

            // Заголовок
            const Text(
              'E-mail подтвержден',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Текст более мелким шрифтом
            Text(
              'Начните вносить данные о радиостанциях\nдля мониторинга качества эфира',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Email пользователя
            Text(
              email,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.deepPurple,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 48),

            // Кнопка для перехода на экран верификации (дополнительная опция)
            OutlinedButton.icon(
              onPressed: () => _logoutToVerification(context),
              icon: const Icon(Icons.login),
              label: const Text('Перейти к входу'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}