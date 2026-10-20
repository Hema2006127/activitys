import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// جسر لـ ActivityKit (Live Activity + Dynamic Island) على الآيفون.
/// الكود الأصلي في ios/Runner/LiveActivityPlugin.swift.
class LiveActivityService {
  static const _channel = MethodChannel('habits/live_activity');

  static bool get _supported => !kIsWeb && Platform.isIOS;

  /// بيبدأ أو يحدّث عداد الراحة. لو [pausedRemaining] موجود العداد بيظهر واقف.
  static Future<void> showRest({
    required DateTime endsAt,
    required int totalSeconds,
    required String label,
    int? pausedRemaining,
  }) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('showRest', {
        'endsAt': endsAt.millisecondsSinceEpoch / 1000,
        'totalSeconds': totalSeconds,
        'label': label,
        'pausedRemaining': pausedRemaining,
      });
    } catch (e) {
      debugPrint('LiveActivity showRest failed: $e');
    }
  }

  static Future<void> end() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('end');
    } catch (e) {
      debugPrint('LiveActivity end failed: $e');
    }
  }
}
