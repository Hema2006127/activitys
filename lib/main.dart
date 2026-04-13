import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/providers/theme_provider.dart';
import 'package:gymapp/core/theme/app_theme.dart';
import 'package:gymapp/features/splash/splash_screen.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveSetup.init();
  HiveSetup.setSetting('onboarding_done', 'false'); // TEMP: reset onboarding for testing
  await NotificationService.init();
  await NotificationService.scheduleDailyReminders();
  await NotificationService.scheduleEndOfDayReport();

  runApp(
    const ProviderScope(
      child: HabitTrackerApp(),
    ),
  );
}

class HabitTrackerApp extends ConsumerWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'GymApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
    );
  }
}
