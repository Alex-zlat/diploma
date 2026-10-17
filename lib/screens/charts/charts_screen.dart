// ЭКРАН «ГРАФИКИ»
//
// Отображает 4 графика для выбранной частоты:
// 1. Online время устройства
// 2. Volume по частотам
// 3. RSSI по частотам
//
// Возможности:
// - Включение/выключение линий частот через легенду с чекбоксами
// - Zoom и pan графика
// - Загрузка реальных данных с сервера

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/chart_data_service.dart';
import '../../models/device_model.dart';
import '../../models/frequency_model.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/common_widgets.dart';
import 'legend_checkbox.dart';

// Тип активного графика
enum ChartType { online, volume, rssi }

class ChartsScreen extends StatefulWidget {
  final Device device;
  final Frequency frequency;

  const ChartsScreen({
    Key? key,
    required this.device,
    required this.frequency,
  }) : super(key: key);

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final LocalStorageService _storage = LocalStorageService();
  final ChartDataService _dataService = ChartDataService();

  ChartType _activeChartType = ChartType.online;

  // Данные для графиков
  List<DeviceOnlineData> _onlineData = [];
  List<ChartDataPoint> _volumeData = [];
  List<ChartDataPoint> _rssiData = [];

  // Частоты устройства (только одна)
  List<Frequency> _frequencies = [];

  // Легенда для каждого типа графика (только одна)
  List<FrequencyLegendItem> _volumeLegend = [];
  List<FrequencyLegendItem> _rssiLegend = [];

  bool _isLoading = true;
  String? _errorMessage;

  // Цвета для линий
  final List<Color> _chartColors = [
    const Color(0xFFB070A0),
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // ТОЛЬКО ОДНА ЧАСТОТА
    _frequencies = [widget.frequency];

    // Загружаем данные для графиков
    await _loadChartData();

    // Инициализируем легенду
    _initLegends();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadChartData() async {
    // РЕАЛЬНЫЕ ЗАПРОСЫ К СЕРВЕРУ
    // Раскомментирую, когда API будет готов

    /*
    _onlineData = await _dataService.getDeviceOnlineTime(widget.device.id!);
    _volumeData = await _dataService.getStationChartData(
      widget.device.id!,
      StationChartType.volume,
      _frequencies,
    );
    _rssiData = await _dataService.getStationChartData(
      widget.device.id!,
      StationChartType.rssi,
      _frequencies,
    );

    */

    // ЗАГЛУШКА ДЛЯ ДЕМОНСТРАЦИИ
    await Future.delayed(const Duration(milliseconds: 500));
    _onlineData = ChartDataService.getMockDeviceOnlineData();
    _volumeData = ChartDataService.getMockStationData(_frequencies, StationChartType.volume);
    _rssiData = ChartDataService.getMockStationData(_frequencies, StationChartType.rssi);
  }

  void _initLegends() {
    // Очищаем все легенды
    _volumeLegend = [];
    _rssiLegend = [];

    // ТОЛЬКО ОДНА ЧАСТОТА
    final freq = widget.frequency;
    final color = _chartColors[0];

    final item = FrequencyLegendItem(
      frequencyId: freq.id!,
      name: freq.name,
      frequencyValue: freq.frequency,
      color: color,
      isVisible: true,
    );

    _volumeLegend.add(item);
    _rssiLegend.add(item);
  }

  void _updateLegendVisibility(ChartType type, int frequencyId, bool isVisible) {
    setState(() {
      switch (type) {
        case ChartType.volume:
          final index = _volumeLegend.indexWhere((item) => item.frequencyId == frequencyId);
          if (index != -1) _volumeLegend[index].isVisible = isVisible;
          break;
        case ChartType.rssi:
          final index = _rssiLegend.indexWhere((item) => item.frequencyId == frequencyId);
          if (index != -1) _rssiLegend[index].isVisible = isVisible;
          break;
        default:
          break;
      }
    });
  }

  // Форматирование времени для оси X (добавляем ведущий ноль)
  // Форматирование времени для оси X (только число часов, без :00)
  String _formatTime(DateTime time) {
    return time.hour.toString(); // <-- Было: '${time.hour.toString().padLeft(2, '0')}:00'
  }

// Добавляем метод для определения какие метки показывать
  bool _shouldShowTitle(double value, int hourCount) {
    final index = value.toInt();

    // Показываем первую и последнюю метку всегда
    if (index == 0 || index == hourCount - 1) return true;

    // Показываем каждую 5-ю метку
    if (index % 5 == 0) return true;

    // Если 23:00 слишком близко к предыдущей метке — пропускаем
    final time = DateTime(2026, 9, 6, index);
    final nextHour = (index + 5) % 24;
    if (index >= 20 && nextHour < index) return false;

    return false;
  }

  // Построение Online графика
  Widget _buildOnlineChart() {
    if (_onlineData.isEmpty) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    final minTime = _onlineData.first.time;
    final maxTime = _onlineData.last.time;
    final totalHours = maxTime.difference(minTime).inHours + 1;

    return LineChart(
      LineChartData(
        // 3. СЕТКА: жестко привязываем вертикальные линии к меткам времени
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          verticalInterval: 1.0,
          checkToShowVerticalLine: (value) {
            final step = totalHours > 12 ? 4 : (totalHours > 6 ? 2 : 1);
            final intValue = value.round();
            return intValue % step == 0 ||
                intValue == totalHours - 1 ||
                intValue == 0;
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: const RotatedBox(
              quarterTurns: 4,
              child: Text(
                'Наличие сигнала',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            axisNameSize: 28,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: 1.0,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const Text('0', style: TextStyle(fontSize: 12));
                } else if (value == 1) {
                  return const Text('1', style: TextStyle(fontSize: 12));
                }
                return const Text('');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: totalHours > 12 ? 4.0 : (totalHours > 6 ? 2.0 : 1.0),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= totalHours) return const Text('');

                final time = minTime.add(Duration(hours: index));
                final isLast = index == totalHours - 1;
                final isFirst = index == 0;
                final step = totalHours > 12 ? 4 : (totalHours > 6 ? 2 : 1);
                final isStep = index % step == 0;

                // Показываем первую, последнюю и шаговые метки
                if (isFirst || isLast || isStep) {
                  // Сдвигаем только последнюю метку (23)
                  if (isLast) {
                    return Transform.translate(
                      offset: const Offset(-10, 0), // <-- ПАРАМЕТР: двигать влево/вправо
                      child: Text(
                        _formatTime(time),
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }

                  // Все остальные метки (первая и шаговые) без сдвига
                  return Text(
                    _formatTime(time),
                    style: const TextStyle(fontSize: 11),
                  );
                }
                return const Text('');
              },
            ),
          ),
          // 2. ПОДПИСЬ "ЧАСЫ" внутри графика справа
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) {
                // Показываем только у последней метки (справа)
                if (value.toInt() == totalHours - 1) {
                  return Transform.translate(
                    // <-- ПАРАМЕТР: двигать слово "Часы".
                    // Первое число (X): отрицательное = ВЛЕВО, положительное = ВПРАВО.
                    // Второе число (Y): положительное = ВНИЗ, отрицательное = ВВЕРХ.
                    offset: const Offset(-15, -4),
                    child: const Text(
                      'Часы',
                      style: TextStyle(
                        color: Colors.deepPurple, // Темно-зеленый
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: _onlineData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.isOnline ? 1.0 : 0.0);
            }).toList(),
            isCurved: false,
            color: const Color(0xFFB070A0),
            barWidth: 2,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.deepPurple.withOpacity(0.2),
            ),
          ),
        ],
        minY: 0,
        // 1. ПАРАМЕТР ДЛЯ ДВИЖЕНИЯ "1" ВВЕРХ/ВНИЗ:
        // Увеличиваем maxY до 1.15. Это создает "пустое" пространство сверху.
        // Чем БОЛЬШЕ число (например, 1.2), тем НИЖЕ опускается единица.
        // Чем МЕНЬШЕ число (например, 1.05), тем ВЫШЕ поднимается единица.
        maxY: 1.0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipMargin: 8,
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            getTooltipColor: (touchedSpots) => Colors.black87,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= _onlineData.length) return null;

                final time = _onlineData[index].time;
                final hour = time.hour.toString().padLeft(2, '0');
                final minute = time.minute.toString().padLeft(2, '0');

                return LineTooltipItem(
                  '$hour:$minute',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // Построение графика для частот (Volume, RSSI) — ТОЛЬКО ОДНА ЛИНИЯ
  Widget _buildStationChart(
      List<ChartDataPoint> data,
      List<FrequencyLegendItem> legend,
      String yAxisTitle,
      double minY,
      double maxY,
      ) {
    if (data.isEmpty) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    final allTimes = data.map((p) => p.time).toList();
    final minTime = allTimes.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxTime = allTimes.reduce((a, b) => a.isAfter(b) ? a : b);
    final totalHours = maxTime.difference(minTime).inHours + 1;

    final List<LineChartBarData> lineBars = [];

    if (legend.isNotEmpty && legend.first.isVisible) {
      final points = data.where((p) => p.frequencyId == legend.first.frequencyId).toList();
      if (points.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: points.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            color: const Color(0xFFB070A0), // Цвет линии
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    }

    // Определяем параметры для Volume (255) или RSSI (80)
    final isVolume = maxY == 255;
    final yInterval = isVolume ? 50.0 : 20.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          verticalInterval: 1.0,
          horizontalInterval: yInterval,
          checkToShowVerticalLine: (value) {
            final step = totalHours > 12 ? 4 : (totalHours > 6 ? 2 : 1);
            final intValue = value.round();
            return intValue % step == 0 || intValue == totalHours - 1 || intValue == 0;
          },
          checkToShowHorizontalLine: (value) {
            final intValue = value.toInt();
            if (isVolume) {
              // Линии для Volume: 50, 100, 150, 200, 250 (без 255)
              return intValue % 50 == 0 && intValue > 0 && intValue <= 250;
            } else {
              // Линии для RSSI: 20, 40, 60, 80
              return intValue % 20 == 0 && intValue > 0 && intValue <= maxY.toInt();
            }
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: RotatedBox(
              quarterTurns: 4,
              child: Text(
                yAxisTitle,
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            axisNameSize: 28,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                final intValue = value.toInt();
                if (isVolume) {
                  if (intValue == 0) return const Text('0', style: TextStyle(fontSize: 12));
                  if (intValue % 50 == 0 && intValue <= 250) {
                    return Text(intValue.toString(), style: const TextStyle(fontSize: 12));
                  }
                  if (intValue == 255) {
                    return const Text('255', style: TextStyle(fontSize: 11, color: Colors.deepPurple));
                  }
                  return const Text('');
                } else {
                  if (intValue == 0 || intValue == maxY.toInt()) {
                    return Text(intValue.toString(), style: const TextStyle(fontSize: 12));
                  }
                  return const Text('');
                }
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: totalHours > 12 ? 4.0 : (totalHours > 6 ? 2.0 : 1.0),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= totalHours) return const Text('');
                final time = minTime.add(Duration(hours: index));
                final isLast = index == totalHours - 1;
                final isFirst = index == 0;
                final step = totalHours > 12 ? 4 : (totalHours > 6 ? 2 : 1);
                final isStep = index % step == 0;

                if (isFirst || isLast || isStep) {
                  if (isLast) {
                    return Transform.translate(
                      offset: const Offset(-10, 0),
                      child: Text(time.hour.toString(), style: const TextStyle(fontSize: 11)),
                    );
                  }
                  return Text(time.hour.toString(), style: const TextStyle(fontSize: 11));
                }
                return const Text('');
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) {
                if (value.toInt() == totalHours - 1) {
                  return Transform.translate(
                    offset: const Offset(-15, -4),
                    child: const Text(
                      'Часы',
                      style: TextStyle(color: Colors.deepPurple, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: lineBars,
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipMargin: 8,
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            getTooltipColor: (touchedSpots) => Colors.black87,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= data.length) return null;
                final time = data[index].time;
                final hour = time.hour.toString().padLeft(2, '0');
                final minute = time.minute.toString().padLeft(2, '0');
                return LineTooltipItem(
                  '$hour:$minute\n${data[index].value.toStringAsFixed(1)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // Получить количество точек для оси X
  int get pointsCount {
    if (_activeChartType == ChartType.online) {
      return _onlineData.length;
    } else if (_activeChartType == ChartType.volume) {
      return _volumeData.isEmpty ? 0 : (_volumeData.map((p) => p.time).toList().reduce((a, b) => a.isAfter(b) ? a : b).difference(_volumeData.map((p) => p.time).toList().reduce((a, b) => a.isBefore(b) ? a : b)).inHours + 1);
    } else if (_activeChartType == ChartType.rssi) {
      return _rssiData.isEmpty ? 0 : (_rssiData.map((p) => p.time).toList().reduce((a, b) => a.isAfter(b) ? a : b).difference(_rssiData.map((p) => p.time).toList().reduce((a, b) => a.isBefore(b) ? a : b)).inHours + 1);
    } else {
      return 0;  //
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Tooltip(
          message: 'Графики: ${widget.frequency.name}',
          child: Text(
            'Графики: ${widget.frequency.name}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [LogoutCircleButton()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Переключатель типов графиков
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                _buildChartTypeButton(ChartType.online, 'Online'),
                _buildChartTypeButton(ChartType.volume, 'Vol'),
                _buildChartTypeButton(ChartType.rssi, 'RSSI'),
              ],
            ),
          ),

          // Заголовок второго уровня
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _getChartTitle(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 4),

          // График
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRect(
                child: _buildCurrentChart(),
              ),
            ),
          ),

          // Легенда с чекбоксами
          if (_showLegend())
            Expanded(
              flex: 1,
              child: _buildCurrentLegend(),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/devices');
          } else if (index == 2) {
            // ПЕРЕХОД НА ПРОФИЛЬ
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _buildChartTypeButton(ChartType type, String label) {
    final isActive = _activeChartType == type;

    String shortLabel;
    switch (type) {
      case ChartType.online:
        shortLabel = 'Online';
        break;
      case ChartType.volume:
        shortLabel = 'Vol';
        break;
      case ChartType.rssi:
        shortLabel = 'RSSI';
        break;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _activeChartType = type;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? Colors.deepPurple : Colors.grey.shade300,
            foregroundColor: isActive ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            minimumSize: const Size(0, 32),
          ),
          child: Text(
            shortLabel,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );
  }

  String _getChartTitle() {
    switch (_activeChartType) {
      case ChartType.online:
        return 'Online время устройства: ${widget.device.city}';
      case ChartType.volume:
        return 'Volume: ${widget.frequency.name} (${widget.frequency.frequency.toStringAsFixed(1)} МГц)';
      case ChartType.rssi:
        return 'RSSI: ${widget.frequency.name} (${widget.frequency.frequency.toStringAsFixed(1)} МГц)';
    }
  }

  Widget _buildCurrentChart() {
    switch (_activeChartType) {
      case ChartType.online:
        return _buildOnlineChart();
      case ChartType.volume:
        return _buildStationChart(
          _volumeData,
          _volumeLegend,
          'Уровень громкости от 0 до 255 (у.е.)',
          0,
          255,
        );
      case ChartType.rssi:
        return _buildStationChart(
          _rssiData,
          _rssiLegend,
          'Мощность сигнала (dBm)',
          0,
          80,
        );
    }
  }

  bool _showLegend() {
    // return _activeChartType != ChartType.online && _frequencies.isNotEmpty;
    return false;  // легенды для графиков не выводятся
  }

  Widget _buildCurrentLegend() {
    switch (_activeChartType) {
      case ChartType.volume:
        return ChartLegend(
          items: _volumeLegend,
          onVisibilityChanged: (id, isVisible) {
            _updateLegendVisibility(ChartType.volume, id, isVisible);
          },
        );
      case ChartType.rssi:
        return ChartLegend(
          items: _rssiLegend,
          onVisibilityChanged: (id, isVisible) {
            _updateLegendVisibility(ChartType.rssi, id, isVisible);
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}