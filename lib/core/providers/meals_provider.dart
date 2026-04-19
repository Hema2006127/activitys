import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gymapp/core/database/models.dart';
import 'package:gymapp/core/database/hive_setup.dart';

final mealsProvider = NotifierProvider<MealsNotifier, MealLog>(MealsNotifier.new);

class MealsNotifier extends Notifier<MealLog> {
  @override
  MealLog build() {
    return _loadData();
  }

  MealLog _loadData() {
    final box = Hive.box<MealLog>(HiveSetup.mealsBox);
    final now = DateTime.now();
    
    final todaysLog = box.values.where((log) => 
      log.date.year == now.year && log.date.month == now.month && log.date.day == now.day
    ).toList();
    
    if (todaysLog.isNotEmpty) {
      return todaysLog.first;
    } else {
      return MealLog(date: now, mealsCount: 0);
    }
  }

  void updateMeals(int delta) {
    final box = Hive.box<MealLog>(HiveSetup.mealsBox);
    
    final newCount = state.mealsCount + delta;
    if (newCount < 0) return;
    
    final newLog = MealLog(
      date: state.date,
      mealsCount: newCount,
    );
    
    final keysToRemove = [];
    for (var i = 0; i < box.length; i++) {
        final item = box.getAt(i);
        if (item != null && item.date.year == state.date.year && item.date.month == state.date.month && item.date.day == state.date.day) {
            keysToRemove.add(box.keyAt(i));
        }
    }
    for (var k in keysToRemove) { box.delete(k); }
    
    box.add(newLog);
    state = newLog;
  }
}
