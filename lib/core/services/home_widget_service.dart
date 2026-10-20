import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/providers/gym_provider.dart';
import 'package:gymapp/core/providers/sleep_provider.dart';
import 'package:gymapp/core/providers/tab_provider.dart';
import 'package:gymapp/core/providers/tasks_provider.dart';
import 'package:gymapp/core/providers/water_provider.dart';
import 'package:gymapp/core/services/habit_history.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

/// ربط التطبيق بـ Widget الشاشة الرئيسية في الآيفون (WidgetKit).
///
/// البيانات بتتكتب في App Group مشترك، والـ Widget (Swift) بيقراها.
/// زرار "+250 مل" في الـ Widget بيزوّد `water_pending`، والتطبيق بيضيفها لـ Hive أول ما يفتح.
class HomeWidgetService {
  static const appGroupId = 'group.com.example.gymapp';
  static const iOSWidgetName = 'HabitsWidget';
  static const heatDays = 35; // 5 أسابيع للـ Widget الكبير

  static bool get _supported => !kIsWeb && Platform.isIOS;
  static Timer? _debounce;

  static Future<void> init() async {
    if (!_supported) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('HomeWidget init failed: $e');
    }
  }

  /// يضيف المياه اللي اتسجلت من الـ Widget وهو التطبيق مقفول.
  static Future<void> consumePendingWater(WidgetRef ref) async {
    if (!_supported) return;
    try {
      final pending = await HomeWidget.getWidgetData<int>('water_pending') ?? 0;
      if (pending <= 0) return;
      final day = await HomeWidget.getWidgetData<String>('water_pending_day');
      if (day == _dayString(DateTime.now())) {
        ref.read(waterProvider.notifier).addWater(pending);
      }
      await HomeWidget.saveWidgetData<int>('water_pending', 0);
    } catch (e) {
      debugPrint('HomeWidget consume failed: $e');
    }
  }

  /// تحديث مؤجَّل شوية عشان الضغطات المتتالية متعملش reload كتير للـ Widget.
  static void scheduleSync(WidgetRef ref) {
    if (!_supported) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => sync(ref));
  }

  static Future<void> sync(WidgetRef ref) async {
    if (!_supported) return;
    try {
      final water = ref.read(waterProvider);
      final todaysTasks = ref.read(tasksProvider.notifier).todaysTasks;
      final days = HabitHistory.lastDays(heatDays);
      final today = days.last;
      final sleep = ref.read(sleepProvider).hours;

      final data = <String, Object>{
        'day': _dayString(DateTime.now()),
        'name': HiveSetup.getSetting('user_name') ?? '',
        'score': (today.score * 100).round(),
        'score_parts': today.partsCount,
        'water_amount': water.amount,
        'water_goal': water.goal,
        'sleep_hours': sleep,
        'meals': (today.meals * 3).round(),
        'tasks_done': todaysTasks.where((t) => t.isCompleted).length,
        'tasks_total': todaysTasks.length,
        'gym_streak': ref.read(gymProvider.notifier).currentStreak,
        'active_streak': HabitHistory.activeStreak(days),
        'heat': days.map((d) => (d.score * 100).round()).join(','),
      };

      await Future.wait([
        for (final e in data.entries)
          switch (e.value) {
            final int v => HomeWidget.saveWidgetData<int>(e.key, v),
            final double v => HomeWidget.saveWidgetData<double>(e.key, v),
            final v => HomeWidget.saveWidgetData<String>(e.key, '$v'),
          },
      ]);
      await HomeWidget.updateWidget(iOSName: iOSWidgetName);
    } catch (e) {
      debugPrint('HomeWidget sync failed: $e');
    }
  }

  /// فتح الشاشة المناسبة لما المستخدم يضغط على الـ Widget
  /// (الروابط: habits://water?homeWidget  /  habits://tasks?homeWidget ...).
  static void handleLaunchUri(Uri? uri, WidgetRef ref) {
    if (uri == null) return;
    const tabs = {'home': 0, 'gym': 1, 'water': 2, 'tasks': 3, 'reports': 4};
    final tab = tabs[uri.host];
    if (tab != null) ref.read(currentTabProvider.notifier).setTab(tab);
  }

  static Future<void> listenForLaunches(
    WidgetRef ref,
    void Function(StreamSubscription<Uri?>) onSubscribed,
  ) async {
    if (!_supported) return;
    try {
      handleLaunchUri(await HomeWidget.initiallyLaunchedFromHomeWidget(), ref);
      onSubscribed(HomeWidget.widgetClicked.listen((u) => handleLaunchUri(u, ref)));
    } catch (e) {
      debugPrint('HomeWidget launch listen failed: $e');
    }
  }

  static String _dayString(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
