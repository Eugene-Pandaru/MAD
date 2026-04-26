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
    // Use try-catch to handle potential timezone initialization issues
    try {
       tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    } catch (e) {
      debugPrint("Timezone error: $e");
    }

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint("Notification tapped: ${response.payload}");
      },
    );
  }

  Future<void> requestPermissions() async {
    final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // Show immediate notification
  Future<void> showNotification(int id, String title, String body, {String? payload}) async {
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
          fullScreenIntent: true, // Try to show a more prominent alert
        ),
      ),
      payload: payload,
    );
  }

  // Schedule a daily or weekly reminder at a specific time
  Future<void> scheduleMedicineReminder(int id, String name, String dose, String timeStr, String frequency) async {
    try {
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
            playSound: true,
            styleInformation: BigTextStyleInformation(''),
            category: AndroidNotificationCategory.alarm,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: frequency == 'Daily' 
            ? DateTimeComponents.time 
            : DateTimeComponents.dayOfWeekAndTime,
        payload: 'reminder_$id',
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
