import 'dart:math';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:yandex_mapkit_demo/data/map_point.dart';
import 'package:yandex_mapkit_demo/presentation/clusterized_icon_painter.dart';
import 'package:yandex_mapkit_demo/presentation/settings_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// Контроллер для управления картами
  late final YandexMapController _mapController;

  /// Значение текущего масштаба карты
  var _mapZoom = 0.0;

  /// Данные о местоположении пользователя
  CameraPosition? _userLocation;

  /// Список точек на карте, по которым строится выделенная область
  List<Point>? _polygonPointsList;

  /// Список точек на карте, по которым строится автомобильный маршрут
  List<Point> _drivingPointsList = [];

  /// Результаты поиска маршрутов на карте
  DrivingResultWithSession? _drivingResultWithSession;

  /// Список объектов линий на карте, которые отображают маршруты
  List<MapObject> _drivingMapLines = [];

  @override
  void dispose() {
    _mapController.dispose();
    _drivingResultWithSession?.session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yandex Mapkit Demo'),
        actions: [
          IconButton(
            onPressed: () async {
              _polygonPointsList = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
              setState(() {});
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: YandexMap(
        onMapCreated: (controller) async {
          _mapController = controller;
          await _initLocationLayer();
        },
        onCameraPositionChanged: (cameraPosition, _, __) {
          setState(() {
            _mapZoom = cameraPosition.zoom;
          });
        },
        onMapLongTap: (argument) {
          setState(() {
            // добавляем точку маршрута на карте, если еще не выбраны две точки
            if (_drivingPointsList.length < 2) {
              _drivingPointsList.add(argument);
            } else {
              _drivingPointsList = [];
              _drivingMapLines = [];
              _drivingResultWithSession = null;
            }

            // когда выбраны точки начала и конца,
            // получаем данные предложенных маршрутов
            if (_drivingPointsList.length == 2) {
              _drivingResultWithSession = _getDrivingResultWithSession(
                startPoint: _drivingPointsList.first,
                endPoint: _drivingPointsList.last,
              );
            }
          });

          _buildRoutes();
        },
        mapObjects: [
          _getClusterizedCollection(
            placemarks: _getPlacemarkObjects(context),
          ),
          _getPolygonMapObject(context, points: _polygonPointsList ?? []),
          ..._getDrivingPlacemarks(context, drivingPoints: _drivingPointsList),
          ..._drivingMapLines,
        ],
        onUserLocationAdded: (view) async {
          // получаем местоположение пользователя
          _userLocation = await _mapController.getUserCameraPosition();
          // если местоположение найдено, центрируем карту относительно этой точки
          if (_userLocation != null) {
            await _mapController.moveCamera(
              CameraUpdate.newCameraPosition(
                _userLocation!.copyWith(zoom: 10),
              ),
              animation: const MapAnimation(
                type: MapAnimationType.linear,
                duration: 0.3,
              ),
            );
          }
          // меняем внешний вид маркера - делаем его непрозрачным
          return view.copyWith(
            pin: view.pin.copyWith(
              opacity: 1,
            ),
          );
        },
      ),
    );
  }

  /// Метод для получения коллекции кластеризованных маркеров
  ClusterizedPlacemarkCollection _getClusterizedCollection({
    required List<PlacemarkMapObject> placemarks,
  }) {
    return ClusterizedPlacemarkCollection(
        mapId: const MapObjectId('clusterized-1'),
        placemarks: placemarks,
        radius: 50,
        minZoom: 15,
        onClusterAdded: (self, cluster) async {
          return cluster.copyWith(
            appearance: cluster.appearance.copyWith(
              opacity: 1.0,
              icon: PlacemarkIcon.single(
                PlacemarkIconStyle(
                  image: BitmapDescriptor.fromBytes(
                    await ClusterIconPainter(cluster.size)
                        .getClusterIconBytes(),
                  ),
                ),
              ),
            ),
          );
        },
        onClusterTap: (self, cluster) async {
          await _mapController.moveCamera(
            animation: const MapAnimation(
                type: MapAnimationType.linear, duration: 0.3),
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: cluster.placemarks.first.point,
                zoom: _mapZoom + 1,
              ),
            ),
          );
        });
  }

  /// Метод, который включает слой местоположения пользователя на карте
  /// Выполняется проверка на доступ к местоположению, в случае отсутствия
  /// разрешения - выводит сообщение
  Future<void> _initLocationLayer() async {
    final locationPermissionIsGranted =
        await Permission.location.request().isGranted;

    if (locationPermissionIsGranted) {
      await _mapController.toggleUserLayer(visible: true);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет доступа к местоположению пользователя'),
          ),
        );
      });
    }
  }

  /// Метод построения маршрутов линиями на карте
  /// Получает список возможных маршрутов и добавляет их линиями на карту
  Future<void> _buildRoutes() async {
    final drivingResult = await _drivingResultWithSession?.result;

    setState(() {
      for (var element in drivingResult?.routes ?? []) {
        _drivingMapLines.add(
          PolylineMapObject(
            mapId: MapObjectId('route $element'),
            polyline: Polyline(points: element.geometry),
            strokeColor:
                // генерируем случайный цвет для каждого маршрута
                Colors.primaries[Random().nextInt(Colors.primaries.length)],
            strokeWidth: 3,
          ),
        );
      }
    });
  }
}

/// Метод для генерации точек на карте
List<MapPoint> _getMapPoints() {
  return const [
    MapPoint(name: 'Москва', latitude: 55.755864, longitude: 37.617698),
    MapPoint(name: 'Лондон', latitude: 51.507351, longitude: -0.127696),
    MapPoint(name: 'Рим', latitude: 41.887064, longitude: 12.504809),
    MapPoint(name: 'Париж', latitude: 48.856663, longitude: 2.351556),
    MapPoint(name: 'Стокгольм', latitude: 59.347360, longitude: 18.341573),
  ];
}

/// Метод для генерации объектов маркеров для отображения на карте
List<PlacemarkMapObject> _getPlacemarkObjects(BuildContext context) {
  return _getMapPoints()
      .map(
        (point) => PlacemarkMapObject(
          mapId: MapObjectId('MapObject $point'),
          point: Point(latitude: point.latitude, longitude: point.longitude),
          opacity: 1,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage(
                'assets/icons/map_point.png',
              ),
              scale: 2,
            ),
          ),
          onTap: (_, __) => showModalBottomSheet(
            context: context,
            builder: (context) => _ModalBodyView(
              point: point,
            ),
          ),
        ),
      )
      .toList();
}

/// Метод для генерации точек начала и конца маршрута
List<PlacemarkMapObject> _getDrivingPlacemarks(
  BuildContext context, {
  required List<Point> drivingPoints,
}) {
  return drivingPoints
      .map(
        (point) => PlacemarkMapObject(
          mapId: MapObjectId('MapObject $point'),
          point: Point(latitude: point.latitude, longitude: point.longitude),
          opacity: 1,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage(
                'assets/icons/car_point.png',
              ),
              scale: 2,
            ),
          ),
        ),
      )
      .toList();
}

/// Метод для генерации объекта выделенной зоны на карте
PolygonMapObject _getPolygonMapObject(
  BuildContext context, {
  required List<Point> points,
}) {
  return PolygonMapObject(
    mapId: const MapObjectId('polygon map object'),
    polygon: Polygon(
      // внешняя линия зоны
      outerRing: LinearRing(
        points: points,
      ),
      // внутренняя линия зоны, которая формирует пропуски в полигоне
      innerRings: const [],
    ),
    strokeColor: Colors.blue,
    strokeWidth: 3.0,
    fillColor: Colors.blue.withOpacity(0.2),
    onTap: (_, point) => showModalBottomSheet(
      context: context,
      builder: (context) => _ModalBodyView(
        point: MapPoint(
          name: 'Неизвестный населенный пункт',
          latitude: point.latitude,
          longitude: point.longitude,
        ),
      ),
    ),
  );
}

/// Метод для получения маршрутов проезда от точки начала к точке конца
DrivingResultWithSession _getDrivingResultWithSession({
  required Point startPoint,
  required Point endPoint,
}) {
  var drivingResultWithSession = YandexDriving.requestRoutes(
    points: [
      RequestPoint(
        point: startPoint,
        requestPointType: RequestPointType.wayPoint, // точка начала маршрута
      ),
      RequestPoint(
        point: endPoint,
        requestPointType: RequestPointType.wayPoint, // точка конца маршрута
      ),
    ],
    drivingOptions: const DrivingOptions(
      initialAzimuth: 0,
      routesCount: 5,
      avoidTolls: true,
      avoidPoorConditions: true,
    ),
  );

  return drivingResultWithSession;
}

/// Содержимое модального окна с информацией о точке на карте
class _ModalBodyView extends StatelessWidget {
  const _ModalBodyView({required this.point});

  final MapPoint point;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(point.name, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          Text(
            '${point.latitude}, ${point.longitude}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
