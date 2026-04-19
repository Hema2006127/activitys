import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/database/models.dart';
import 'package:gymapp/core/providers/gym_provider.dart';
import 'package:gymapp/core/providers/tasks_provider.dart';
import 'package:gymapp/core/providers/water_provider.dart';
import 'package:gymapp/core/providers/meals_provider.dart';
import 'package:gymapp/core/providers/sleep_provider.dart';
import 'package:gymapp/core/providers/workout_provider.dart';
import 'package:gymapp/core/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير 🏆'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'اليوم'),
              Tab(text: 'الأسبوع'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DailyTab(ref: ref),
            _WeeklyTab(ref: ref),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Daily Tab (original content)
// ═══════════════════════════════════════════════════════════════════════════════
class _DailyTab extends StatelessWidget {
  final WidgetRef ref;
  const _DailyTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final water      = ref.watch(waterProvider);
    final tasksN     = ref.watch(tasksProvider.notifier);
    final meals      = ref.watch(mealsProvider);
    final sleep      = ref.watch(sleepProvider);
    final gymStreak  = ref.watch(gymProvider.notifier).currentStreak;
    final workouts   = ref.watch(workoutProvider.notifier).getSetsForDate(DateTime.now());

    final waterDone  = water.amount >= water.goal;
    final tasksDone  = tasksN.completionRate >= 1.0;
    final gymDone    = workouts.isNotEmpty;
    final perfectDay = waterDone && tasksDone && gymDone;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('ملخص اليوم',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  perfectDay
                      ? 'يوم مثالي! أنت رهيب! 🔥'
                      : 'مجهود كويس! كمّل بكره! 💪',
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 12),
                Text('السلسلة الحالية: $gymStreak يوم',
                    style: const TextStyle(
                        fontSize: 17,
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('الإنجازات',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _ReportCard(
            title: 'المياه',
            value: '${water.amount} / ${water.goal} مل',
            icon: Icons.water_drop,
            color: Colors.blue,
            done: waterDone,
          ),
          _ReportCard(
            title: 'المهام',
            value: '${(tasksN.completionRate * 100).toStringAsFixed(0)}%',
            icon: Icons.check_circle,
            color: Colors.orange,
            done: tasksDone,
          ),
          _ReportCard(
            title: 'الجيم والتمارين',
            value: workouts.isNotEmpty
                ? '${workouts.length} سيت مسجّل'
                : 'مفيش تمرين النهارده',
            icon: Icons.fitness_center,
            color: Colors.green,
            done: gymDone,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SmallCard(
                    title: 'الوجبات',
                    value: '${meals.mealsCount}',
                    icon: Icons.restaurant,
                    color: Colors.redAccent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallCard(
                    title: 'النوم',
                    value: '${sleep.hours} ساعة',
                    icon: Icons.bedtime,
                    color: Colors.indigoAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Weekly Tab
// ═══════════════════════════════════════════════════════════════════════════════
class _WeeklyTab extends StatelessWidget {
  final WidgetRef ref;
  const _WeeklyTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final now     = DateTime.now();
    final gymLogs = ref.watch(gymProvider);
    final tasks   = ref.watch(tasksProvider);

    // Build last-7-days data
    final days = List.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      return d;
    });

    // Gym status per day
    final gymStatus = days.map((d) {
      final log = gymLogs.firstWhere(
        (l) => l.date.year == d.year &&
               l.date.month == d.month &&
               l.date.day == d.day,
        orElse: () => GymLog(date: d, status: 'none'),
      );
      return log.status;
    }).toList();

    // Water per day (query Hive directly)
    final waterBox = Hive.box<WaterLog>(HiveSetup.waterBox);
    final waterPerDay = days.map((d) {
      final log = waterBox.values.firstWhere(
        (w) => w.date.year == d.year &&
               w.date.month == d.month &&
               w.date.day == d.day,
        orElse: () => WaterLog(date: d, amount: 0, goal: 2000),
      );
      return log.amount.toDouble();
    }).toList();

    // Task completion per day
    final taskPctPerDay = days.map((d) {
      final dayTasks = tasks.where((t) =>
          t.date.year == d.year &&
          t.date.month == d.month &&
          t.date.day == d.day);
      if (dayTasks.isEmpty) return 0.0;
      return dayTasks.where((t) => t.isCompleted).length / dayTasks.length;
    }).toList();

    // Summary numbers
    final totalWorkout = gymStatus.where((s) => s == 'workout').length;
    final totalRest    = gymStatus.where((s) => s == 'rest').length;
    final totalMissed  = gymStatus.where((s) => s == 'missed').length;
    final avgWater     = waterPerDay.reduce((a, b) => a + b) / 7;
    final avgTasks     = (taskPctPerDay.reduce((a, b) => a + b) / 7 * 100).toInt();

    final startWeekday = days[0].weekday; // 1=Mon
    final labels = List.generate(7, (i) {
      const map = {1: 'ن', 2: 'ث', 3: 'ر', 4: 'خ', 5: 'ج', 6: 'س', 7: 'ح'};
      final wd = ((startWeekday - 1 + i) % 7) + 1;
      return map[wd] ?? '?';
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards row
          Row(
            children: [
              _WeekStatCard(
                  label: 'تمرين', value: '$totalWorkout', color: Colors.greenAccent),
              const SizedBox(width: 10),
              _WeekStatCard(
                  label: 'راحة', value: '$totalRest', color: Colors.blueAccent),
              const SizedBox(width: 10),
              _WeekStatCard(
                  label: 'فائت', value: '$totalMissed', color: Colors.redAccent),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _WeekStatCard(
                  label: 'متوسط مياه',
                  value: '${avgWater.toInt()} مل',
                  color: Colors.blue,
                  flex: 2),
              const SizedBox(width: 10),
              _WeekStatCard(
                  label: 'متوسط مهام',
                  value: '$avgTasks%',
                  color: AppTheme.accentColor,
                  flex: 2),
            ],
          ),
          const SizedBox(height: 24),

          // Gym attendance bar chart
          const Text('حضور الجيم (٧ أيام)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                barGroups: List.generate(7, (i) {
                  Color barColor;
                  switch (gymStatus[i]) {
                    case 'workout': barColor = Colors.greenAccent; break;
                    case 'rest':    barColor = Colors.blueAccent;  break;
                    case 'missed':  barColor = Colors.redAccent;   break;
                    default:        barColor = Colors.white12;
                  }
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: gymStatus[i] == 'none' ? 0.3 : 1.0,
                        color: barColor,
                        width: 22,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        labels[v.toInt()],
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                maxY: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Water bar chart
          const Text('المياه اليومية (٧ أيام)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                barGroups: List.generate(7, (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: waterPerDay[i] / 100,
                      color: Colors.blue.withValues(alpha: 0.7),
                      width: 22,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                )),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        labels[v.toInt()],
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Task completion line chart
          const Text('إتمام المهام (٧ أيام)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        labels[v.toInt()],
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                minY: 0,
                maxY: 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                        7, (i) => FlSpot(i.toDouble(), taskPctPerDay[i])),
                    isCurved: true,
                    color: AppTheme.accentColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 4,
                        color: AppTheme.accentColor,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.accentColor.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────
class _WeekStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final int flex;

  const _WeekStatCard({
    required this.label,
    required this.value,
    required this.color,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final bool done;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(value, style: const TextStyle(fontSize: 14)),
        trailing: Icon(
          done ? Icons.check_circle : Icons.cancel,
          color: done ? Colors.green : Colors.grey,
          size: 28,
        ),
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _SmallCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
