import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/navigation.dart';
import 'package:gymapp/core/providers/gym_provider.dart';
import 'package:gymapp/core/providers/tab_provider.dart';
import 'package:gymapp/core/providers/tasks_provider.dart';
import 'package:gymapp/core/providers/water_provider.dart';
import 'package:gymapp/core/providers/weight_provider.dart';
import 'package:gymapp/core/providers/meals_provider.dart';
import 'package:gymapp/core/providers/sleep_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gymapp/core/theme/app_theme.dart';
import 'package:gymapp/core/services/habit_history.dart';
import 'package:gymapp/core/services/health_service.dart';
import 'package:gymapp/core/widgets/animations.dart';
import 'package:gymapp/core/widgets/glass.dart';
import 'package:gymapp/core/widgets/habit_heatmap.dart';
import 'package:intl/intl.dart';
import 'package:gymapp/features/sleep/sleep_tracker.dart';
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
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'صباح الخير'
        : hour < 18
            ? 'مساء النور'
            : 'مساء الخير';
    final greeting = userName != null && userName.isNotEmpty
        ? '$timeGreeting، $userName'
        : timeGreeting;
    final ink = Theme.of(context).colorScheme.onSurface;

    // نتيجة اليوم (نفس الحسبة المستخدمة في الخريطة الحرارية والـ Widget)
    final dayScore = HabitHistory.today().score;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        centerTitle: false,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(
              DateFormat('EEEE، d MMMM', 'ar').format(DateTime.now()),
              style: TextStyle(fontSize: 13, color: ink.withValues(alpha: 0.55)),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'القائمة',
          onPressed: openMainDrawer,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily score
            FadeSlideIn(index: 0, child: _DayScoreCard(score: dayScore, gymStreak: gymStreak)),
            const SizedBox(height: 16),

            // Quick-add water strip
            FadeSlideIn(index: 1, child: _QuickAddWater(ref: ref, waterLog: waterLog)),
            if (HealthService.supported) ...[
              const SizedBox(height: 12),
              const FadeSlideIn(index: 2, child: _StepsStrip()),
            ],
            const SizedBox(height: 12),
            const FadeSlideIn(index: 3, child: SleepTrackerCard()),
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
                for (final (i, card) in <Widget>[
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
                  color: AppTheme.secondaryColor,
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
                  color: const Color(0xFFEC4899),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WeightScreen()),
                  ),
                ),
                _SummaryCard(
                  title: 'الوجبات',
                  value: '${mealsLog.mealsCount}',
                  icon: Icons.restaurant,
                  color: AppTheme.warningColor,
                  onTap: () => _showMealDialog(context, ref),
                ),
                _SummaryCard(
                  title: 'النوم',
                  value: '${sleepLog.hours.toStringAsFixed(1)} h',
                  icon: Icons.bedtime,
                  color: const Color(0xFF818CF8),
                  onTap: () => _showSleepDialog(context, ref),
                ),
                ].indexed)
                  FadeSlideIn(index: 4 + i, child: card),
              ],
            ),

            const SizedBox(height: 20),
            const FadeSlideIn(index: 10, child: HabitHeatmap()),

            const SizedBox(height: 28),
            const Text('تقدم الوزن',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            SizedBox(
              height: 220,
              child: GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: sortedW.length < 2
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.show_chart,
                                size: 40,
                                color: AppTheme.primaryColor.withValues(alpha: 0.7)),
                            const SizedBox(height: 12),
                            const Text('مفيش بيانات كافية',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(
                              'أضف تسجيلين على الأقل عشان تشوف الرسم البياني',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: ink.withValues(alpha: 0.55)),
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
                                gradient: AppTheme.brandGradient,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppTheme.primaryColor.withValues(alpha: 0.3),
                                      AppTheme.secondaryColor.withValues(alpha: 0),
                                    ],
                                  ),
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
    final double pct = (waterLog.amount / waterLog.goal).clamp(0.0, 1.0);
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.water_drop_rounded, color: AppTheme.secondaryColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedValue('${waterLog.amount} / ${waterLog.goal} مل',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: pct),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation(AppTheme.secondaryColor),
                    ),
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
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Steps (Apple Health) ──────────────────────────────────────────────────────
class _StepsStrip extends ConsumerWidget {
  const _StepsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final synced = ref.watch(stepsProvider);
    final ink = Theme.of(context).colorScheme.onSurface;
    const color = AppTheme.accentColor;

    if (synced == null && !HealthService.enabled) {
      return GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: () async {
          final ok = await HealthService.connect(ref);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('مقدرناش نوصل لـ Apple Health. فعّل الصلاحيات من تطبيق Health.'),
            ));
          }
        },
        child: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: Color(0xFFFF375F), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اربط Apple Health',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  Text('الخطوات والنوم والوزن هيتسجلوا لوحدهم',
                      style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: ink.withValues(alpha: 0.5)),
          ],
        ),
      );
    }

    final steps = synced ?? 0; // مربوط بس لسه بيحمّل
    final double pct = (steps / HealthService.stepsGoal).clamp(0.0, 1.0);
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.directions_walk_rounded, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${NumberFormat.decimalPattern().format(steps)} / '
                  '${NumberFormat.decimalPattern().format(HealthService.stepsGoal)} خطوة',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('${(pct * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w900, color: color)),
        ],
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
    return GlassContainer(
      onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : Colors.black54)),
              const SizedBox(height: 4),
              AnimatedValue(value,
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
    );
  }
}

// ── Day score (فكرة جديدة: نتيجة يومك من 100) ─────────────────────────────────
class _DayScoreCard extends StatelessWidget {
  final double score; // 0..1
  final int gymStreak;

  const _DayScoreCard({required this.score, required this.gymStreak});

  String get _message {
    if (score >= 0.9) return 'يوم مثالي! كمّل كده 🏆';
    if (score >= 0.6) return 'ماشي كويس جداً، فاضل شوية 💪';
    if (score >= 0.3) return 'بداية حلوة، يلا نكمّل 🚀';
    return 'لسه اليوم في أوله، ابدأ بكوباية مياه 💧';
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.primaryColor.withValues(alpha: 0.28),
          AppTheme.secondaryColor.withValues(alpha: 0.12),
        ],
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: ink.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(AppTheme.secondaryColor),
                    ),
                  ),
                  Text('${(v * 100).round()}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('نتيجة يومك',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(_message,
                    style: TextStyle(fontSize: 13, color: ink.withValues(alpha: 0.7))),
                if (gymStreak > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.4)),
                    ),
                    child: Text('🔥 $gymStreak يوم متتالي',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
