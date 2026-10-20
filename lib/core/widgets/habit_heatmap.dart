import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/providers/gym_provider.dart';
import 'package:gymapp/core/providers/meals_provider.dart';
import 'package:gymapp/core/providers/sleep_provider.dart';
import 'package:gymapp/core/providers/tasks_provider.dart';
import 'package:gymapp/core/providers/water_provider.dart';
import 'package:gymapp/core/services/habit_history.dart';
import 'package:gymapp/core/theme/app_theme.dart';
import 'package:gymapp/core/widgets/glass.dart';
import 'package:intl/intl.dart';

/// خريطة حرارية لآخر [weeks] أسبوع (زي GitHub): كل مربع = يوم،
/// ولونه بيغمق كل ما نتيجة اليوم تزيد.
class HabitHeatmap extends ConsumerStatefulWidget {
  final int weeks;
  const HabitHeatmap({this.weeks = 15, super.key});

  @override
  ConsumerState<HabitHeatmap> createState() => _HabitHeatmapState();
}

class _HabitHeatmapState extends ConsumerState<HabitHeatmap> {
  static const _cell = 16.0;
  static const _gap = 4.0;
  static const _weekdays = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س']; // يبدأ بالأحد

  DayStats? _selected;

  static Color colorFor(double score, Color empty) {
    if (score <= 0) return empty;
    if (score < 0.25) return AppTheme.primaryColor.withValues(alpha: 0.3);
    if (score < 0.5) return AppTheme.primaryColor.withValues(alpha: 0.55);
    if (score < 0.75) return AppTheme.primaryColor.withValues(alpha: 0.85);
    return AppTheme.secondaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final empty = ink.withValues(alpha: 0.07);

    // إعادة الحساب لما أي عادة تتغير
    ref.watch(gymProvider);
    ref.watch(waterProvider);
    ref.watch(tasksProvider);
    ref.watch(sleepProvider);
    ref.watch(mealsProvider);

    // نبدأ من يوم أحد عشان كل عمود يبقى أسبوع كامل
    final today = HabitHistory.dayKey(DateTime.now());
    final todayOffset = today.weekday % 7; // الأحد = 0
    final totalDays = (widget.weeks - 1) * 7 + todayOffset + 1;
    final days = HabitHistory.lastDays(totalDays);

    final active = days.where((d) => d.score > 0).length;
    final perfect = days.where((d) => d.score >= 0.9).length;
    final streak = HabitHistory.activeStreak(days);

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text('خريطة العادات',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('آخر ${widget.weeks} أسبوع',
                  style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.5))),
            ],
          ),
          const SizedBox(height: 14),

          // ── الشبكة ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // الأسابيع الأحدث تبان الأول
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    for (final w in _weekdays)
                      SizedBox(
                        height: _cell + _gap,
                        width: 16,
                        child: Text(w,
                            style: TextStyle(fontSize: 9, color: ink.withValues(alpha: 0.45))),
                      ),
                  ],
                ),
                for (var week = 0; week < widget.weeks; week++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: _gap),
                    child: Column(
                      children: [
                        for (var wd = 0; wd < 7; wd++)
                          _buildCell(week * 7 + wd, days, empty, today),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── تفاصيل اليوم المختار أو المفتاح ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _selected == null
                ? _Legend(key: const ValueKey('legend'), empty: empty)
                : _DayDetails(key: ValueKey(_selected!.day), stats: _selected!),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              _Stat(label: 'أيام نشطة', value: '$active'),
              _Stat(label: 'أيام مثالية', value: '$perfect'),
              _Stat(label: 'سلسلة حالية', value: '$streak 🔥'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCell(int index, List<DayStats> days, Color empty, DateTime today) {
    if (index >= days.length) {
      return const SizedBox(width: _cell, height: _cell + _gap);
    }
    final d = days[index];
    final isToday = d.day == today;
    final selected = _selected?.day == d.day;
    return Padding(
      padding: const EdgeInsets.only(bottom: _gap),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selected = selected ? null : d);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _cell,
          height: _cell,
          decoration: BoxDecoration(
            color: colorFor(d.score, empty),
            borderRadius: BorderRadius.circular(4),
            border: selected || isToday
                ? Border.all(
                    color: selected ? Colors.white : AppTheme.secondaryColor,
                    width: 1.5,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color empty;
  const _Legend({required this.empty, super.key});

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final style = TextStyle(fontSize: 11, color: ink.withValues(alpha: 0.5));
    return Row(
      children: [
        Text('اضغط على أي يوم لتفاصيله', style: style),
        const Spacer(),
        Text('أقل', style: style),
        const SizedBox(width: 4),
        for (final s in [0.0, 0.2, 0.4, 0.6, 0.9])
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: _HabitHeatmapState.colorFor(s, empty),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 4),
        Text('أكثر', style: style),
      ],
    );
  }
}

class _DayDetails extends StatelessWidget {
  final DayStats stats;
  const _DayDetails({required this.stats, super.key});

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    String pct(double v) => '${(v * 100).round()}%';
    final gymLabel = switch (stats.gym) {
      'workout' => 'تمرين ✅',
      'rest' => 'راحة 😌',
      'missed' => 'فاتك ❌',
      _ => '—',
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('EEEE، d MMMM', 'ar').format(stats.day)}  •  ${pct(stats.score)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text('💧 ${pct(stats.water)}', style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.75))),
              Text('😴 ${pct(stats.sleep)}', style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.75))),
              Text('🍽 ${pct(stats.meals)}', style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.75))),
              Text('✅ ${stats.tasks == null ? '—' : pct(stats.tasks!)}',
                  style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.75))),
              Text('🏋 $gymLabel', style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.75))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(fontSize: 11, color: ink.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}
