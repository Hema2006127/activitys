import 'dart:io';

import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/providers/sleep_provider.dart';
import 'package:gymapp/core/providers/weight_provider.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';

/// عدد خطوات النهارده من Apple Health (null = مش مربوط).
final stepsProvider = NotifierProvider<StepsNotifier, int?>(StepsNotifier.new);

class StepsNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? steps) => state = steps;
}

/// ربط Apple Health: سحب الخطوات والنوم والوزن تلقائياً.
class HealthService {
  static final _health = Health();
  static bool _configured = false;
  static bool _syncing = false;

  static const stepsGoal = 8000;

  static const _sleepAsleep = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT, // "Core" في iOS
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ];
  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.WEIGHT,
    HealthDataType.SLEEP_IN_BED,
    ..._sleepAsleep,
  ];

  /// حالياً للآيفون بس (Health Connect على أندرويد محتاج إعدادات إضافية في الـ Manifest).
  static bool get supported => !kIsWeb && Platform.isIOS;
  static bool get enabled => HiveSetup.getSetting('health_enabled') == 'true';

  static Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// يطلب صلاحية القراءة ويفعّل المزامنة.
  static Future<bool> connect(WidgetRef ref) async {
    if (!supported) return false;
    try {
      await _ensureConfigured();
      final ok = await _health.requestAuthorization(
        _types,
        permissions: List.filled(_types.length, HealthDataAccess.READ),
      );
      HiveSetup.setSetting('health_enabled', ok ? 'true' : 'false');
      if (ok) await sync(ref);
      return ok;
    } catch (e) {
      debugPrint('Health connect failed: $e');
      return false;
    }
  }

  static void disconnect(WidgetRef ref) {
    HiveSetup.setSetting('health_enabled', 'false');
    ref.read(stepsProvider.notifier).set(null);
  }

  static Future<void> sync(WidgetRef ref) async {
    if (!supported || !enabled || _syncing) return;
    _syncing = true;
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      // ── الخطوات ──
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      ref.read(stepsProvider.notifier).set(steps ?? 0);

      // ── النوم (من 6 مساء امبارح لحد 2 الضهر النهارده) ──
      final hours = await _sleepHours(
        midnight.subtract(const Duration(hours: 6)),
        midnight.add(const Duration(hours: 14)),
      );
      _importSleep(ref, hours);

      // ── الوزن (آخر 30 يوم) ──
      final weights = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.WEIGHT],
        startTime: now.subtract(const Duration(days: 30)),
        endTime: now,
      );
      _importWeights(ref, weights);
    } catch (e) {
      debugPrint('Health sync failed: $e');
    } finally {
      _syncing = false;
    }
  }

  static Future<double> _sleepHours(DateTime from, DateTime to) async {
    double minutes(List<HealthDataPoint> points) => points.fold(
        0.0, (sum, p) => sum + p.dateTo.difference(p.dateFrom).inMinutes);

    final asleep = await _health.getHealthDataFromTypes(
      types: _sleepAsleep,
      startTime: from,
      endTime: to,
    );
    var total = minutes(asleep);
    if (total == 0) {
      // آيفون من غير ساعة بيسجل "في السرير" بس
      final inBed = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.SLEEP_IN_BED],
        startTime: from,
        endTime: to,
      );
      total = minutes(inBed);
    }
    // تقريب لأقرب نص ساعة زي الإدخال اليدوي
    return (total / 30).round() / 2;
  }

  /// بنكتب النوم بس لو المستخدم ماعدّلوش يدوي بعد آخر استيراد.
  static void _importSleep(WidgetRef ref, double hours) {
    if (hours <= 0) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final current = ref.read(sleepProvider).hours;
    final last = HiveSetup.getSetting('health_sleep_imported')?.split('|');
    final lastValue = last != null && last.first == today ? double.tryParse(last.last) : null;

    if (current == 0 || current == lastValue) {
      ref.read(sleepProvider.notifier).setHours(hours);
      HiveSetup.setSetting('health_sleep_imported', '$today|$hours');
    }
  }

  static void _importWeights(WidgetRef ref, List<HealthDataPoint> points) {
    final lastTs = int.tryParse(HiveSetup.getSetting('health_weight_ts') ?? '') ?? 0;
    final fresh = points
        .where((p) => p.dateTo.millisecondsSinceEpoch > lastTs)
        .toList()
      ..sort((a, b) => a.dateTo.compareTo(b.dateTo));

    for (final p in fresh) {
      final value = p.value;
      if (value is! NumericHealthValue) continue;
      final kg = double.parse(value.numericValue.toStringAsFixed(1));
      // متكررش وزن متسجل يدوي في نفس اليوم
      final duplicate = ref.read(weightProvider).any((w) =>
          DateUtils.isSameDay(w.date, p.dateTo) && (w.weight - kg).abs() < 0.05);
      if (!duplicate) {
        ref.read(weightProvider.notifier).addWeight(kg, date: p.dateTo);
      }
    }
    if (fresh.isNotEmpty) {
      HiveSetup.setSetting(
        'health_weight_ts',
        '${fresh.last.dateTo.millisecondsSinceEpoch}',
      );
    }
  }
}
