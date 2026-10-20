import 'package:flutter/foundation.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/database/models.dart';
import 'package:gymapp/core/services/notification_service.dart';

/// تذكيرات المهام بأسمائها:
/// - 9 الصبح: ملخص مهام اليوم (النهارده لو لسه مجاش، وبكره كمان).
/// - خلال اليوم: تذكير لكل مهمة مش متخلصة باسمها (الأولوية العالية الأول).
/// - 8 بالليل: اللي فاضل.
/// بيتعاد حسابها مع أي تغيير في المهام، فالمهمة اللي بتخلص تذكيرها بيتلغي.
class TaskReminders {
  static const _morningToday = 700;
  static const _morningTomorrow = 701;
  static const _perTaskIds = [710, 711, 712, 713, 714, 715];
  static const _evening = 720;

  static const _morningHour = 9;
  static const _firstTaskHour = 11;
  static const _lastTaskHour = 20; // آخر تذكير فردي 8:00 م تقريباً
  static const _step = Duration(minutes: 90);

  static bool get enabled => HiveSetup.getSetting('task_reminders') != 'false';

  static Future<void> setEnabled(bool value, List<TaskItem> tasks) async {
    HiveSetup.setSetting('task_reminders', value ? 'true' : 'false');
    await reschedule(tasks);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static List<TaskItem> _forDay(List<TaskItem> all, DateTime day) =>
      all.where((t) => _sameDay(t.date, day)).toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));

  static String _bullets(List<TaskItem> tasks, {int max = 5}) {
    final lines = tasks.take(max).map((t) => '${t.priority == 2 ? '🔴' : '•'} ${t.title}');
    final more = tasks.length > max ? '\n…و${tasks.length - max} كمان' : '';
    return lines.join('\n') + more;
  }

  static Future<void> reschedule(List<TaskItem> all) async {
    try {
      for (final id in [_morningToday, _morningTomorrow, ..._perTaskIds, _evening]) {
        await NotificationService.cancelNotification(id);
      }
      if (!enabled) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final todayTasks = _forDay(all, today);
      final pending = todayTasks.where((t) => !t.isCompleted).toList();

      // ── ملخص الصبح ──
      if (todayTasks.isNotEmpty) {
        await _notify(
          _morningToday,
          today.add(const Duration(hours: _morningHour)),
          '📋 عندك ${todayTasks.length} ${todayTasks.length == 1 ? 'مهمة' : 'مهام'} النهارده',
          _bullets(todayTasks),
        );
      }
      final tomorrowTasks = _forDay(all, tomorrow).where((t) => !t.isCompleted).toList();
      if (tomorrowTasks.isNotEmpty) {
        await _notify(
          _morningTomorrow,
          tomorrow.add(const Duration(hours: _morningHour)),
          '☀️ صباح الخير! مهامك النهارده (${tomorrowTasks.length})',
          _bullets(tomorrowTasks),
        );
      }

      if (pending.isEmpty) return;

      // ── تذكير لكل مهمة باسمها ──
      var t = now.add(const Duration(hours: 1));
      final first = today.add(const Duration(hours: _firstTaskHour));
      if (t.isBefore(first)) t = first;
      final last = today.add(const Duration(hours: _lastTaskHour));
      for (var i = 0; i < pending.length && i < _perTaskIds.length && !t.isAfter(last); i++) {
        final task = pending[i];
        await _notify(
          _perTaskIds[i],
          t,
          task.priority == 2 ? '🔴 مهمة مهمة: ${task.title}' : '⏰ متنساش: ${task.title}',
          task.note?.isNotEmpty == true
              ? task.note!
              : 'دوس هنا وعلّم عليها لما تخلصها ✅',
        );
        t = t.add(_step);
      }

      // ── آخر اليوم: اللي لسه فاضل ──
      await _notify(
        _evening,
        today.add(const Duration(hours: 20, minutes: 30)),
        '🌙 لسه فاضلك ${pending.length} ${pending.length == 1 ? 'مهمة' : 'مهام'}',
        _bullets(pending),
      );
    } catch (e) {
      debugPrint('TaskReminders failed: $e');
    }
  }

  static Future<void> _notify(int id, DateTime when, String title, String body) {
    return NotificationService.scheduleAt(
      id: id,
      title: title,
      body: body,
      when: when,
      channelId: 'tasks',
      channelName: 'تذكيرات المهام',
      thread: 'tasks',
      payload: 'tasks',
    );
  }
}
