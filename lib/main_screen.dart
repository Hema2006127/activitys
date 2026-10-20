import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/navigation.dart';
import 'package:gymapp/core/providers/gym_provider.dart';
import 'package:gymapp/core/providers/meals_provider.dart';
import 'package:gymapp/core/providers/sleep_provider.dart';
import 'package:gymapp/core/providers/sleep_session_provider.dart';
import 'package:gymapp/core/providers/tab_provider.dart';
import 'package:gymapp/core/providers/tasks_provider.dart';
import 'package:gymapp/core/providers/theme_provider.dart';
import 'package:gymapp/core/providers/water_provider.dart';
import 'package:gymapp/core/providers/weight_provider.dart';
import 'package:gymapp/core/providers/workout_provider.dart';
import 'package:gymapp/core/services/health_service.dart';
import 'package:gymapp/core/services/home_widget_service.dart';
import 'package:gymapp/core/services/notification_service.dart';
import 'package:gymapp/core/services/smart_reminders.dart';
import 'package:gymapp/core/services/task_reminders.dart';
import 'package:gymapp/core/services/weekly_report_service.dart';
import 'package:gymapp/core/theme/app_theme.dart';
import 'package:gymapp/core/widgets/glass.dart';
import 'package:gymapp/features/ai_chat/presentation/screens/ai_chat_screen.dart';
import 'package:gymapp/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:gymapp/features/gym/presentation/screens/gym_screen.dart';
import 'package:gymapp/features/progress_photos/progress_photos_screen.dart';
import 'package:gymapp/features/reports/presentation/screens/reports_screen.dart';
import 'package:gymapp/features/settings/settings_screen.dart';
import 'package:gymapp/features/sleep/sleep_tracker.dart';
import 'package:gymapp/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:gymapp/features/water/presentation/screens/water_screen.dart';
import 'package:gymapp/features/weight/presentation/screens/weight_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  static const _screens = [
    DashboardScreen(),
    GymScreen(),
    WaterScreen(),
    TasksScreen(),
    ReportsScreen(),
  ];

  StreamSubscription<Uri?>? _widgetClicks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _handleUserSwitch();
      await _onAppActive();
      await HomeWidgetService.listenForLaunches(ref, (s) => _widgetClicks = s);
      // الضغط على إشعار → الشاشة المناسبة
      _openFromNotification(await NotificationService.launchPayload());
      _notificationTaps = NotificationService.taps.listen(_openFromNotification);
    });
  }

  StreamSubscription<String?>? _notificationTaps;

  void _openFromNotification(String? payload) {
    const tabs = {'home': 0, 'gym': 1, 'water': 2, 'tasks': 3, 'reports': 4};
    final tab = tabs[payload];
    if (tab == null || !mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    ref.read(currentTabProvider.notifier).setTab(tab);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetClicks?.cancel();
    _notificationTaps?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // رجوع للتطبيق: هات المياه اللي اتضافت من الـ Widget وحدّثه (ممكن يكون يوم جديد)
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(waterProvider);
      ref.invalidate(sleepProvider);
      ref.invalidate(mealsProvider);
      _onAppActive();
    }
  }

  /// كل ما التطبيق يتفتح أو يرجع من الخلفية.
  Future<void> _onAppActive() async {
    await HomeWidgetService.consumePendingWater(ref);
    await HealthService.sync(ref); // خطوات + نوم + وزن من Apple Health
    final water = ref.read(waterProvider);
    await SmartReminders.reschedule(amount: water.amount, goal: water.goal);
    await TaskReminders.reschedule(ref.read(tasksProvider));
    await HomeWidgetService.sync(ref);
    WeeklyReportService.maybeGenerate(ref); // في الخلفية

    // فتح الصبح وهو لسه "نايم" في التطبيق → اسأله صحيت؟
    if (mounted && ref.read(sleepSessionProvider.notifier).shouldAskOnOpen) {
      ref.read(currentTabProvider.notifier).setTab(0);
      await showWakeUpSheet(context, ref);
    }
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

    // أي تغيير في العادات يحدّث الـ Widget
    void sync(_, _) => HomeWidgetService.scheduleSync(ref);
    ref.listen(gymProvider, sync);
    ref.listen(waterProvider, sync);
    ref.listen(tasksProvider, sync);
    ref.listen(sleepProvider, sync);
    ref.listen(mealsProvider, sync);
    // تذكيرات المياه بتتحسب من جديد مع كل كوباية
    ref.listen(waterProvider, (_, w) =>
        SmartReminders.reschedule(amount: w.amount, goal: w.goal));
    // تذكيرات المهام بأسمائها بتتحدث مع أي إضافة/تعليم/حذف
    ref.listen(tasksProvider, (_, t) => TaskReminders.reschedule(t));
    final reportUnread = ref.watch(weeklyReportUnreadProvider);

    return Scaffold(
      key: mainScaffoldKey,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.02), end: Offset.zero)
                .animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(currentIndex),
          child: _screens[currentIndex],
        ),
      ),
      floatingActionButton: _AiFab(
        badge: reportUnread,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiChatScreen()),
        ),
      ),
      bottomNavigationBar: _GlassNavBar(
        currentIndex: currentIndex,
        onTap: (i) => ref.read(currentTabProvider.notifier).setTab(i),
      ),
      drawer: _AppDrawer(isLight: isLight, ref: ref),
    );
  }
}

// ── Floating glass bottom navigation ─────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'الرئيسية'),
    _NavItem(Icons.fitness_center_outlined, Icons.fitness_center_rounded, 'الجيم'),
    _NavItem(Icons.water_drop_outlined, Icons.water_drop_rounded, 'المياه'),
    _NavItem(Icons.check_circle_outline_rounded, Icons.check_circle_rounded, 'المهام'),
    _NavItem(Icons.insights_outlined, Icons.insights_rounded, 'التقارير'),
  ];

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final selected = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: selected
                        ? LinearGradient(colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.35),
                            AppTheme.secondaryColor.withValues(alpha: 0.25),
                          ])
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 24,
                          color: selected ? ink : ink.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? ink : ink.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _AiFab extends StatelessWidget {
  final VoidCallback onPressed;
  final bool badge; // تقرير أسبوعي جديد
  const _AiFab({required this.onPressed, this.badge = false});

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: badge,
      smallSize: 14,
      backgroundColor: AppTheme.warningColor,
      child: _fab(),
    );
  }

  Widget _fab() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.brandGradient,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'ai_fab',
        backgroundColor: Colors.transparent,
        tooltip: 'المدرب الذكي',
        onPressed: onPressed,
        child: const Icon(Icons.auto_awesome_rounded),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final bool isLight;
  final WidgetRef ref;

  const _AppDrawer({required this.isLight, required this.ref});

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Drawer(
      child: GlassContainer(
        blur: 24,
        borderRadius: const BorderRadiusDirectional.horizontal(
          end: Radius.circular(28),
        ).resolve(Directionality.of(context)),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Row(
                  children: [
                    const AppLogo(size: 56),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('عاداتي',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('مدربك الشخصي الذكي',
                            style: TextStyle(
                                fontSize: 13, color: ink.withValues(alpha: 0.55))),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              const SizedBox(height: 8),
              _DrawerTile(
                icon: Icons.photo_library_outlined,
                title: 'صور التقدم',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProgressPhotosScreen()),
                  );
                },
              ),
              _DrawerTile(
                icon: Icons.monitor_weight_outlined,
                title: 'تتبع الوزن',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WeightScreen()),
                  );
                },
              ),
              _DrawerTile(
                icon: Icons.settings_outlined,
                title: 'الإعدادات',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(14),
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(18),
                  child: SwitchListTile(
                    secondary: Icon(isLight ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                    title: Text(isLight ? 'الوضع المضيء' : 'الوضع المظلم'),
                    value: isLight,
                    onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_left_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }
}
