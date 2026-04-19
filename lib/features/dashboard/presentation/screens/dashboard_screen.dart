import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/providers/gym_provider.dart';
import 'package:gymapp/core/providers/tab_provider.dart';
import 'package:gymapp/core/providers/tasks_provider.dart';
import 'package:gymapp/core/providers/water_provider.dart';
import 'package:gymapp/core/providers/weight_provider.dart';
import 'package:gymapp/core/providers/meals_provider.dart';
import 'package:gymapp/core/providers/sleep_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gymapp/core/theme/app_theme.dart';
import 'package:gymapp/features/weight/presentation/screens/weight_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymStreak   = ref.watch(gymProvider.notifier).currentStreak;
    final waterLog    = ref.watch(waterProvider);
    final waterPct    = waterLog.goal > 0 ? waterLog.amount / waterLog.goal : 0.0;
    final taskPct     = ref.watch(tasksProvider.notifier).completionRate;
    final lastWeight  = ref.watch(weightProvider.notifier).lastRecorded?.weight ?? 0.0;
    final mealsLog    = ref.watch(mealsProvider);
    final sleepLog    = ref.watch(sleepProvider);
    final weights     = ref.watch(weightProvider);
    final sortedW     = [...weights]..sort((a, b) => a.date.compareTo(b.date));

    final userName = HiveSetup.getSetting('user_name');
    final greeting = userName != null && userName.isNotEmpty ? 'أهلاً، $userName!' : 'أهلاً بك!';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('إيه اللي عملته النهارده؟',
                style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : Colors.black45)),
            const SizedBox(height: 20),

            // Quick-add water strip
            _QuickAddWater(ref: ref, waterLog: waterLog),
            const SizedBox(height: 20),

            // Summary grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: [
                _SummaryCard(
                  title: 'سلسلة الجيم',
                  value: '$gymStreak 🔥',
                  icon: Icons.fitness_center,
                  color: AppTheme.primaryColor,
                  onTap: () => ref.read(currentTabProvider.notifier).setTab(1),
                ),
                _SummaryCard(
                  title: 'المياه',
                  value: '${(waterPct * 100).toInt()}%',
                  icon: Icons.water_drop,
                  color: Colors.blue,
                  onTap: () => ref.read(currentTabProvider.notifier).setTab(2),
                ),
                _SummaryCard(
                  title: 'المهام',
                  value: '${(taskPct * 100).toInt()}%',
                  icon: Icons.check_box,
                  color: AppTheme.accentColor,
                  onTap: () => ref.read(currentTabProvider.notifier).setTab(3),
                ),
                _SummaryCard(
                  title: 'الوزن',
                  value: lastWeight > 0 ? '${lastWeight.toStringAsFixed(1)} kg' : '-',
                  icon: Icons.monitor_weight,
                  color: Colors.purpleAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WeightScreen()),
                  ),
                ),
                _SummaryCard(
                  title: 'الوجبات',
                  value: '${mealsLog.mealsCount}',
                  icon: Icons.restaurant,
                  color: Colors.orangeAccent,
                  onTap: () => _showMealDialog(context, ref),
                ),
                _SummaryCard(
                  title: 'النوم',
                  value: '${sleepLog.hours.toStringAsFixed(1)} h',
                  icon: Icons.bedtime,
                  color: Colors.indigoAccent,
                  onTap: () => _showSleepDialog(context, ref),
                ),
              ],
            ),

            const SizedBox(height: 28),
            const Text('تقدم الوزن',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            SizedBox(
              height: 220,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: sortedW.length < 2
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.show_chart,
                                size: 40,
                                color: Colors.purpleAccent.withValues(alpha: 0.6)),
                            const SizedBox(height: 12),
                            const Text('مفيش بيانات كافية',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(
                              'أضف تسجيلين على الأقل عشان تشوف الرسم البياني',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purpleAccent.withValues(alpha: 0.7)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: sortedW.asMap().entries
                                    .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
                                    .toList(),
                                isCurved: true,
                                color: AppTheme.primaryColor,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMealDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('تحديث الوجبات',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () => ref.read(mealsProvider.notifier).updateMeals(-1),
                ),
                const SizedBox(width: 20),
                Consumer(builder: (_, r, _) {
                  final count = r.watch(mealsProvider).mealsCount;
                  return Text('$count',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold));
                }),
                const SizedBox(width: 20),
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
                  onPressed: () => ref.read(mealsProvider.notifier).updateMeals(1),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSleepDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('تحديث النوم (ساعات)',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () => ref.read(sleepProvider.notifier).updateSleep(-0.5),
                ),
                const SizedBox(width: 20),
                Consumer(builder: (_, r, _) {
                  final hours = r.watch(sleepProvider).hours;
                  return Text(hours.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold));
                }),
                const SizedBox(width: 20),
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
                  onPressed: () => ref.read(sleepProvider.notifier).updateSleep(0.5),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Quick-add water strip ─────────────────────────────────────────────────────
class _QuickAddWater extends StatelessWidget {
  final WidgetRef ref;
  final dynamic waterLog;

  const _QuickAddWater({required this.ref, required this.waterLog});

  @override
  Widget build(BuildContext context) {
    final pct = (waterLog.amount / waterLog.goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: Colors.blue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${waterLog.amount} / ${waterLog.goal} مل',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.blue.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _QuickBtn(
            label: '+250',
            onTap: () => ref.read(waterProvider.notifier).addWater(250),
          ),
          const SizedBox(width: 6),
          _QuickBtn(
            label: '+500',
            onTap: () => ref.read(waterProvider.notifier).addWater(500),
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(height: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : Colors.black54)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              if (onTap != null)
                const SizedBox(height: 2),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 10, color: color.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
