import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/services/live_activity_service.dart';
import 'package:gymapp/core/services/notification_service.dart';

class RestTimerState {
  final int totalSeconds;
  final DateTime? endsAt; // شغال
  final int? pausedRemaining; // واقف
  final String label;

  const RestTimerState({
    this.totalSeconds = 0,
    this.endsAt,
    this.pausedRemaining,
    this.label = '',
  });

  bool get isActive => endsAt != null || pausedRemaining != null;
  bool get isPaused => pausedRemaining != null;

  int remaining([DateTime? now]) {
    if (pausedRemaining != null) return pausedRemaining!;
    if (endsAt == null) return 0;
    final ms = endsAt!.difference(now ?? DateTime.now()).inMilliseconds;
    return max(0, (ms / 1000).ceil());
  }
}

final restTimerProvider =
    NotifierProvider<RestTimerNotifier, RestTimerState>(RestTimerNotifier.new);

/// عداد الراحة بين الـ sets.
/// مبني على وقت النهاية (مش tick) عشان يفضل دقيق لو التطبيق في الخلفية،
/// ومعاه إشعار في وقت النهاية + Live Activity في الـ Dynamic Island وشاشة القفل.
class RestTimerNotifier extends Notifier<RestTimerState> {
  static const presets = [60, 90, 120, 180];

  @override
  RestTimerState build() => const RestTimerState();

  int get defaultSeconds =>
      int.tryParse(HiveSetup.getSetting('rest_seconds') ?? '') ?? 90;

  set defaultSeconds(int s) => HiveSetup.setSetting('rest_seconds', '$s');

  void start({int? seconds, String label = 'راحة'}) {
    final total = seconds ?? defaultSeconds;
    state = RestTimerState(
      totalSeconds: total,
      endsAt: DateTime.now().add(Duration(seconds: total)),
      label: label,
    );
    _sync();
  }

  void addSeconds(int delta) {
    if (!state.isActive) return;
    if (state.isPaused) {
      final r = max(1, state.pausedRemaining! + delta);
      state = RestTimerState(
        totalSeconds: max(state.totalSeconds, r),
        pausedRemaining: r,
        label: state.label,
      );
    } else {
      final end = state.endsAt!.add(Duration(seconds: delta));
      if (!end.isAfter(DateTime.now())) return stop();
      state = RestTimerState(
        totalSeconds: max(state.totalSeconds, state.remaining() + delta),
        endsAt: end,
        label: state.label,
      );
    }
    _sync();
  }

  void togglePause() {
    if (!state.isActive) return;
    state = state.isPaused
        ? RestTimerState(
            totalSeconds: state.totalSeconds,
            endsAt: DateTime.now().add(Duration(seconds: state.pausedRemaining!)),
            label: state.label,
          )
        : RestTimerState(
            totalSeconds: state.totalSeconds,
            pausedRemaining: state.remaining(),
            label: state.label,
          );
    _sync();
  }

  void stop() {
    state = const RestTimerState();
    NotificationService.cancelNotification(NotificationService.restTimerId);
    LiveActivityService.end();
  }

  void _sync() {
    NotificationService.cancelNotification(NotificationService.restTimerId);
    final endsAt = state.endsAt ??
        DateTime.now().add(Duration(seconds: state.pausedRemaining ?? 0));

    if (!state.isPaused) {
      NotificationService.scheduleAt(
        id: NotificationService.restTimerId,
        title: 'خلصت الراحة ⏱️',
        body: 'يلا على الـ set الجاي 💪 ${state.label}',
        when: endsAt,
        channelId: 'rest_timer',
        channelName: 'عداد الراحة',
        thread: 'rest',
        timeSensitive: true,
      );
    }
    LiveActivityService.showRest(
      endsAt: endsAt,
      totalSeconds: state.totalSeconds,
      label: state.label,
      pausedRemaining: state.pausedRemaining,
    );
  }
}
