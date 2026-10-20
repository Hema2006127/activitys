import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/theme/app_theme.dart';
import 'package:gymapp/core/widgets/glass.dart';
import 'package:gymapp/features/auth/login_screen.dart';
import 'package:gymapp/features/onboarding/onboarding_screen.dart';
import 'package:gymapp/main_screen.dart';

/// جملة تحفيزية بتتغير كل يوم وبتظهر في الـ Splash.
const _dailyQuotes = [
  'كل خطوة صغيرة بتقربك من هدفك 💪',
  'الاستمرارية أهم من الكمال',
  'اشرب مياه… جسمك هيشكرك 💧',
  'النهارده فرصة جديدة تبقى أحسن',
  'العادة بتتبني يوم ورا يوم 🔥',
  'نومك الكويس نص تمرينك 😴',
  'متقارنش نفسك غير بنفسك امبارح',
];

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _progressCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _quoteOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _textOpacity = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _quoteOpacity = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    _introCtrl.forward();
    _progressCtrl.forward().whenComplete(_navigate);
  }

  /// منطق التوجيه:
  /// 1) مسجّل دخول → MainScreen
  /// 2) أنهى Onboarding → LoginScreen
  /// 3) جديد تماماً → OnboardingScreen
  void _navigate() {
    if (!mounted || _navigated) return;
    _navigated = true;

    final user = FirebaseAuth.instance.currentUser;
    Widget destination;

    if (user != null) {
      // المستخدم مسجّل دخوله بالفعل
      destination = const MainScreen();
    } else {
      final onboardingDone = HiveSetup.getSetting('onboarding_done') == 'true';
      destination = onboardingDone
          ? const LoginScreen()
          : const OnboardingScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => destination,
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _ringCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الـ Splash دايماً داكن عشان يتماشى مع Login / Onboarding
    const ink = Colors.white;
    final quote = _dailyQuotes[DateTime.now().weekday % _dailyQuotes.length];

    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
      body: AuroraBackground(
        animated: true,
        child: SafeArea(
          child: GestureDetector(
            // الضغط في أي مكان يتخطى الـ Splash
            behavior: HitTestBehavior.opaque,
            onTap: _navigate,
            child: Column(
              children: [
                const Spacer(flex: 3),

                // ── Logo داخل كارت زجاجي مع حلقة متدرجة بتلف ──
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: GlassContainer(
                      borderRadius: BorderRadius.circular(48),
                      padding: const EdgeInsets.all(22),
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            RotationTransition(
                              turns: _ringCtrl,
                              child: CustomPaint(
                                size: const Size.square(140),
                                painter: _RingPainter(),
                              ),
                            ),
                            const AppLogo(size: 104),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ── الاسم والوصف ──
                FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) =>
                              AppTheme.brandGradient.createShader(b),
                          child: const Text(
                            'عاداتي',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'مدربك الشخصي الذكي',
                          style: TextStyle(
                            fontSize: 16,
                            color: ink.withValues(alpha: 0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── جملة اليوم ──
                FadeTransition(
                  opacity: _quoteOpacity,
                  child: GlassContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    borderRadius: BorderRadius.circular(18),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            size: 18, color: AppTheme.secondaryColor),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            quote,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: ink.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── شريط تحميل متدرج ──
                AnimatedBuilder(
                  animation: _progressCtrl,
                  builder: (_, _) => _GradientProgress(
                    value: Curves.easeInOut.transform(_progressCtrl.value),
                    track: ink.withValues(alpha: 0.1),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Footer ──
                FadeTransition(
                  opacity: _quoteOpacity,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) =>
                              AppTheme.brandGradient.createShader(b),
                          child: const Text(
                            'Hema',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '© ${DateTime.now().year} جميع الحقوق محفوظة',
                          style: TextStyle(
                            color: ink.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _GradientProgress extends StatelessWidget {
  final double value;
  final Color track;
  const _GradientProgress({required this.value, required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 5,
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.brandGradient,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryColor.withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// حلقة متدرجة (بنفسجي ← سماوي ← شفاف) حوالين اللوجو.
class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          AppTheme.primaryColor.withValues(alpha: 0),
          AppTheme.primaryColor,
          AppTheme.secondaryColor,
        ],
      ).createShader(rect);
    canvas.drawArc(rect.deflate(2), 0, 2 * pi * 0.85, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}
