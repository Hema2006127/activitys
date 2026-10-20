import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gymapp/core/theme/app_theme.dart';
import 'package:gymapp/core/widgets/animations.dart';

/// سطح زجاجي (Glassmorphism): blur للي وراه + لون شفاف + حدّ فاتح.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final double blur;
  final Color? tint;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassContainer({
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.blur = 18,
    this.tint,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = tint ??
        (dark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.55));

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: gradient == null ? fill : null,
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                fill.withValues(alpha: (fill.a * 1.6).clamp(0.0, 1.0)),
                fill,
              ],
            ),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.8),
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    Widget glass = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
    if (onTap != null) glass = PressScale(child: glass);

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: glass,
    );
  }
}

/// خلفية "أورورا": تدرج + بقع ألوان ناعمة من ألوان البراند.
/// لما [animated] تكون true البقع بتتحرك ببطء (مستخدمة في الـ Splash).
class AuroraBackground extends StatefulWidget {
  final Widget? child;
  final bool animated;
  final Brightness? brightness;

  const AuroraBackground({
    this.child,
    this.animated = false,
    this.brightness,
    super.key,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 14),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.brightness ?? Theme.of(context).brightness;
    final painter = _ctrl == null
        ? CustomPaint(painter: _AuroraPainter(0, b))
        : AnimatedBuilder(
            animation: _ctrl!,
            builder: (_, _) =>
                CustomPaint(painter: _AuroraPainter(_ctrl!.value, b)),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.backgroundColors(b),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: painter),
          ?widget.child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final Brightness brightness;

  _AuroraPainter(this.t, this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final dark = brightness == Brightness.dark;
    final a = 2 * pi * t;
    final blobs = [
      (AppTheme.primaryColor, Offset(0.15 + 0.08 * sin(a), 0.12 + 0.05 * cos(a)), 0.75),
      (AppTheme.secondaryColor, Offset(0.95 - 0.08 * cos(a), 0.45 + 0.07 * sin(a)), 0.65),
      (const Color(0xFFEC4899), Offset(0.2 + 0.06 * cos(a), 0.92 - 0.05 * sin(a)), 0.6),
    ];

    for (final (color, pos, r) in blobs) {
      final center = Offset(pos.dx * size.width, pos.dy * size.height);
      final radius = r * size.shortestSide;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: dark ? 0.35 : 0.22),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.t != t || old.brightness != brightness;
}

/// انتقال الصفحات: كل صفحة جديدة بتترسم فوق خلفية الأورورا (عشان الـ Scaffold شفاف)
/// مع fade + slide خفيف.
class GlassPageTransitionsBuilder extends PageTransitionsBuilder {
  const GlassPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
            .animate(curved),
        child: AuroraBackground(child: child),
      ),
    );
  }
}

/// أيقونة/لوجو التطبيق بنفس الشكل في كل مكان.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({this.size = 90, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.brandGradient,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.45),
            blurRadius: size * 0.4,
            spreadRadius: size * 0.03,
          ),
        ],
      ),
      child: Icon(Icons.fitness_center_rounded,
          size: size * 0.5, color: Colors.white),
    );
  }
}
