import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/providers/water_provider.dart';
import 'package:gymapp/core/theme/app_theme.dart';

class WaterScreen extends ConsumerStatefulWidget {
  const WaterScreen({super.key});

  @override
  ConsumerState<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends ConsumerState<WaterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waterLog   = ref.watch(waterProvider);
    final percentage = (waterLog.amount / waterLog.goal).clamp(0.0, 1.0);
    final cups       = waterLog.amount ~/ 250;
    final goalCups   = (waterLog.goal ~/ 250).clamp(1, 12);

    return Scaffold(
      appBar: AppBar(title: const Text('تتبع المياه')),
      body: Column(
        children: [
          const SizedBox(height: 36),

          // ── Wave circle ────────────────────────────────────────────────────
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Wave fill
                  // المية بتطلع تدريجياً لما تضيف كوباية
                  ClipOval(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: percentage),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, fill, _) => AnimatedBuilder(
                        animation: _waveController,
                        builder: (_, _) => CustomPaint(
                          painter: _WavePainter(
                            fillPercent: fill,
                            phase: _waveController.value * 2 * pi,
                          ),
                          size: const Size(240, 240),
                        ),
                      ),
                    ),
                  ),
                  // Border ring
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.35),
                        width: 3,
                      ),
                    ),
                  ),
                  // Text overlay
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(percentage * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                        ),
                      ),
                      Text(
                        '${waterLog.amount} مل',
                        style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'الهدف: ${waterLog.goal} مل',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Cup indicators ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: List.generate(goalCups, (i) => AnimatedScale(
                scale: i < cups ? 1.0 : 0.8,
                duration: Duration(milliseconds: 300 + i * 40),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    i < cups ? Icons.water_drop : Icons.water_drop_outlined,
                    key: ValueKey(i < cups),
                    color: i < cups ? AppTheme.secondaryColor : Colors.white24,
                    size: 24,
                  ),
                ),
              )),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$cups / $goalCups كوب',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),

          const Spacer(),

          // ── Buttons ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 52),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WaterBtn(
                  label: '-250',
                  sublabel: 'مل',
                  color: Colors.redAccent,
                  size: 56,
                  onTap: () => ref.read(waterProvider.notifier).addWater(-250),
                ),
                const SizedBox(width: 16),
                _WaterBtn(
                  label: '+500',
                  sublabel: 'مل',
                  color: Colors.blue.shade300,
                  size: 70,
                  onTap: () => ref.read(waterProvider.notifier).addWater(500),
                ),
                const SizedBox(width: 16),
                _WaterBtn(
                  label: '+250',
                  sublabel: 'مل',
                  color: Colors.blue,
                  size: 56,
                  onTap: () => ref.read(waterProvider.notifier).addWater(250),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wave Painter ──────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double fillPercent;
  final double phase;

  const _WavePainter({required this.fillPercent, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * (1.0 - fillPercent);

    _drawWave(canvas, size, baseY, phase + pi,
        Colors.blue.withValues(alpha: 0.30));
    _drawWave(canvas, size, baseY, phase,
        Colors.blue.withValues(alpha: 0.65));
  }

  void _drawWave(Canvas canvas, Size size, double baseY, double shift, Color color) {
    const amp = 9.0;
    final path = Path()..moveTo(0, baseY);

    for (double x = 0; x <= size.width + 1; x++) {
      final y = baseY + amp * sin((x / size.width * 2 * pi) + shift);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.fillPercent != fillPercent || old.phase != phase;
}

// ── Round water button ────────────────────────────────────────────────────────
class _WaterBtn extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _WaterBtn({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.bold)),
            Text(sublabel,
                style: TextStyle(
                    color: Colors.white70, fontSize: size * 0.14)),
          ],
        ),
      ),
    );
  }
}
