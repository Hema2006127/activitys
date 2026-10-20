import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/providers/rest_timer_provider.dart';
import 'package:gymapp/core/theme/app_theme.dart';
import 'package:gymapp/core/widgets/glass.dart';

/// شريط عداد الراحة (زجاجي) في أسفل شاشة التمرين.
/// وهو واقف: اختيار مدة الراحة الافتراضية. وهو شغال: عداد + تحكم.
class RestTimerBar extends ConsumerStatefulWidget {
  const RestTimerBar({super.key});

  @override
  ConsumerState<RestTimerBar> createState() => _RestTimerBarState();
}

class _RestTimerBarState extends ConsumerState<RestTimerBar> {
  Timer? _ticker;
  bool _finishedHandled = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    final s = ref.read(restTimerProvider);
    if (!s.isActive) {
      _finishedHandled = false;
      return;
    }
    if (!s.isPaused && s.remaining() == 0 && !_finishedHandled) {
      _finishedHandled = true;
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 1500), () {
        // لو ماحدش بدأ عداد جديد في الوقت ده، اقفل
        final now = ref.read(restTimerProvider);
        if (now.isActive && !now.isPaused && now.remaining() == 0) {
          ref.read(restTimerProvider.notifier).stop();
        }
      });
    }
    if (mounted) setState(() {});
  }

  static String _fmt(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restTimerProvider);
    final notifier = ref.read(restTimerProvider.notifier);
    final ink = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: BorderRadius.circular(26),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: state.isActive
              ? _active(state, notifier, ink)
              : _idle(notifier, ink),
        ),
      ),
    );
  }

  Widget _idle(RestTimerNotifier notifier, Color ink) {
    final current = notifier.defaultSeconds;
    return Row(
      children: [
        Icon(Icons.timer_outlined, color: ink.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text('الراحة', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in RestTimerNotifier.presets)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(
                      label: Text(s < 60 ? '$sث' : _fmt(s)),
                      selected: s == current,
                      showCheckmark: false,
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.35),
                      onSelected: (_) => setState(() => notifier.defaultSeconds = s),
                    ),
                  ),
              ],
            ),
          ),
        ),
        IconButton.filled(
          tooltip: 'ابدأ الراحة',
          style: IconButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          onPressed: () => notifier.start(),
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _active(RestTimerState state, RestTimerNotifier notifier, Color ink) {
    final remaining = state.remaining();
    final progress =
        state.totalSeconds == 0 ? 0.0 : remaining / state.totalSeconds;
    final done = remaining == 0 && !state.isPaused;

    return Row(
      children: [
        SizedBox(
          width: 58,
          height: 58,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: ink.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                    done ? AppTheme.accentColor : AppTheme.secondaryColor,
                  ),
                ),
              ),
              Icon(
                done
                    ? Icons.check_rounded
                    : state.isPaused
                        ? Icons.pause_rounded
                        : Icons.timer_rounded,
                size: 22,
                color: done ? AppTheme.accentColor : ink,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                done ? 'يلا الـ set الجاي! 💪' : _fmt(remaining),
                style: TextStyle(
                  fontSize: done ? 18 : 28,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                state.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: ink.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
        _RoundBtn(label: '-15', onTap: () => notifier.addSeconds(-15)),
        _RoundBtn(label: '+15', onTap: () => notifier.addSeconds(15)),
        _RoundBtn(
          icon: state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          onTap: notifier.togglePause,
        ),
        _RoundBtn(icon: Icons.skip_next_rounded, onTap: notifier.stop, accent: true),
      ],
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool accent;

  const _RoundBtn({this.label, this.icon, required this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: accent ? AppTheme.brandGradient : null,
            color: accent ? null : ink.withValues(alpha: 0.08),
            border: Border.all(color: ink.withValues(alpha: 0.12)),
          ),
          child: icon != null
              ? Icon(icon, size: 20, color: accent ? Colors.white : ink)
              : Text(label!,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ink)),
        ),
      ),
    );
  }
}
