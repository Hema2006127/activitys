import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gymapp/core/theme/app_theme.dart';

class StreakCelebrationOverlay extends StatefulWidget {
  final int streak;
  final VoidCallback onDone;

  const StreakCelebrationOverlay({
    required this.streak,
    required this.onDone,
    super.key,
  });

  @override
  State<StreakCelebrationOverlay> createState() => _StreakCelebrationOverlayState();
}

class _StreakCelebrationOverlayState extends State<StreakCelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _cardController;
  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(70, (_) => _Particle(rng));

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..forward().whenComplete(widget.onDone);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _cardScale = CurvedAnimation(parent: _cardController, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _cardOpacity = CurvedAnimation(parent: _cardController, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardController.forward();
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  String _getMilestoneMessage() {
    if (widget.streak >= 30) return 'وحش حقيقي!\nشهر كامل متوقفتش!';
    if (widget.streak >= 21) return 'ثلاث أسابيع!\nاستمر يا بطل!';
    if (widget.streak >= 14) return 'أسبوعين قوة!\nمش بتتوقف!';
    return 'أسبوع كامل!\nخطوة عظيمة!';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: GestureDetector(
        onTap: () {
          _particleController.stop();
          widget.onDone();
        },
        child: Stack(
          children: [
            // Confetti particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ConfettiPainter(_particles, _particleController.value),
                  size: MediaQuery.of(context).size,
                );
              },
            ),

            // Celebration card
            Center(
              child: AnimatedBuilder(
                animation: _cardController,
                builder: (context, child) => Opacity(
                  opacity: _cardOpacity.value,
                  child: Transform.scale(scale: _cardScale.value, child: child),
                ),
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.35),
                        AppTheme.bgMid.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.6), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.streak} يوم',
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'سلسلة رائعة!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getMilestoneMessage(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'اضغط في أي مكان للإغلاق',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double speed;
  final double size;
  final Color color;
  final double startDelay;
  final double swayAmp;
  final double swayFreq;
  final bool isRect;

  _Particle(Random rng)
      : x = rng.nextDouble(),
        speed = 0.25 + rng.nextDouble() * 0.65,
        size = 5 + rng.nextDouble() * 9,
        color = const [
          Colors.red,
          Colors.blue,
          Colors.yellow,
          Colors.green,
          Colors.purple,
          Colors.orange,
          Colors.pink,
          Colors.cyan,
          Colors.lime,
          Colors.teal,
        ][rng.nextInt(10)],
        startDelay = rng.nextDouble() * 0.35,
        swayAmp = 20 + rng.nextDouble() * 40,
        swayFreq = 1.5 + rng.nextDouble() * 2.5,
        isRect = rng.nextBool();
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress; // 0.0 → 1.0

  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress - p.startDelay).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final normalizedT = t / (1 - p.startDelay).clamp(0.01, 1.0);
      final y = normalizedT * size.height * p.speed * 1.6;
      final x = p.x * size.width + sin(normalizedT * pi * p.swayFreq) * p.swayAmp;
      final opacity = t < 0.1 ? t / 0.1 : (t > 0.85 ? (1.0 - t) / 0.15 : 1.0);

      final paint = Paint()..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0));

      if (p.isRect) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(normalizedT * pi * 4);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(x, y), p.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

bool isStreakMilestone(int streak) => streak > 0 && streak % 7 == 0;
