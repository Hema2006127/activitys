import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gymapp/core/database/models.dart';
import 'package:gymapp/core/database/hive_setup.dart';

final sleepProvider = NotifierProvider<SleepNotifier, SleepLog>(SleepNotifier.new);

class SleepNotifier extends Notifier<SleepLog> {
  @override
  SleepLog build() {
    return _loadData();
  }

  SleepLog _loadData() {
    final box = Hive.box<SleepLog>(HiveSetup.sleepBox);
    final now = DateTime.now();
    
    final todaysLog = box.values.where((log) => 
      log.date.year == now.year && log.date.month == now.month && log.date.day == now.day
    ).toList();
    
    if (todaysLog.isNotEmpty) {
      return todaysLog.first;
    } else {
      return SleepLog(date: now, hours: 0.0);
    }
  }

  void updateSleep(double delta) {
    var hours = state.hours + delta;
    if (hours < 0) hours = 0.0;
    if (hours > 24) hours = 24.0;
    
    final box = Hive.box<SleepLog>(HiveSetup.sleepBox);
    
    final newLog = SleepLog(
      date: state.date,
      hours: hours,
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
