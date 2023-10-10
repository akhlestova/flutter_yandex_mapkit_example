import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:yandex_mapkit_demo/data/map_point.dart';
import 'package:yandex_mapkit_demo/presentation/clusterized_icon_painter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final YandexMapController _mapController;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yandex Mapkit Demo')),
      body: YandexMap(
        onMapCreated: (controller) async {
          _mapController = controller;
          // приближаем вид карты ближе к Европе
          await _mapController.moveCamera(
            CameraUpdate.newCameraPosition(
              const CameraPosition(
                target: Point(
                  latitude: 50,
                  longitude: 20,
                ),
                zoom: 3,
              ),
            ),
          );
        },
        mapObjects: [
          _getClusterizedCollection(
            placemarks: _getPlacemarkObjects(context),
          ),
        ],
      ),
    );
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

/// Метод для получения коллекции кластеризованных маркеров
ClusterizedPlacemarkCollection _getClusterizedCollection({
  required List<PlacemarkMapObject> placemarks,
  YandexMapController? mapController,
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
                  await ClusterIconPainter(cluster.size).getClusterIconBytes(),
                ),
              ),
            ),
          ),
        );
      },
      onClusterTap: (self, cluster) async {
        await mapController?.moveCamera(CameraUpdate.zoomIn());
      });
}

/// Содержимое модального окна с информацией о точке на карте
class _ModalBodyView extends StatelessWidget {
  const _ModalBodyView({required this.point});

  final MapPoint point;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(point.name, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 20),
        Text(
          '${point.latitude}, ${point.longitude}',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ]),
    );
  }
}
