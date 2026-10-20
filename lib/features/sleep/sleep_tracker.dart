import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/providers/sleep_provider.dart';
import 'package:gymapp/core/providers/sleep_session_provider.dart';
import 'package:gymapp/core/theme/app_theme.dart';
import 'package:gymapp/core/widgets/glass.dart';
import 'package:intl/intl.dart';

const _night = Color(0xFF818CF8);

/// كارت "رايح أنام / صحيت" في الـ Dashboard.
class SleepTrackerCard extends ConsumerStatefulWidget {
  const SleepTrackerCard({super.key});

  @override
  ConsumerState<SleepTrackerCard> createState() => _SleepTrackerCardState();
}

class _SleepTrackerCardState extends ConsumerState<SleepTrackerCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // تحديث المدة المعروضة كل دقيقة
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && ref.read(sleepSessionProvider) != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startedAt = ref.watch(sleepSessionProvider);
    final ink = Theme.of(context).colorScheme.onSurface;
    return startedAt == null ? _awake(ink) : _sleeping(startedAt, ink);
  }

  Widget _awake(Color ink) {
    final logged = ref.watch(sleepProvider).hours;
    final evening = DateTime.now().hour >= 20 || DateTime.now().hour < 4;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.bedtime_rounded, color: _night, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evening ? 'وقت النوم قرب 🌙' : 'النوم',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                Text(
                  logged > 0
                      ? 'نمت ${logged.toStringAsFixed(1)} ساعة النهارده'
                      : 'دوس قبل ما تنام، والتطبيق يحسب لوحده',
                  style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _night),
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(sleepSessionProvider.notifier).start();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('تصبح على خير 😴 دوس "صحيت" أول ما تقوم.'),
              ));
            },
            icon: const Icon(Icons.nightlight_round, size: 18),
            label: const Text('رايح أنام'),
          ),
        ],
      ),
    );
  }

  Widget _sleeping(DateTime startedAt, Color ink) {
    final elapsed = DateTime.now().difference(startedAt);
    final h = elapsed.inHours;
    final m = elapsed.inMinutes % 60;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_night.withValues(alpha: 0.3), AppTheme.primaryColor.withValues(alpha: 0.12)],
      ),
      child: Row(
        children: [
          const Text('😴', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نايم من ${DateFormat('h:mm a', 'ar').format(startedAt)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                Text('$h ساعة و $m دقيقة',
                    style: TextStyle(fontSize: 13, color: ink.withValues(alpha: 0.7))),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ref.read(sleepSessionProvider.notifier).cancel(),
            child: Text('إلغاء', style: TextStyle(color: ink.withValues(alpha: 0.6))),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.warningColor, foregroundColor: AppTheme.inkColor),
            onPressed: () => showWakeUpSheet(context, ref),
            icon: const Icon(Icons.wb_sunny_rounded, size: 18),
            label: const Text('صحيت'),
          ),
        ],
      ),
    );
  }
}

/// شيت تأكيد ساعات النوم بعد "صحيت" (أو أوتوماتيك لما التطبيق يتفتح الصبح).
Future<void> showWakeUpSheet(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sleepSessionProvider.notifier);
  if (ref.read(sleepSessionProvider) == null) return;
  var hours = session.elapsedHours;
  final existing = ref.read(sleepProvider).hours;
  HapticFeedback.mediumImpact();

  final result = await showModalBottomSheet<double>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        final ink = Theme.of(ctx).colorScheme.onSurface;
        final label = hours >= 7
            ? 'نوم ممتاز 👌'
            : hours >= 5
                ? 'مقبول، حاول تزوّد شوية'
                : 'قليل… هيأثر على تمرينك النهارده';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('☀️ صباح الخير!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('نمت قد إيه؟', style: TextStyle(color: ink.withValues(alpha: 0.65))),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: hours > 0.5 ? () => setSheet(() => hours -= 0.5) : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text(
                        '${hours.toStringAsFixed(1)} س',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: hours < 16 ? () => setSheet(() => hours += 0.5) : null,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                Text(label, style: const TextStyle(color: _night, fontWeight: FontWeight.w700)),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, hours),
                    child: Text(existing > 0 ? 'استبدال (كان ${existing.toStringAsFixed(1)} س)' : 'حفظ'),
                  ),
                ),
                if (existing > 0) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      // قيلولة: تتضاف على نوم النهارده
                      onPressed: () => Navigator.pop(ctx, existing + hours),
                      child: Text('إضافة كقيلولة (المجموع ${(existing + hours).toStringAsFixed(1)} س)'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );

  if (result == null) return; // قفل الشيت: الجلسة تفضل شغالة
  session.cancel();
  ref.read(sleepProvider.notifier).setHours(result.clamp(0.0, 24.0));
}
