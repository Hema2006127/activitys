import 'package:hive/hive.dart';

// --- GymLog ---
class GymLog {
  final DateTime date;
  final String status; // "workout", "rest", "missed"

  GymLog({required this.date, required this.status});
}

class GymLogAdapter extends TypeAdapter<GymLog> {
  @override
  final int typeId = 0;

  @override
  GymLog read(BinaryReader reader) {
    return GymLog(
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      status: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, GymLog obj) {
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeString(obj.status);
  }
}

// --- WaterLog ---
class WaterLog {
  final DateTime date;
  final int amount; // in ml or cups
  final int goal;

  WaterLog({required this.date, required this.amount, required this.goal});
}

class WaterLogAdapter extends TypeAdapter<WaterLog> {
  @override
  final int typeId = 1;

  @override
  WaterLog read(BinaryReader reader) {
    return WaterLog(
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      amount: reader.readInt(),
      goal: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, WaterLog obj) {
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeInt(obj.amount);
    writer.writeInt(obj.goal);
  }
}

// --- TaskItem ---
class TaskItem {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime date;
  final int priority; // 0=Low, 1=Medium, 2=High
  final String? note;

  TaskItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.date,
    this.priority = 1,
    this.note,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? date,
    int? priority,
    String? note,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      note: note ?? this.note,
    );
  }
}

class TaskItemAdapter extends TypeAdapter<TaskItem> {
  @override
  final int typeId = 2;

  @override
  TaskItem read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final isCompleted = reader.readBool();
    final date = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    int priority = 1;
    String? note;
    try {
      priority = reader.readInt();
      final n = reader.readString();
      if (n.isNotEmpty) note = n;
    } catch (_) {}
    return TaskItem(id: id, title: title, isCompleted: isCompleted, date: date, priority: priority, note: note);
  }

  @override
  void write(BinaryWriter writer, TaskItem obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeBool(obj.isCompleted);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeInt(obj.priority);
    writer.writeString(obj.note ?? '');
  }
}

// --- WeightLog ---
class WeightLog {
  final DateTime date;
  final double weight;

  WeightLog({required this.date, required this.weight});
}

class WeightLogAdapter extends TypeAdapter<WeightLog> {
  @override
  final int typeId = 3;

  @override
  WeightLog read(BinaryReader reader) {
    return WeightLog(
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      weight: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, WeightLog obj) {
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeDouble(obj.weight);
  }
}

// --- MealLog ---
class MealLog {
  final DateTime date;
  final int mealsCount;

  MealLog({required this.date, required this.mealsCount});
}

class MealLogAdapter extends TypeAdapter<MealLog> {
  @override
  final int typeId = 4;

  @override
  MealLog read(BinaryReader reader) {
    return MealLog(
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      mealsCount: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MealLog obj) {
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeInt(obj.mealsCount);
  }
}

// --- WorkoutSetLog ---
class WorkoutSetLog {
  final String id;
  final DateTime date;
  final String muscleGroup;
  final String musclePart;
  final double weight;

  WorkoutSetLog({
    required this.id,
    required this.date,
    required this.muscleGroup,
    required this.musclePart,
    required this.weight,
  });
}

class WorkoutSetLogAdapter extends TypeAdapter<WorkoutSetLog> {
  @override
  final int typeId = 5;

  @override
  WorkoutSetLog read(BinaryReader reader) {
    return WorkoutSetLog(
      id: reader.readString(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      muscleGroup: reader.readString(),
      musclePart: reader.readString(),
      weight: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSetLog obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeString(obj.muscleGroup);
    writer.writeString(obj.musclePart);
    writer.writeDouble(obj.weight);
  }
}

// --- SleepLog ---
class SleepLog {
  final DateTime date;
  final double hours;

  SleepLog({required this.date, required this.hours});
}

class SleepLogAdapter extends TypeAdapter<SleepLog> {
  @override
  final int typeId = 6;

  @override
  SleepLog read(BinaryReader reader) {
    return SleepLog(
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      hours: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, SleepLog obj) {
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeDouble(obj.hours);
  }
}
