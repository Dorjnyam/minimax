import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'app/baigalaa_app.dart';
import 'features/overlay/presentation/baigalaa_overlay_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FlutterForegroundTask.initCommunicationPort();
  }
  runApp(const BaigalaaApp());
}

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BaigalaaOverlayApp());
}
