import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gymapp/core/database/models.dart';
import 'package:gymapp/core/database/hive_setup.dart';

final weightProvider = NotifierProvider<WeightNotifier, List<WeightLog>>(WeightNotifier.new);

class WeightNotifier extends Notifier<List<WeightLog>> {
  @override
  List<WeightLog> build() {
    return _loadData();
  }

  List<WeightLog> _loadData() {
    final box = Hive.box<WeightLog>(HiveSetup.weightBox);
    return box.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  void addWeight(double weight) {
    final box = Hive.box<WeightLog>(HiveSetup.weightBox);
    final log = WeightLog(date: DateTime.now(), weight: weight);
    box.add(log);
    
    final newState = [...state, log];
    newState.sort((a, b) => a.date.compareTo(b.date));
    state = newState;
  }

  WeightLog? get lastRecorded {
    if (state.isEmpty) return null;
    return state.last;
  }
}
