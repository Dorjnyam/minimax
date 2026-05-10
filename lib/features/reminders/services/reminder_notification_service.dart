import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder.dart';
import '../domain/reminder_schedule_calculator.dart';

/// Schedules local alerts for reminders; payload is [Reminder.id].
class ReminderNotificationService {
  ReminderNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    ReminderScheduleCalculator? calculator,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _calculator = calculator ?? const ReminderScheduleCalculator();

  final FlutterLocalNotificationsPlugin _plugin;
  final ReminderScheduleCalculator _calculator;

  static const _channelId = 'baigalaa_reminders_v1';
  static const _channelName = 'Сануулга';
  static const _channelDesc = 'Товлосон цагт сануулга харуулна';

  bool _initialized = false;

  Future<void> ensureInitialized({
    void Function(String reminderId)? onTapPayload,
  }) async {
    if (kIsWeb) return;
    if (_initialized) return;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      final settings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (details) {
          final p = details.payload;
          if (p != null && p.isNotEmpty) {
            onTapPayload?.call(p);
          }
        },
      );

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ),
      );

      _initialized = true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Reminders] notification plugin init skipped: $e\n$st');
      }
      _initialized = true;
    }
  }

  /// Stable positive id for Android notification manager.
  static int notificationIdFor(String reminderId) {
    var h = reminderId.hashCode;
    if (h < 0) h = -h;
    if (h == 0) h = 1;
    return h;
  }

  Future<void> requestPermissionsIfNeeded() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final n = await Permission.notification.request();
      if (!n.isGranted && kDebugMode) {
        debugPrint('[Reminders] notification permission: $n');
      }
    }
  }

  Future<void> cancelReminder(String reminderId) async {
    if (kIsWeb) return;
    await _plugin.cancel(notificationIdFor(reminderId));
  }

  Future<void> rescheduleAll({
    required List<Reminder> reminders,
    required Set<String> pausedIds,
  }) async {
    if (kIsWeb) return;
    await requestPermissionsIfNeeded();

    for (final r in reminders) {
      await cancelReminder(r.id);
    }

    for (final r in reminders) {
      if (pausedIds.contains(r.id)) continue;
      if (r.completed) continue;
      if (r.status != 'open') continue;

      final loc = _calculator.locationFor(r);
      final nowLoc = tz.TZDateTime.now(loc);

      final next = _calculator.nextFire(reminder: r, now: nowLoc);
      if (next == null) continue;

      final daily = _isDaily(r.recurrence);
      final title = 'Сануулга';
      final body = r.alertText;

      final android = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      );
      const ios = DarwinNotificationDetails();
      final details = NotificationDetails(android: android, iOS: ios);

      try {
        await _plugin.zonedSchedule(
          notificationIdFor(r.id),
          title,
          body,
          next,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: r.id,
          matchDateTimeComponents:
              daily ? DateTimeComponents.time : null,
        );
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[Reminders] schedule failed for ${r.id}: $e\n$st');
        }
      }
    }
  }

  bool _isDaily(String recurrence) =>
      recurrence.toLowerCase() == 'daily' ||
      recurrence.toLowerCase().contains('day');
}
