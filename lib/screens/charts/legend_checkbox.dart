// Виджет легенды графика с чекбоксами для включения/выключения линий
// Пользователь может выбрать, какие частоты показывать на графике

import 'package:flutter/material.dart';

class FrequencyLegendItem {
  final int frequencyId;
  final String name;
  final double frequencyValue;
  final Color color;
  bool isVisible;

  FrequencyLegendItem({
    required this.frequencyId,
    required this.name,
    required this.frequencyValue,
    required this.color,
    this.isVisible = true,
  });

  String get displayName => '${frequencyValue.toStringAsFixed(1)} $name';
}

class ChartLegend extends StatelessWidget {
  final List<FrequencyLegendItem> items;
  final Function(int frequencyId, bool isVisible) onVisibilityChanged;

  const ChartLegend({
    Key? key,
    required this.items,
    required this.onVisibilityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: item.isVisible,
                  onChanged: (value) {
                    onVisibilityChanged(item.frequencyId, value ?? true);
                  },
                  activeColor: item.color,
                ),
                const SizedBox(width: 4),
                Text(
                  item.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: item.isVisible ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}