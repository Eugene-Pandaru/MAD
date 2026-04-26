//kh

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mad/utility.dart';
import 'reminder_model.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _internal = NotificationService._();
  factory NotificationService() => _internal;
  NotificationService._();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _checkTimer;
  Reminder? overdueReminder;

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    tz.initializeTimeZones();
    try {
       tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    } catch (e) {
      debugPrint("Timezone error: $e");
    }

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("Notification tapped: ${response.payload}");
      },
    );

    // Start a periodic check every 30 seconds to see if any reminder is due
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      checkOverdueReminders();
    });
  }

  Future<void> checkOverdueReminders() async {
    final userId = Utils.currentUser?['id'];
    if (userId == null) return;

    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('reminders')
          .select()
          .eq('user_id', userId)
          .eq('is_taken', false);

      if (data.isNotEmpty) {
        final List<Reminder> reminders = (data as List).map((json) => Reminder.fromJson(json)).toList();
        final now = DateTime.now();
        final DateFormat format = DateFormat.jm();

        Reminder? found;
        for (var r in reminders) {
          try {
            final DateTime parsedTime = format.parse(r.time);
            final scheduledTimeToday = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
            
            // If it's time or past due today (within today)
            if (now.isAfter(scheduledTimeToday) && now.day == scheduledTimeToday.day) {
               found = r;
               break;
            }
          } catch (e) {
            debugPrint("Time parse error: $e");
          }
        }

        if (overdueReminder?.id != found?.id) {
          overdueReminder = found;
          notifyListeners();
        }
      } else if (overdueReminder != null) {
        overdueReminder = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Global reminder check error: $e");
    }
  }

  void dismissReminder() {
    overdueReminder = null;
    notifyListeners();
  }

  Future<void> requestPermissions() async {
    final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

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
          fullScreenIntent: true,
        ),
      ),
      payload: payload,
    );
  }

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
            'med_channel_exact',
            'Medicine Exact Alarms',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: frequency == 'Daily' 
            ? DateTimeComponents.time 
            : DateTimeComponents.dayOfWeekAndTime,
        payload: 'reminder_$id',
      );
    } catch (e) {
      debugPrint("Error scheduling: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
