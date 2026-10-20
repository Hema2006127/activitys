import 'package:flutter/foundation.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/services/notification_service.dart';

/// تذكيرات المياه الذكية: بدل مواعيد ثابتة، بنحسب المفروض تكون شربت كام لحد كل وقت
/// (توزيع الهدف بالتساوي من [startHour] لـ [endHour])، ونبعت إشعار بس لو إنت متأخر فعلاً.
///
/// بيتعاد جدولتها مع كل تسجيل مياه، فلو شربت الإشعارات اللي مالهاش لازمة بتتلغي.
class SmartReminders {
  static const _todayIds = [300, 301, 302, 303];
  static const _tomorrowIds = [310, 311, 312];

  static const startHour = 9;
  static const endHour = 22;
  static const _minDeficit = 300; // مل — أقل من كده مش هنزعجك
  static const _quietAfterDrink = Duration(minutes: 75);
  static const _step = Duration(minutes: 90);

  static bool get enabled => HiveSetup.getSetting('smart_water') != 'false';

  static Future<void> setEnabled(bool value, {required int amount, required int goal}) async {
    HiveSetup.setSetting('smart_water', value ? 'true' : 'false');
    await reschedule(amount: amount, goal: goal);
  }

  /// الكمية المفروض تكون اتشربت لحد [t].
  static int expectedBy(DateTime t, int goal) {
    final start = DateTime(t.year, t.month, t.day, startHour);
    final end = DateTime(t.year, t.month, t.day, endHour);
    final progress = t.difference(start).inMinutes / end.difference(start).inMinutes;
    return (goal * progress.clamp(0.0, 1.0)).round();
  }

  static Future<void> reschedule({required int amount, required int goal}) async {
    try {
      for (final id in [..._todayIds, ..._tomorrowIds]) {
        await NotificationService.cancelNotification(id);
      }
      if (!enabled || goal <= 0) return;

      final now = DateTime.now();

      // ── النهارده: بنبدأ بعد ساعة وربع من آخر تسجيل ──
      if (amount < goal) {
        var t = now.add(_quietAfterDrink);
        final firstSlot = DateTime(now.year, now.month, now.day, startHour, 30);
        if (t.isBefore(firstSlot)) t = firstSlot;
        final lastSlot = DateTime(now.year, now.month, now.day, endHour - 1);
        var i = 0;
        while (!t.isAfter(lastSlot) && i < _todayIds.length) {
          final deficit = expectedBy(t, goal) - amount;
          if (deficit >= _minDeficit) {
            await _schedule(_todayIds[i++], t, deficit, goal - amount);
          }
          t = t.add(_step);
        }
      }

      // ── بكره: لو التطبيق ماتفتحش، تذكيرات على أساس إنك لسه ماشربتش ──
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final slots = [
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 11),
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 30),
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18),
      ];
      for (var j = 0; j < slots.length; j++) {
        await _schedule(_tomorrowIds[j], slots[j], expectedBy(slots[j], goal), goal);
      }
    } catch (e) {
      debugPrint('SmartReminders failed: $e');
    }
  }

  static Future<void> _schedule(int id, DateTime when, int deficit, int remaining) {
    final cups = (deficit / 250).ceil();
    final (title, body) = deficit < 600
        ? ('💧 فاضلك حاجة بسيطة', 'إنت متأخر $deficit مل عن هدفك — كوباية دلوقتي تظبطك.')
        : deficit < 1200
            ? ('💧 جسمك محتاج مياه', 'متأخر $deficit مل… اشرب $cups كوبايات على مدار الساعة الجاية.')
            : ('🚰 يلا نلحق الهدف', 'لسه فاضلك $remaining مل النهارده. ابدأ بكوبايتين وكمّل على مهلك.');
    return NotificationService.scheduleAt(
      id: id,
      title: title,
      body: body,
      when: when,
      channelId: 'water_smart',
      channelName: 'تذكيرات المياه الذكية',
      thread: 'water',
      payload: 'water',
    );
  }
}
