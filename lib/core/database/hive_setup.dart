import 'package:hive_flutter/hive_flutter.dart';
import 'package:gymapp/core/database/models.dart';

class HiveSetup {
  static const String gymBox = 'gymBoxV2';
  static const String waterBox = 'waterBox';
  static const String tasksBox = 'tasksBox';
  static const String weightBox = 'weightBox';
  static const String mealsBox = 'mealsBox';
  static const String workoutSetBox = 'workoutSetBox';
  static const String sleepBox = 'sleepBox';
  static const String chatBox = 'chatBox'; // AI conversation history
  static const String settingsBox = 'settingsBox'; // user prefs & onboarding
  static const String photosBox = 'photosBox'; // progress photo metadata

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(GymLogAdapter());
    Hive.registerAdapter(WaterLogAdapter());
    Hive.registerAdapter(TaskItemAdapter());
    Hive.registerAdapter(WeightLogAdapter());
    Hive.registerAdapter(MealLogAdapter());
    Hive.registerAdapter(WorkoutSetLogAdapter());
    Hive.registerAdapter(SleepLogAdapter());

    // Open Boxes
    await Hive.openBox<GymLog>(gymBox);
    await Hive.openBox<WaterLog>(waterBox);
    await Hive.openBox<TaskItem>(tasksBox);
    await Hive.openBox<WeightLog>(weightBox);
    await Hive.openBox<MealLog>(mealsBox);
    await Hive.openBox<WorkoutSetLog>(workoutSetBox);
    await Hive.openBox<SleepLog>(sleepBox);
    await Hive.openBox<String>(chatBox);    // AI chat history
    await Hive.openBox<String>(settingsBox); // user preferences
    await Hive.openBox<String>(photosBox);   // progress photos metadata
  }

  static String? getSetting(String key) =>
      Hive.box<String>(settingsBox).get(key);

  static void setSetting(String key, String value) =>
      Hive.box<String>(settingsBox).put(key, value);

  /// امسح كل بيانات المستخدم لما حساب جديد يسجل دخول
  static Future<void> clearUserData() async {
    await Hive.box<GymLog>(gymBox).clear();
    await Hive.box<WaterLog>(waterBox).clear();
    await Hive.box<TaskItem>(tasksBox).clear();
    await Hive.box<WeightLog>(weightBox).clear();
    await Hive.box<MealLog>(mealsBox).clear();
    await Hive.box<WorkoutSetLog>(workoutSetBox).clear();
    await Hive.box<SleepLog>(sleepBox).clear();
    await Hive.box<String>(chatBox).clear();
    await Hive.box<String>(photosBox).clear();
    final s = Hive.box<String>(settingsBox);
    s.delete('user_name');
    s.delete('water_goal');
    s.delete('gym_days_goal');
    s.delete('sleep_started_at');
  }
}
