// Переиспользуемые виджеты для всех экранов устройств
// Содержит: BottomNavigationBar, PopupMenuButton для выхода,
//           кнопки со стрелками (таймауты), диалоги удаления

import 'package:flutter/material.dart';

// 1. Футер с меню
class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.monitor),
          label: 'Монитор',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.devices),
          label: 'Устройства',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Профиль',
        ),
      ],
    );
  }
}

// 2. Кружок выхода (сверху справа)
class LogoutCircleButton extends StatelessWidget {
  const LogoutCircleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.person, size: 16),
      ),
      onSelected: (value) {
        if (value == 'logout') {
          // Выход на экран верификации
          Navigator.pushNamedAndRemoveUntil(context, '/verification', (route) => false);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'logout',
          child: Text('Выйти'),
        ),
      ],
    );
  }
}

// 3. Виджет для ввода таймаута со стрелками
class TimeoutInputWithArrows extends StatefulWidget {
  final String title;
  final String hint;
  final int value;
  final Function(int) onChanged;

  const TimeoutInputWithArrows({
    Key? key,
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<TimeoutInputWithArrows> createState() => _TimeoutInputWithArrowsState();
}

class _TimeoutInputWithArrowsState extends State<TimeoutInputWithArrows> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant TimeoutInputWithArrows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  void _updateValue(int newValue) {
    if (newValue < 0) newValue = 0;
    widget.onChanged(newValue);
    _controller.text = newValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  // Поле ввода
                  TextFormField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final intValue = int.tryParse(value);
                      if (intValue != null && intValue >= 0) {
                        widget.onChanged(intValue);
                      }
                    },
                  ),
                  // Стрелки внутри поля справа
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _updateValue(widget.value + 1),
                          child: const Icon(
                            Icons.arrow_drop_up,
                            size: 24,
                            color: Colors.grey,
                          ),
                        ),
                        InkWell(
                          onTap: () => widget.value > 0 ? _updateValue(widget.value - 1) : null,
                          child: Icon(
                            Icons.arrow_drop_down,
                            size: 24,
                            color: widget.value > 0 ? Colors.grey : Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// 4. Диалоговое окно 1: удаление устройства
Future<void> showDeleteDeviceDialog(
    BuildContext context, {
      required int deviceId,
      required String deviceCity,
      required VoidCallback onDelete,
    }) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Удаление устройства'),
      content: Text(
        'Вы уверены, что хотите удалить устройство "$deviceCity"?\n\n'
            'После выбора этой опции устройство со всеми радиостанциями на нем '
            'прекратит отслеживаться.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отменить'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDelete();
          },
          child: const Text('Удалить', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

// 5. Диалоговое окно 2: удаление частоты
Future<void> showDeleteFrequencyDialog(
    BuildContext context, {
      required int frequencyId,
      required String frequencyName,
      required VoidCallback onDelete,
    }) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Удаление частоты'),
      content: Text(
        'Вы уверены, что хотите удалить частоту "$frequencyName"?\n\n'
            'После выбора этой опции устройство прекратит отслеживать данную частоту.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отменить'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDelete();
          },
          child: const Text('Удалить', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}