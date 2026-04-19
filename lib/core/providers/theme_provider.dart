import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/database/hive_setup.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = HiveSetup.getSetting('theme');
    return saved == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    HiveSetup.setSetting('theme', next == ThemeMode.light ? 'light' : 'dark');
    state = next;
  }

  bool get isLight => state == ThemeMode.light;
}
