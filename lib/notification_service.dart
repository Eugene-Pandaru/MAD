///kh

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _internal = NotificationService._();
  factory NotificationService() => _internal;
  NotificationService._();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    tz.initializeTimeZones();
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Use this to trigger an alarm 10 seconds after adding a medicine (for testing)
  Future<void> scheduleNotification(int id, String title, String body) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)), // 10s delay
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'med_channel', 'Medicine Alarms',
          importance: Importance.max, priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}