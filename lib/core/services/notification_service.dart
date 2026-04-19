import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static const _androidDetails = AndroidNotificationDetails(
    'ht_channel',
    'Habit Tracker',
    channelDescription: 'Habit Tracker daily reminders',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _notifDetails = NotificationDetails(android: _androidDetails);

  // --- Show instant notification ---
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notifDetails,
    );
  }

  // --- Cancel a single notification ---
  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  // --- Cancel all reminders ---
  static Future<void> cancelIncompleteReminders() async {
    for (final id in [101, 102, 103, 104, 105]) {
      await _plugin.cancel(id: id);
    }
  }

  // --- Internal helper: schedule one daily reminder at HH:mm ---
  static Future<void> _scheduleDailyAt(
      int id, String title, String body, int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // --- Schedule the 5 daily reminders ---
  static Future<void> scheduleDailyReminders() async {
    await _scheduleDailyAt(101, "Stay Hydrated! 💧",
        "Log your water intake and check your tasks.", 12, 0);
    await _scheduleDailyAt(102, "Mid-Day Check-in 🎯",
        "Have you hit your water goal yet? Keep going!", 14, 0);
    await _scheduleDailyAt(103, "Afternoon Reminder 🏋️",
        "Did you hit the gym today? Don't miss your streak!", 16, 0);
    await _scheduleDailyAt(104, "Evening Push 💪",
        "Complete your tasks before the day slips away.", 18, 0);
    await _scheduleDailyAt(105, "Last Call! 🌙",
        "Final chance to log your habits today.", 20, 0);
  }

  // --- Schedule midnight end-of-day report ---
  static Future<void> scheduleEndOfDayReport() async {
    await _scheduleDailyAt(
        200, "Daily Report Ready! 📊", "Tap to see today's achievements.", 0, 0);
  }
}
