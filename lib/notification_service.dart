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
  bool _isChecking = false;

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

    // Start a periodic check every 5 seconds for immediate pop-out
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      checkOverdueReminders();
    });
    
    // Initial check
    checkOverdueReminders();
  }

  // Robust time parsing to handle "9:00 AM", "09:00 AM", or "21:00"
  DateTime? _parseTime(String timeStr) {
    try {
      return DateFormat.jm().parse(timeStr.trim());
    } catch (e) {
      try {
        return DateFormat.Hm().parse(timeStr.trim());
      } catch (e2) {
        debugPrint("Failed to parse time: $timeStr");
        return null;
      }
    }
  }

  Future<void> checkOverdueReminders() async {
    if (_isChecking) return;
    _isChecking = true;

    final userId = Utils.currentUser?['id'];
    if (userId == null) {
      _isChecking = false;
      if (overdueReminder != null) {
        overdueReminder = null;
        notifyListeners();
      }
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('reminders')
          .select()
          .eq('user_id', userId)
          .eq('is_taken', false);

      if (data != null) {
        final List<Reminder> reminders = (data as List).map((json) => Reminder.fromJson(json)).toList();
        final now = DateTime.now();

        Reminder? found;
        for (var r in reminders) {
          final parsedTime = _parseTime(r.time);
          if (parsedTime != null) {
            final scheduledTimeToday = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
            if (now.isAfter(scheduledTimeToday)) {
               found = r;
               break;
            }
          }
        }

        if (overdueReminder?.id != found?.id) {
          overdueReminder = found;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Global reminder check error: $e");
    } finally {
      _isChecking = false;
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
      final parsedTime = _parseTime(timeStr);
      if (parsedTime == null) return;
      
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
