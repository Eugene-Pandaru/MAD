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
import 'reminder_screen.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _internal = NotificationService._();
  factory NotificationService() => _internal;
  NotificationService._();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _checkTimer;
  Reminder? overdueReminder;
  bool _isChecking = false;
  
  // To handle navigation when notification is tapped
  GlobalKey<NavigatorState>? navigatorKey;

  Future<void> init({GlobalKey<NavigatorState>? navKey}) async {
    navigatorKey = navKey;
    
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
        // Navigate to schedule screen when tapped
        if (navigatorKey != null && navigatorKey!.currentState != null) {
          navigatorKey!.currentState!.push(
            MaterialPageRoute(builder: (context) => const ReminderScreen()),
          );
        }
      },
    );

    // Periodic check for the pop-out UI and daily reset
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      dailyResetReminders();
      checkOverdueReminders();
    });
    
    dailyResetReminders();
    checkOverdueReminders();
  }

  Future<void> dailyResetReminders() async {
    final user = Utils.currentUser;
    if (user == null) return;
    final userId = user['id'];

    final supabase = Supabase.instance.client;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final profile = await supabase.from('users_profile').select('last_medicine_reset').eq('id', userId).maybeSingle();
      
      if (profile != null) {
        String? lastReset = profile['last_medicine_reset'];
        if (lastReset != today) {
          await supabase.from('reminders').update({'is_taken': false}).eq('user_id', userId);
          await supabase.from('users_profile').update({'last_medicine_reset': today}).eq('id', userId);
        }
      }
    } catch (e) {
      debugPrint("Daily Reset Error: $e");
    }
  }

  DateTime? _parseTime(String timeStr) {
    try {
      return DateFormat.jm().parse(timeStr.trim());
    } catch (e) {
      try {
        return DateFormat.Hm().parse(timeStr.trim());
      } catch (e2) {
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
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('reminders')
          .select()
          .eq('user_id', userId)
          .eq('is_taken', false)
          .eq('is_archived', false);

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
      debugPrint("Reminder check error: $e");
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

  Future<void> showNotification(int id, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'med_channel_generic',
      'General Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(id, title, body, platformChannelSpecifics);
  }

  Future<void> showInstantMedicineReminder({required String name, required String dose}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'med_channel_instant',
      'Instant Medicine Reminders',
      channelDescription: 'Manual test notifications for medicine',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      999, // Unique ID for test notification
      'Medicine Reminder: $name',
      "It's time to take your $dose of $name.",
      platformChannelSpecifics,
    );
  }

  Future<void> scheduleMedicineReminder(int id, String name, String dose, String timeStr, String frequency) async {
    try {
      final parsedTime = _parseTime(timeStr);
      if (parsedTime == null) return;
      
      final now = DateTime.now();
      var scheduledDateTime = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
      
      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        "Medicine Reminder: $name",
        "It's time to take your $dose of $name.",
        tz.TZDateTime.from(scheduledDateTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'med_channel_exact',
            'Medicine Exact Alarms',
            channelDescription: 'Scheduled medicine notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
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
    } catch (e) {
      debugPrint("Error scheduling: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
