import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/services/notification_service.dart';

/// جلسة نوم شغالة: وقت ما المستخدم داس "رايح أنام" (null = صاحي).
/// بديل لـ Apple Watch لمستخدمين الآيفون من غير ساعة.
final sleepSessionProvider =
    NotifierProvider<SleepSessionNotifier, DateTime?>(SleepSessionNotifier.new);

class SleepSessionNotifier extends Notifier<DateTime?> {
  static const _key = 'sleep_started_at';
  static const _wakeReminderId = 600;

  @override
  DateTime? build() {
    final ms = int.tryParse(HiveSetup.getSetting(_key) ?? '');
    return ms == null || ms == 0 ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  void start() {
    final now = DateTime.now();
    HiveSetup.setSetting(_key, '${now.millisecondsSinceEpoch}');
    state = now;
    // لو نسي يدوس "صحيت"
    NotificationService.scheduleAt(
      id: _wakeReminderId,
      title: 'صباح الخير ☀️',
      body: 'صحيت؟ افتح التطبيق وأكّد ساعات نومك.',
      when: now.add(const Duration(hours: 8)),
      thread: 'sleep',
    );
  }

  /// بينهي الجلسة من غير حفظ (الحفظ بيحصل في شيت التأكيد).
  void cancel() {
    HiveSetup.setSetting(_key, '0');
    state = null;
    NotificationService.cancelNotification(_wakeReminderId);
  }

  /// المدة من "رايح أنام" لحد دلوقتي، متقربة لأقرب نص ساعة.
  double get elapsedHours {
    final start = state;
    if (start == null) return 0;
    final minutes = DateTime.now().difference(start).inMinutes;
    return ((minutes / 30).round() / 2).clamp(0.0, 16.0);
  }

  /// فتح التطبيق الصبح وفيه جلسة عدّت 3 ساعات → نسأله "صحيت؟"
  bool get shouldAskOnOpen {
    final start = state;
    if (start == null) return false;
    final hour = DateTime.now().hour;
    return DateTime.now().difference(start).inHours >= 3 && hour >= 4 && hour < 15;
  }
}
