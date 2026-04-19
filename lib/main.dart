import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/providers/theme_provider.dart';
import 'package:gymapp/core/services/notification_service.dart';
import 'package:gymapp/core/theme/app_theme.dart';
import 'package:gymapp/features/splash/splash_screen.dart';
import 'package:gymapp/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) تهيئة Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2) تهيئة Hive
  await HiveSetup.init();

  // 3) الإشعارات
  await NotificationService.init();
  await NotificationService.scheduleDailyReminders();
  await NotificationService.scheduleEndOfDayReport();

  runApp(const ProviderScope(child: HabitTrackerApp()));
}

class HabitTrackerApp extends ConsumerWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'عاداتي',
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
      supportedLocales: const [Locale('ar'), Locale('en')],
    );
  }
}
