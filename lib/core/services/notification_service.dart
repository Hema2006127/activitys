import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // IDs
  static const _legacyWaterIds = [101, 102]; // اتشالوا لصالح التذكيرات الذكية
  static const _dailyIds = [103, 104, 105];
  static const restTimerId = 400;
  static const weeklyReportId = 500;

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // الصلاحيات على iOS بتتطلب في أول فتح
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (r) => _taps.add(r.payload),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    for (final id in _legacyWaterIds) {
      await _plugin.cancel(id: id);
    }
  }

  // ── الضغط على الإشعار: الـ payload = اسم الشاشة (tasks / water / ...) ──
  static final _taps = StreamController<String?>.broadcast();
  static Stream<String?> get taps => _taps.stream;

  /// لو التطبيق اتفتح من إشعار وهو مقفول خالص.
  static Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true
        ? details?.notificationResponse?.payload
        : null;
  }

  static NotificationDetails _details({
    String channelId = 'ht_channel',
    String channelName = 'Habit Tracker',
    String? thread,
    bool timeSensitive = false,
    String? bigText,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Habit Tracker reminders',
        importance: Importance.high,
        priority: Priority.high,
        // نص طويل (زي قايمة المهام) يتعرض كامل
        styleInformation: bigText == null ? null : BigTextStyleInformation(bigText),
      ),
      iOS: DarwinNotificationDetails(
        threadIdentifier: thread,
        interruptionLevel: timeSensitive
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      ),
    );
  }

  /// وقت محلي → TZDateTime.
  /// (tz.local بيبقى UTC لو ماتظبطش، فكانت التذكيرات بتيجي في مواعيد غلط — هنا بنحوّل من وقت الجهاز مباشرة)
  static tz.TZDateTime _at(DateTime local) =>
      tz.TZDateTime.from(local.toUtc(), tz.UTC);

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
      notificationDetails: _details(),
    );
  }

  /// إشعار مرة واحدة في وقت محدد.
  static Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String channelId = 'ht_channel',
    String channelName = 'Habit Tracker',
    String? thread,
    bool timeSensitive = false,
    String? payload,
  }) async {
    if (when.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _at(when),
      notificationDetails: _details(
        channelId: channelId,
        channelName: channelName,
        thread: thread,
        timeSensitive: timeSensitive,
        bigText: body.contains('\n') ? body : null,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  // --- Cancel a single notification ---
  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  // --- Cancel all reminders ---
  static Future<void> cancelIncompleteReminders() async {
    for (final id in _dailyIds) {
      await _plugin.cancel(id: id);
    }
  }

  // --- Internal helper: repeat at HH:mm (daily, or weekly on [weekday]) ---
  static Future<void> _scheduleRepeating(
    int id,
    String title,
    String body,
    int hour,
    int minute, {
    int? weekday,
  }) async {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    while (next.isBefore(now) || (weekday != null && next.weekday != weekday)) {
      next = next.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _at(next),
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: weekday == null
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // --- Daily reminders ---
  // المياه → SmartReminders، المهام (بأسمائها) → TaskReminders
  static Future<void> scheduleDailyReminders() async {
    await _plugin.cancel(id: 104); // كان تذكير مهام عام، اتبدّل بتذكيرات بأسماء المهام
    await _scheduleRepeating(103, 'روحت الجيم النهارده؟ 🏋️',
        'متكسرش السلسلة بتاعتك، سجّل تمرينك.', 16, 0);
    await _scheduleRepeating(105, 'آخر فرصة 🌙',
        'سجّل عاداتك النهارده عشان نتيجة يومك تتحسب صح.', 21, 0);
  }

  // --- Schedule midnight end-of-day report ---
  static Future<void> scheduleEndOfDayReport() async {
    await _scheduleRepeating(
        200, 'تقرير يومك جاهز 📊', 'افتح التطبيق وشوف إنجازاتك.', 23, 30);
  }

  /// كل جمعة 10 الصبح: التقرير الأسبوعي من المدرب الذكي.
  static Future<void> scheduleWeeklyReport() async {
    await _scheduleRepeating(
      weeklyReportId,
      'تقريرك الأسبوعي جاهز 🧠',
      'المدرب حلّل أسبوعك وجهزلك نصايح للأسبوع الجاي.',
      10,
      0,
      weekday: DateTime.friday,
    );
  }
}
