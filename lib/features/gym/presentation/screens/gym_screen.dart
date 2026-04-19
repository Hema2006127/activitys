import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/providers/gym_provider.dart';
import 'package:gymapp/core/widgets/streak_celebration.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gymapp/core/database/models.dart';
import 'package:gymapp/features/workout/presentation/screens/workout_screen.dart';

class GymScreen extends ConsumerStatefulWidget {
  const GymScreen({super.key});
  @override
  ConsumerState<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends ConsumerState<GymScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showCelebration = false;

  void _onDayLogged(String status) {
    final streak = ref.read(gymProvider.notifier).currentStreak;
    if (status == 'workout' && isStreakMilestone(streak)) {
      setState(() => _showCelebration = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymLogs = ref.watch(gymProvider);
    final currentStreak = ref.read(gymProvider.notifier).currentStreak;

    return Scaffold(
      appBar: AppBar(title: const Text('تقدم الجيم')),
      body: Stack(
        children: [
          // ── Main content ─────────────────────────────────────────────────
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Streak card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            size: 40,
                            color: Colors.orange,
                          ),
                          Text(
                            'السلسلة الحالية',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '$currentStreak يوم',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  fontSize: 36,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                          ),
                          if (currentStreak > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _streakEmoji(currentStreak),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white60,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Calendar
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDay = selected;
                            _focusedDay = focused;
                          });
                          _showLogDialog(context, selected);
                        },
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (ctx, day, _) =>
                              _buildCell(day, gymLogs),
                          todayBuilder: (ctx, day, _) =>
                              _buildCell(day, gymLogs, isToday: true),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Legend
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Legend(color: Colors.greenAccent, label: 'تمرين'),
                      _Legend(color: Colors.blueAccent, label: 'راحة'),
                      _Legend(color: Colors.redAccent, label: 'فائت'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Celebration overlay ──────────────────────────────────────────
          if (_showCelebration)
            Positioned.fill(
              child: StreakCelebrationOverlay(
                streak: currentStreak,
                onDone: () => setState(() => _showCelebration = false),
              ),
            ),
        ],
      ),
    );
  }

  String _streakEmoji(int s) {
    if (s >= 30) {
      return '🏆 أسطورة! شهر كامل!';
    }
    if (s >= 14) {
      return '💪 أسبوعين قوة!';
    }
    if (s >= 7) {
      return '🔥 أسبوع كامل!';
    }
    return '⚡ استمر وكمّل!';
  }

  Widget _buildCell(DateTime day, List<GymLog> logs, {bool isToday = false}) {
    final log = logs.firstWhere(
      (l) => isSameDay(l.date, day),
      orElse: () => GymLog(date: day, status: 'none'),
    );
    Color? fill;
    if (log.status == 'workout') {
      fill = Colors.greenAccent.withValues(alpha: 0.55);
    } else if (log.status == 'rest')
      fill = Colors.blueAccent.withValues(alpha: 0.55);
    else if (log.status == 'missed')
      fill = Colors.redAccent.withValues(alpha: 0.55);

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(color: Theme.of(context).primaryColor, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: fill != null
              ? Colors.black
              : (isToday ? Theme.of(context).primaryColor : null),
          fontWeight: isToday ? FontWeight.bold : null,
        ),
      ),
    );
  }

  void _showLogDialog(BuildContext context, DateTime day) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تسجيل ${day.day}/${day.month}/${day.year}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.fitness_center, color: Colors.green),
              title: const Text('اتمرنت النهارده'),
              onTap: () {
                ref.read(gymProvider.notifier).logDay(day, 'workout');
                Navigator.pop(ctx);
                _onDayLogged('workout');
              },
            ),
            ListTile(
              leading: const Icon(Icons.weekend, color: Colors.blue),
              title: const Text('يوم راحة'),
              onTap: () {
                ref.read(gymProvider.notifier).logDay(day, 'rest');
                Navigator.pop(ctx);
                _onDayLogged('rest');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('فائت (كسر السلسلة)'),
              onTap: () {
                ref.read(gymProvider.notifier).logDay(day, 'missed');
                Navigator.pop(ctx);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Colors.orangeAccent),
              title: const Text('عرض التمرين التفصيلي'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => WorkoutScreen(date: day)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
