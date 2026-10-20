import 'package:hive_flutter/hive_flutter.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/database/models.dart';

/// ملخص يوم واحد: كل عادة كنسبة إنجاز من 0 لـ 1.
class DayStats {
  final DateTime day;
  final double water;
  final double sleep;
  final double meals;
  final double? tasks; // null = مفيش مهام اليوم ده
  final String? gym; // workout / rest / missed / null

  const DayStats({
    required this.day,
    required this.water,
    required this.sleep,
    required this.meals,
    this.tasks,
    this.gym,
  });

  /// نتيجة اليوم (0..1): متوسط المياه + النوم (هدف 8 ساعات) + الوجبات (هدف 3)
  /// + المهام (لو موجودة) + الجيم (لو متسجل).
  double get score {
    final parts = <double>[water, sleep, meals, ?tasks];
    if (gym != null) parts.add(gym == 'missed' ? 0.0 : 1.0);
    return parts.reduce((a, b) => a + b) / parts.length;
  }

  /// عدد العادات الداخلة في حساب [score].
  int get partsCount => 3 + (tasks != null ? 1 : 0) + (gym != null ? 1 : 0);

  bool get hasData =>
      water > 0 || sleep > 0 || meals > 0 || tasks != null || gym != null;
}

/// بيقرأ سجلات Hive ويحسب [DayStats] لأي فترة.
class HabitHistory {
  static DateTime dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  /// إحصائيات آخر [days] يوم (الأقدم أولاً، وآخر عنصر = النهارده).
  static List<DayStats> lastDays(int days) {
    final water = <DateTime, WaterLog>{
      for (final l in Hive.box<WaterLog>(HiveSetup.waterBox).values) dayKey(l.date): l,
    };
    final sleep = <DateTime, double>{
      for (final l in Hive.box<SleepLog>(HiveSetup.sleepBox).values) dayKey(l.date): l.hours,
    };
    final meals = <DateTime, int>{
      for (final l in Hive.box<MealLog>(HiveSetup.mealsBox).values) dayKey(l.date): l.mealsCount,
    };
    final gym = <DateTime, String>{
      for (final l in Hive.box<GymLog>(HiveSetup.gymBox).values) dayKey(l.date): l.status,
    };
    final tasksTotal = <DateTime, int>{};
    final tasksDone = <DateTime, int>{};
    for (final t in Hive.box<TaskItem>(HiveSetup.tasksBox).values) {
      final k = dayKey(t.date);
      tasksTotal[k] = (tasksTotal[k] ?? 0) + 1;
      if (t.isCompleted) tasksDone[k] = (tasksDone[k] ?? 0) + 1;
    }

    final today = dayKey(DateTime.now());
    return List.generate(days, (i) {
      final d = DateTime(today.year, today.month, today.day - (days - 1 - i));
      final w = water[d];
      final total = tasksTotal[d];
      return DayStats(
        day: d,
        water: w == null || w.goal <= 0 ? 0 : (w.amount / w.goal).clamp(0.0, 1.0),
        sleep: ((sleep[d] ?? 0) / 8).clamp(0.0, 1.0),
        meals: ((meals[d] ?? 0) / 3).clamp(0.0, 1.0),
        tasks: total == null ? null : (tasksDone[d] ?? 0) / total,
        gym: gym[d],
      );
    });
  }

  static DayStats today() => lastDays(1).single;

  /// عدد الأيام المتتالية (لحد النهارده أو امبارح) اللي نتيجتها ≥ [threshold].
  static int activeStreak(List<DayStats> days, {double threshold = 0.5}) {
    var streak = 0;
    for (var i = days.length - 1; i >= 0; i--) {
      final ok = days[i].score >= threshold;
      if (ok) {
        streak++;
      } else if (i == days.length - 1) {
        continue; // النهارده لسه ماخلصش
      } else {
        break;
      }
    }
    return streak;
  }
}
