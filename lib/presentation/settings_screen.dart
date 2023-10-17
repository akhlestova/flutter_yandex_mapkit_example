import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

/// Экран с настройками формирования списка точек
/// для построения выделенной области на карте
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Список контроллеров для редактирования широты
  late List<TextEditingController> _latControllers;

  /// Список контроллеров для редактирования долготы
  late List<TextEditingController> _lonControllers;

  /// Количество точек на карте
  var _pointCount = 3;

  @override
  void initState() {
    super.initState();
    // создаем список контроллеров для текстовых полей координат,
    // при инициализации добавляем три точки
    _latControllers = _getTextControllersList(_pointCount);
    _lonControllers = _getTextControllersList(_pointCount);
  }

  @override
  void dispose() {
    // отключаем все созданные контроллеры текстовых координат
    for (final controller in _latControllers) {
      controller.dispose();
    }
    for (final controller in _lonControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings Screen')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...List.generate(
                    _pointCount,
                    (index) => _LatLongTextFields(
                      latController: _latControllers[index],
                      lonController: _lonControllers[index],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    child: const Text('Отобразить область'),
                    onPressed: () {
                      Navigator.pop(context, _getPointsFromText());
                    },
                  )
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'add',
                    child: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        _pointCount++;
                        _latControllers.add(TextEditingController());
                        _lonControllers.add(TextEditingController());
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: 'remove',
                    child: const Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        _pointCount--;
                        _latControllers.removeLast();
                        _lonControllers.removeLast();
                      });
                    },
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Метод для формирования списка контроллеров по количеству полей
  List<TextEditingController> _getTextControllersList(int count) {
    return List.generate(count, (index) => TextEditingController());
  }

  /// Метод для формирования списка точек по введенным координатам в текстовые поля
  List<Point> _getPointsFromText() {
    final points = <Point>[];
    for (int index = 0; index < _pointCount; index++) {
      final doubleLat = double.tryParse(_latControllers[index].text);
      final doubleLon = double.tryParse(_lonControllers[index].text);

      if (doubleLat != null && doubleLon != null) {
        points.add(Point(latitude: doubleLat, longitude: doubleLon));
      }
    }
    return points;
  }
}

/// Виджет, состоящий из текстовых полей для редактирования широты и долготы
class _LatLongTextFields extends StatelessWidget {
  const _LatLongTextFields({
    required this.latController,
    required this.lonController,
  });

  /// Контроллер для редактирования широты
  final TextEditingController latController;

  /// Контроллер для редактирования долготы
  final TextEditingController lonController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: latController,
            decoration: const InputDecoration(
              labelText: 'Широта',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: lonController,
            decoration: const InputDecoration(
              labelText: 'Долгота',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}
