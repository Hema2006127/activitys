import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/providers/weight_provider.dart';
import 'package:gymapp/core/providers/workout_provider.dart';
import 'package:gymapp/core/services/ai_service.dart';
import 'package:gymapp/core/services/habit_history.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

/// فيه تقرير أسبوعي جديد ماتقراش في الشات (بيظهر كنقطة على زرار المدرب).
final weeklyReportUnreadProvider =
    NotifierProvider<WeeklyReportUnread, bool>(WeeklyReportUnread.new);

class WeeklyReportUnread extends Notifier<bool> {
  @override
  bool build() => HiveSetup.getSetting('weekly_report_unread') == 'true';

  void set(bool value) {
    HiveSetup.setSetting('weekly_report_unread', '$value');
    state = value;
  }
}

/// التقرير الأسبوعي: كل جمعة المدرب الذكي بيحلل آخر 7 أيام
/// ويكتب ملخص + تحليل + خطة للأسبوع الجاي كرسالة في الشات.
class WeeklyReportService {
  static const header = '📊 تقريرك الأسبوعي';
  static bool _running = false;

  static DateTime _lastFriday(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: (today.weekday - DateTime.friday) % 7));
  }

  /// بيتنادى عند فتح التطبيق: لو عدّت جمعة من غير تقرير، يعمله ويحطه في الشات.
  static Future<void> maybeGenerate(WidgetRef ref) async {
    if (_running) return;
    final friday = _lastFriday(DateTime.now());
    final key = DateFormat('yyyy-MM-dd').format(friday);
    if (HiveSetup.getSetting('weekly_report_last') == key) return;

    // مفيش بيانات كفاية؟ نستنى
    final week = HabitHistory.lastDays(7);
    if (week.where((d) => d.hasData).length < 2) return;

    _running = true;
    try {
      final report = await generate(ref);
      final box = Hive.box<String>(HiveSetup.chatBox);
      await box.add(jsonEncode({'text': report, 'isUser': false}));
      HiveSetup.setSetting('weekly_report_last', key);
      ref.read(weeklyReportUnreadProvider.notifier).set(true);
    } catch (e) {
      debugPrint('Weekly report failed: $e'); // نحاول تاني الفتحة الجاية
    } finally {
      _running = false;
    }
  }

  static Future<String> generate(WidgetRef ref) async {
    final reply = await AiService.complete(
      [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': _weekData(ref)},
      ],
      maxTokens: 1100,
      temperature: 0.5,
    );
    return reply.trim().startsWith(header) ? reply.trim() : '$header\n\n${reply.trim()}';
  }

  static String _weekData(WidgetRef ref) {
    final days = HabitHistory.lastDays(14);
    final thisWeek = days.sublist(7);
    final lastWeek = days.sublist(0, 7);
    String pct(double v) => '${(v * 100).round()}%';
    double avg(List<DayStats> l, double Function(DayStats) f) =>
        l.map(f).reduce((a, b) => a + b) / l.length;

    final rows = thisWeek.map((d) {
      final gym = switch (d.gym) {
        'workout' => 'تمرين',
        'rest' => 'راحة',
        'missed' => 'فاته',
        _ => '-',
      };
      return '- ${DateFormat('EEEE d/M', 'ar').format(d.day)}: النتيجة ${pct(d.score)}، '
          'المياه ${pct(d.water)}، النوم ${(d.sleep * 8).toStringAsFixed(1)} ساعة، '
          'الوجبات ${(d.meals * 3).round()}، المهام ${d.tasks == null ? '-' : pct(d.tasks!)}، الجيم: $gym';
    }).join('\n');

    final weekStart = thisWeek.first.day;
    final weights = ref.read(weightProvider)
        .where((w) => !w.date.isBefore(weekStart.subtract(const Duration(days: 7))))
        .toList();
    final weightLine = weights.length >= 2
        ? 'الوزن: من ${weights.first.weight} لـ ${weights.last.weight} كجم'
        : weights.isEmpty
            ? 'الوزن: مفيش تسجيلات'
            : 'الوزن: ${weights.last.weight} كجم (تسجيل واحد)';

    final sets = ref.read(workoutProvider).where((s) => !s.date.isBefore(weekStart)).toList();
    final byMuscle = <String, int>{};
    for (final s in sets) {
      byMuscle[s.muscleGroup] = (byMuscle[s.muscleGroup] ?? 0) + 1;
    }

    final name = HiveSetup.getSetting('user_name') ?? '';
    final gymGoal = HiveSetup.getSetting('gym_days_goal') ?? '4';
    final waterGoal = HiveSetup.getSetting('water_goal') ?? '2000';
    final workouts = thisWeek.where((d) => d.gym == 'workout').length;

    return '''بيانات أسبوع ${name.isEmpty ? 'المستخدم' : name}:
$rows

الملخص:
- متوسط نتيجة الأسبوع: ${pct(avg(thisWeek, (d) => d.score))} (الأسبوع اللي قبله: ${pct(avg(lastWeek, (d) => d.score))})
- أيام الجيم: $workouts من هدف $gymGoal أيام
- متوسط المياه: ${pct(avg(thisWeek, (d) => d.water))} من هدف $waterGoal مل
- متوسط النوم: ${(avg(thisWeek, (d) => d.sleep) * 8).toStringAsFixed(1)} ساعة
- $weightLine
- الـ sets المسجلة: ${sets.length}${byMuscle.isEmpty ? '' : ' (${byMuscle.entries.map((e) => '${e.key}: ${e.value}').join('، ')})'}''';
  }

  static const _systemPrompt = '''أنت "كوتش جيم"، المدرب الشخصي داخل تطبيق عاداتي. اكتب التقرير الأسبوعي للمستخدم بالعامية المصرية، بأسلوب صديق خبير ومشجع.

الشكل المطلوب بالظبط (نص عادي من غير رموز Markdown زي ** أو # ومن غير جداول):
$header

✅ أحسن حاجات عملتها
2-3 نقاط بأرقام حقيقية من البيانات.

⚠️ محتاج تركيز
2-3 نقاط: إيه اللي قلّ، وفي أنهي أيام، وليه ده مهم.

📈 مقارنة بالأسبوع اللي فات
سطر أو اتنين.

🎯 خطة الأسبوع الجاي
3 أهداف محددة وقابلة للقياس (مثلاً: "4 أيام جيم"، "2.5 لتر مياه يومياً").

💡 نصيحة الأسبوع
نصيحة عملية واحدة مرتبطة بأضعف نقطة.

قواعد: استخدم الأرقام من البيانات بس ومتخترعش. لو في عادة مفيهاش بيانات قول إنها مش متسجلة. الطول الكلي أقل من 220 كلمة.''';
}
