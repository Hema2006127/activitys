import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/providers/theme_provider.dart';
import 'package:gymapp/core/services/home_widget_service.dart';
import 'package:gymapp/core/services/notification_service.dart';
import 'package:gymapp/core/theme/app_theme.dart';
import 'package:gymapp/core/widgets/glass.dart';
import 'package:gymapp/features/splash/splash_screen.dart';
import 'package:gymapp/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) تهيئة Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // تواريخ بالعربي (DateFormat(..., 'ar'))
  await initializeDateFormatting('ar');

  // 2) تهيئة Hive
  try {
    await HiveSetup.init();
  } catch (e) {
    debugPrint('Hive init error: $e');
  }

  // Widget الشاشة الرئيسية (iOS)
  await HomeWidgetService.init();

  // 3) الإشعارات
  try {
    await NotificationService.init();
    await NotificationService.scheduleDailyReminders();
    await NotificationService.scheduleEndOfDayReport();
    await NotificationService.scheduleWeeklyReport();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

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
      // خلفية الأورورا ثابتة ورا كل الشاشات (الـ Scaffold شفاف)
      builder: (context, child) => AuroraBackground(child: child),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
    );
  }
}
