package com.example.flutter_yandex_mapkit_example

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import com.yandex.mapkit.MapKitFactory

class MainActivity: FlutterActivity() {
  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    MapKitFactory.setApiKey("b505015c-8c0a-4a4f-93be-3ca6a6d57ee2") 
    super.configureFlutterEngine(flutterEngine)
  }
}