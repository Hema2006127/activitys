import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gymapp/core/database/models.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:uuid/uuid.dart';

final workoutProvider = NotifierProvider<WorkoutNotifier, List<WorkoutSetLog>>(
  WorkoutNotifier.new,
);

class WorkoutNotifier extends Notifier<List<WorkoutSetLog>> {
  @override
  List<WorkoutSetLog> build() {
    return _loadData();
  }

  List<WorkoutSetLog> _loadData() {
    final box = Hive.box<WorkoutSetLog>(HiveSetup.workoutSetBox);
    return box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  void addSet(
    DateTime date,
    String muscleGroup,
    String musclePart,
    double weight,
  ) {
    final box = Hive.box<WorkoutSetLog>(HiveSetup.workoutSetBox);
    final newSet = WorkoutSetLog(
      id: const Uuid().v4(),
      date: date,
      muscleGroup: muscleGroup,
      musclePart: musclePart,
      weight: weight,
    );
    box.add(newSet);
    state = [...state, newSet];
  }

  void removeSet(String id) {
    final box = Hive.box<WorkoutSetLog>(HiveSetup.workoutSetBox);
    var keyToRemove;
    for (var i = 0; i < box.length; i++) {
      if (box.getAt(i)?.id == id) {
        keyToRemove = box.keyAt(i);
        break;
      }
    }
    if (keyToRemove != null) box.delete(keyToRemove);
    state = state.where((s) => s.id != id).toList();
  }

  void addTemplate(DateTime date, String templateType) {
    // E.g., Push, Pull, Legs prepopulate
    final pushExercises = [
      {'group': 'Chest', 'part': 'Bench Press'},
      {'group': 'Chest', 'part': 'Incline DB Press'},
      {'group': 'Shoulders', 'part': 'Overhead Press'},
      {'group': 'Triceps', 'part': 'Triceps Pushdown'},
    ];
    final pullExercises = [
      {'group': 'Back', 'part': 'Pull-ups'},
      {'group': 'Back', 'part': 'Barbell Row'},
      {'group': 'Back', 'part': 'Lat Pulldown'},
      {'group': 'Biceps', 'part': 'Barbell Curl'},
    ];
    final legsExercises = [
      {'group': 'Legs', 'part': 'Squat'},
      {'group': 'Legs', 'part': 'Leg Press'},
      {'group': 'Legs', 'part': 'Walking Lunges'},
      {'group': 'Calves', 'part': 'Calf Raises'},
    ];

    List<Map<String, String>> selected;
    if (templateType == 'Push') {
      selected = pushExercises;
    } else if (templateType == 'Pull')
      selected = pullExercises;
    else
      selected = legsExercises;

    for (var ex in selected) {
      addSet(date, ex['group']!, ex['part']!, 0.0);
    }
  }

  List<WorkoutSetLog> getSetsForDate(DateTime date) {
    return state
        .where(
          (s) =>
              s.date.year == date.year &&
              s.date.month == date.month &&
              s.date.day == date.day,
        )
        .toList();
  }
}
