import 'package:flutter/material.dart';
import 'package:yandex_mapkit_demo/presentation/map_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Yandex Mapkit Demo',
      home: MapScreen(),
    );
  }
}
