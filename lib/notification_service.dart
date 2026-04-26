//kh

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';

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
    // Set local timezone to Malaysia
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    } catch (e) {
      debugPrint("Timezone error: $e");
    }

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // Show immediate notification
  Future<void> showNotification(int id, String title, String body) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'med_channel', 
          'Medicine Alarms',
          channelDescription: 'Channel for Medicine Reminders',
          importance: Importance.max, 
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
  }

  // Schedule a daily or weekly reminder at a specific time
  Future<void> scheduleMedicineReminder(int id, String name, String dose, String timeStr, String frequency) async {
    try {
      // Parse time string (e.g., "9:00 AM")
      final DateFormat format = DateFormat.jm();
      final DateTime parsedTime = format.parse(timeStr);
      
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        parsedTime.hour,
        parsedTime.minute,
      );
      
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        "Medicine Reminder: $name",
        "It's time to take your $dose of $name.",
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'med_channel',
            'Medicine Alarms',
            importance: Importance.max,
            priority: Priority.high,
            channelShowBadge: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: frequency == 'Daily' 
            ? DateTimeComponents.time 
            : DateTimeComponents.dayOfWeekAndTime,
      );
      debugPrint("Scheduled $name at $scheduledDate");
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
