import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gymapp/core/database/models.dart';
import 'package:gymapp/core/database/hive_setup.dart';

final gymProvider = NotifierProvider<GymNotifier, List<GymLog>>(GymNotifier.new);

class GymNotifier extends Notifier<List<GymLog>> {
  @override
  List<GymLog> build() {
    return _loadData();
  }

  List<GymLog> _loadData() {
    final box = Hive.box<GymLog>(HiveSetup.gymBox);
    return box.values.toList();
  }

  void logDay(DateTime date, String status) {
    final box = Hive.box<GymLog>(HiveSetup.gymBox);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    final existingIndex = state.indexWhere((l) => l.date.year == normalizedDate.year && l.date.month == normalizedDate.month && l.date.day == normalizedDate.day);
    
    final log = GymLog(date: normalizedDate, status: status);

    if (existingIndex != -1) {
      var key;
      for (var i = 0; i < box.length; i++) {
        final item = box.getAt(i);
        if (item != null && item.date.year == normalizedDate.year && item.date.month == normalizedDate.month && item.date.day == normalizedDate.day) {
            key = box.keyAt(i);
            break;
        }
      }
      if (key != null) box.put(key, log);
      
      final newState = [...state];
      newState[existingIndex] = log;
      state = newState;
    } else {
      box.add(log);
      state = [...state, log];
    }
  }

  int get currentStreak {
    if (state.isEmpty) return 0;
    
    // Sort descending
    final sorted = [...state]..sort((a, b) => b.date.compareTo(a.date));
    
    int streak = 0;
    DateTime? lastCheckIn;
    
    for (var log in sorted) {
      if (log.status == 'missed') {
         break; // Streak broken
      }

      if (lastCheckIn == null) {
        final difference = DateTime.now().difference(log.date).inDays;
        if (difference > 1) return 0; 
        if (log.status != 'missed') streak++;
      } else {
        final diff = lastCheckIn.difference(log.date).inDays;
        if (diff == 1) {
          streak++;
        } else if (diff > 1) {
          break; // Broken streak
        }
      }
      lastCheckIn = log.date;
    }
    
    return streak;
  }
}
