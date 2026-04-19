import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/providers/gym_provider.dart';
import 'package:gymapp/core/providers/meals_provider.dart';
import 'package:gymapp/core/providers/sleep_provider.dart';
import 'package:gymapp/core/providers/tab_provider.dart';
import 'package:gymapp/core/providers/tasks_provider.dart';
import 'package:gymapp/core/providers/theme_provider.dart';
import 'package:gymapp/core/providers/water_provider.dart';
import 'package:gymapp/core/providers/weight_provider.dart';
import 'package:gymapp/core/providers/workout_provider.dart';
import 'package:gymapp/features/ai_chat/presentation/screens/ai_chat_screen.dart';
import 'package:gymapp/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:gymapp/features/gym/presentation/screens/gym_screen.dart';
import 'package:gymapp/features/progress_photos/progress_photos_screen.dart';
import 'package:gymapp/features/reports/presentation/screens/reports_screen.dart';
import 'package:gymapp/features/settings/settings_screen.dart';
import 'package:gymapp/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:gymapp/features/water/presentation/screens/water_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  static const _screens = [
    DashboardScreen(),
    GymScreen(),
    WaterScreen(),
    TasksScreen(),
    ReportsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleUserSwitch());
  }

  Future<void> _handleUserSwitch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storedUid = HiveSetup.getSetting('current_uid') ?? '';

    if (storedUid.isNotEmpty && storedUid != user.uid) {
      // مستخدم مختلف — امسح كل البيانات القديمة
      await HiveSetup.clearUserData();
      // أعد تحميل كل الـ providers من Hive الفاضي
      ref.invalidate(gymProvider);
      ref.invalidate(waterProvider);
      ref.invalidate(tasksProvider);
      ref.invalidate(weightProvider);
      ref.invalidate(mealsProvider);
      ref.invalidate(sleepProvider);
      ref.invalidate(workoutProvider);
    }

    // احفظ الـ UID الحالي
    HiveSetup.setSetting('current_uid', user.uid);

    // اضبط الاسم من Firebase لو مش متسجل
    final storedName = HiveSetup.getSetting('user_name') ?? '';
    if (storedName.isEmpty) {
      final name = user.displayName ??
          (user.email?.split('@').first ?? '');
      if (name.isNotEmpty) HiveSetup.setSetting('user_name', name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentTabProvider);
    final isLight = ref.watch(themeProvider.notifier).isLight;

    return Scaffold(
      body: _screens[currentIndex],
      floatingActionButton: FloatingActionButton(
        heroTag: 'ai_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiChatScreen()),
        ),
        child: const Icon(Icons.smart_toy),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (i) => ref.read(currentTabProvider.notifier).setTab(i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'الجيم'),
          BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'المياه'),
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: 'المهام'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
        ],
      ),
      drawer: _AppDrawer(isLight: isLight, ref: ref),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final bool isLight;
  final WidgetRef ref;

  const _AppDrawer({required this.isLight, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF6C63FF)],
                      ),
                    ),
                    child: const Icon(Icons.fitness_center, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text('عاداتي',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('مدربك الشخصي الذكي',
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : Colors.black45)),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('صور التقدم'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProgressPhotosScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('الإعدادات'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            SwitchListTile(
              secondary: Icon(isLight ? Icons.light_mode : Icons.dark_mode),
              title: Text(isLight ? 'الوضع المضيء' : 'الوضع المظلم'),
              value: isLight,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
