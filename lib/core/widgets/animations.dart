import 'package:flutter/material.dart';

/// ظهور تدريجي: fade + slide لتحت لفوق، مع تأخير حسب [index] (تأثير متتالي).
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration step;
  final Duration duration;
  final double offsetY;

  const FadeSlideIn({
    required this.child,
    this.index = 0,
    this.step = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 450),
    this.offsetY = 24,
    super.key,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    // سقف للتأخير عشان العناصر البعيدة ماتستناش كتير
    final delay = widget.step * widget.index.clamp(0, 10);
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (_, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// تصغير بسيط وقت الضغط (إحساس زرار حقيقي). مابيستهلكش الضغطة.
class PressScale extends StatefulWidget {
  final Widget child;
  final double scale;

  const PressScale({required this.child, this.scale = 0.96, super.key});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// تغيير رقم/نص بأنيميشن (fade + scale) بدل ما يتبدل فجأة.
class AnimatedValue extends StatelessWidget {
  final String value;
  final TextStyle? style;

  const AnimatedValue(this.value, {this.style, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.7, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
      child: Text(value, key: ValueKey(value), style: style),
    );
  }
}
