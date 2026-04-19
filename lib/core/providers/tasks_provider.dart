import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gymapp/core/database/models.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:uuid/uuid.dart';

final tasksProvider = NotifierProvider<TasksNotifier, List<TaskItem>>(
  TasksNotifier.new,
);

class TasksNotifier extends Notifier<List<TaskItem>> {
  @override
  List<TaskItem> build() {
    return _loadData();
  }

  List<TaskItem> _loadData() {
    final box = Hive.box<TaskItem>(HiveSetup.tasksBox);
    return box.values.toList();
  }

  /// Tasks for a specific date
  List<TaskItem> getTasksForDate(DateTime date) {
    return state
        .where(
          (task) =>
              task.date.year == date.year &&
              task.date.month == date.month &&
              task.date.day == date.day,
        )
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// Today's tasks
  List<TaskItem> get todaysTasks => getTasksForDate(DateTime.now());

  /// Add task for a specific date
  void addTask(String title, {DateTime? date, int priority = 1, String? note}) {
    final box = Hive.box<TaskItem>(HiveSetup.tasksBox);
    final task = TaskItem(
      id: const Uuid().v4(),
      title: title,
      isCompleted: false,
      date: date ?? DateTime.now(),
      priority: priority,
      note: note,
    );
    box.add(task);
    state = [...state, task];
  }

  /// Toggle complete/incomplete
  void toggleTask(String id) {
    final box = Hive.box<TaskItem>(HiveSetup.tasksBox);
    final taskIndex = state.indexWhere((t) => t.id == id);
    if (taskIndex != -1) {
      final task = state[taskIndex];
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      for (var i = 0; i < box.length; i++) {
        if (box.getAt(i)?.id == id) {
          box.putAt(i, updatedTask);
          break;
        }
      }
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == taskIndex) updatedTask else state[i],
      ];
    }
  }

  /// Delete a task
  void deleteTask(String id) {
    final box = Hive.box<TaskItem>(HiveSetup.tasksBox);
    for (var i = 0; i < box.length; i++) {
      if (box.getAt(i)?.id == id) {
        box.deleteAt(i);
        break;
      }
    }
    state = state.where((t) => t.id != id).toList();
  }

  /// Delete all tasks for a specific date
  void deleteAllForDate(DateTime date) {
    final toDelete = getTasksForDate(date).map((t) => t.id).toSet();
    final box = Hive.box<TaskItem>(HiveSetup.tasksBox);
    final keysToDelete = <dynamic>[];
    for (var i = 0; i < box.length; i++) {
      if (toDelete.contains(box.getAt(i)?.id)) {
        keysToDelete.add(box.keyAt(i));
      }
    }
    for (final k in keysToDelete) {
      box.delete(k);
    }
    state = state.where((t) => !toDelete.contains(t.id)).toList();
  }

  double get completionRate {
    final today = todaysTasks;
    if (today.isEmpty) return 0.0;
    return today.where((t) => t.isCompleted).length / today.length;
  }

  /// All distinct dates that have tasks
  List<DateTime> get datesWithTasks {
    final seen = <String>{};
    final dates = <DateTime>[];
    for (final t in state) {
      final key = '${t.date.year}-${t.date.month}-${t.date.day}';
      if (seen.add(key)) {
        dates.add(DateTime(t.date.year, t.date.month, t.date.day));
      }
    }
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }
}
