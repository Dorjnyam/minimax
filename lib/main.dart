import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'app/baigalaa_app.dart';
import 'features/overlay/presentation/baigalaa_overlay_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FlutterForegroundTask.initCommunicationPort();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ulaanbaatar'));
  }
  runApp(const BaigalaaApp());
}

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BaigalaaOverlayApp());
}
