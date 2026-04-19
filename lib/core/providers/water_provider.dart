import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gymapp/core/database/models.dart';
import 'package:gymapp/core/database/hive_setup.dart';

final waterProvider = NotifierProvider<WaterNotifier, WaterLog>(WaterNotifier.new);

class WaterNotifier extends Notifier<WaterLog> {
  @override
  WaterLog build() {
    return _loadData();
  }

  int _savedGoal() {
    final raw = HiveSetup.getSetting('water_goal');
    return int.tryParse(raw ?? '') ?? 2000;
  }

  WaterLog _loadData() {
    final box = Hive.box<WaterLog>(HiveSetup.waterBox);
    final now = DateTime.now();

    final todaysLog = box.values.where((log) =>
      log.date.year == now.year && log.date.month == now.month && log.date.day == now.day
    ).toList();

    if (todaysLog.isNotEmpty) {
      return todaysLog.first;
    } else {
      return WaterLog(date: now, amount: 0, goal: _savedGoal());
    }
  }

  void setGoal(int newGoal) {
    final box = Hive.box<WaterLog>(HiveSetup.waterBox);
    final updated = WaterLog(date: state.date, amount: state.amount, goal: newGoal);
    final keysToRemove = [];
    for (var i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item != null &&
          item.date.year == state.date.year &&
          item.date.month == state.date.month &&
          item.date.day == state.date.day) {
        keysToRemove.add(box.keyAt(i));
      }
    }
    for (var k in keysToRemove) { box.delete(k); }
    box.add(updated);
    state = updated;
  }

  void addWater(int amount) {
    final box = Hive.box<WaterLog>(HiveSetup.waterBox);
    
    final newLog = WaterLog(
      date: state.date,
      amount: state.amount + amount < 0 ? 0 : state.amount + amount,
      goal: state.goal,
    );
    
    // To properly update, we should track the key, but to keep it simple, we can filter and delete old ones of the same day.
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
