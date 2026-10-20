import 'package:flutter/material.dart';
import 'package:gymapp/core/theme/app_theme.dart';
import 'package:gymapp/core/widgets/glass.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/features/settings/settings_screen.dart';
import 'package:gymapp/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController();
  int _waterGoal = 2000;
  int _gymDaysGoal = 4;

  late AnimationController _iconController;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _iconScale = CurvedAnimation(parent: _iconController, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _iconController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    HiveSetup.setSetting('onboarding_done', 'true');
    if (_nameController.text.trim().isNotEmpty) {
      HiveSetup.setSetting('user_name', _nameController.text.trim());
    }
    HiveSetup.setSetting('water_goal', _waterGoal.toString());
    HiveSetup.setSetting('gym_days_goal', _gymDaysGoal.toString());

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => const MainScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
      body: AuroraBackground(
        animated: true,
        child: SafeArea(
          child: Column(
            children: [
              // Progress dots
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 14),
                        child: _Dot(active: i == _currentPage),
                      ),
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _WelcomePage(iconScale: _iconScale),
                    _NamePage(controller: _nameController),
                    _GoalsPage(
                      waterGoal: _waterGoal,
                      gymDaysGoal: _gymDaysGoal,
                      onWaterChanged: (v) => setState(() => _waterGoal = v),
                      onGymDaysChanged: (v) => setState(() => _gymDaysGoal = v),
                    ),
                  ],
                ),
              ),

              // Bottom button
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 36),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _nextPage,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage < 2 ? 'التالي' : 'ابدأ الرحلة!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage < 2
                              ? Icons.arrow_forward_rounded
                              : Icons.rocket_launch_rounded,
                          size: 20,
                          textDirection: Directionality.of(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

// ── Page 1: Welcome ───────────────────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  final Animation<double> iconScale;
  const _WelcomePage({required this.iconScale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: iconScale,
            child: const AppLogo(size: 120),
          ),
          const SizedBox(height: 40),
          const Text(
            'أهلاً بيك في\nعاداتي!',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'مدربك الشخصي الذكي،\nهيساعدك تتابع جيمك، مياهك، نومك، ووزنك كل يوم.',
            style: TextStyle(fontSize: 16, color: Colors.white60, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Name ──────────────────────────────────────────────────────────────
class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  const _NamePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👋', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 24),
          const Text(
            'إيه اسمك؟',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'عشان التطبيق يعرف يكلمك بالاسم',
            style: TextStyle(fontSize: 16, color: Colors.white54),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 20),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'اكتب اسمك هنا...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.secondaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 3: Goals ─────────────────────────────────────────────────────────────
class _GoalsPage extends StatelessWidget {
  final int waterGoal;
  final int gymDaysGoal;
  final ValueChanged<int> onWaterChanged;
  final ValueChanged<int> onGymDaysChanged;

  const _GoalsPage({
    required this.waterGoal,
    required this.gymDaysGoal,
    required this.onWaterChanged,
    required this.onGymDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('🎯', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 20),
          const Text(
            'حدّد أهدافك',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'هتعديها في أي وقت من الإعدادات',
            style: TextStyle(fontSize: 15, color: Colors.white54),
          ),
          const SizedBox(height: 40),

          // Water goal
          _GoalTile(
            icon: Icons.water_drop,
            color: Colors.blue,
            label: 'هدف المياه اليومي',
            value: '${waterGoal ~/ 1000}.${(waterGoal % 1000) ~/ 100} لتر  ($waterGoal مل)',
            child: Slider(
              value: waterGoal.toDouble(),
              min: 1000,
              max: 4000,
              divisions: 12,
              activeColor: Colors.blue,
              onChanged: (v) => onWaterChanged(v.round()),
            ),
          ),
          const SizedBox(height: 24),

          // Gym days goal
          _GoalTile(
            icon: Icons.fitness_center,
            color: AppTheme.secondaryColor,
            label: 'أيام الجيم في الأسبوع',
            value: '$gymDaysGoal أيام',
            child: Slider(
              value: gymDaysGoal.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              activeColor: AppTheme.secondaryColor,
              onChanged: (v) => onGymDaysChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final Widget child;

  const _GoalTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          child,
        ],
      ),
    );
  }
}

// ── Progress dot ──────────────────────────────────────────────────────────────
class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppTheme.secondaryColor : Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
