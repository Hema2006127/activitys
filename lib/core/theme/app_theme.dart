import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymapp/core/widgets/glass.dart';

/// نظام ألوان موحّد للتطبيق كله (Splash / Login / Onboarding / الشاشات الداخلية)
/// كل الألوان تُستخدم من هنا فقط عشان يفضل التطبيق متناسق.
class AppTheme {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primaryColor   = Color(0xFF7C5CFF); // بنفسجي
  static const Color secondaryColor = Color(0xFF22D3EE); // سماوي
  static const Color accentColor    = Color(0xFF34D399); // نعناعي (نجاح/إنجاز)
  static const Color warningColor   = Color(0xFFFBBF24);
  static const Color errorColor     = Color(0xFFF87171);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Dark background ────────────────────────────────────────────────────────
  static const Color bgColor      = Color(0xFF0A0A1F);
  static const Color bgMid        = Color(0xFF11113A);
  static const Color bgEnd        = Color(0xFF0B1B36);
  static const Color surfaceColor = Color(0x1AFFFFFF); // زجاج داكن
  static const Color sheetDark    = Color(0xE6161638);

  // ── Light background ───────────────────────────────────────────────────────
  static const Color lightPrimary = Color(0xFF6A4BF5);
  static const Color lightAccent  = Color(0xFF10B981);
  static const Color lightBg      = Color(0xFFF1EEFF);
  static const Color lightMid     = Color(0xFFF7F8FF);
  static const Color lightEnd     = Color(0xFFE6F7FB);
  static const Color lightSurface = Color(0x99FFFFFF); // زجاج فاتح
  static const Color sheetLight   = Color(0xF2F7F6FF);
  static const Color inkColor     = Color(0xFF1B1840);

  static List<Color> backgroundColors(Brightness b) => b == Brightness.dark
      ? const [bgColor, bgMid, bgEnd]
      : const [lightBg, lightMid, lightEnd];

  static ThemeData get darkTheme => _build(Brightness.dark);
  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final primary = dark ? primaryColor : lightPrimary;
    final ink = dark ? Colors.white : inkColor;
    final glassBorder = dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.7);
    final sheet = dark ? sheetDark : sheetLight;
    final base = dark ? ThemeData.dark() : ThemeData.light();

    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: glassBorder),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      primaryColor: primary,
      // الخلفية شفافة: AuroraBackground بيترسم ورا كل الشاشات
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      colorScheme: (dark ? const ColorScheme.dark() : const ColorScheme.light())
          .copyWith(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: inkColor,
        tertiary: dark ? accentColor : lightAccent,
        error: errorColor,
        surface: dark ? surfaceColor : lightSurface,
        onSurface: ink,
        surfaceTint: Colors.transparent,
      ),
      textTheme: textTheme,
      iconTheme: IconThemeData(color: ink),
      dividerTheme: DividerThemeData(color: glassBorder, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: dark ? surfaceColor : lightSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: dark ? 0.25 : 0.06),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: glassBorder),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.6),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: glassBorder),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheet,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: sheet,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrimColor: Colors.black.withValues(alpha: 0.35),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: sheet,
        contentTextStyle: GoogleFonts.cairo(color: ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: glassBorder),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: ink.withValues(alpha: 0.55),
        indicatorColor: primary,
        dividerColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      sliderTheme: SliderThemeData(activeTrackColor: primary, thumbColor: primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : null,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: GlassPageTransitionsBuilder(),
          TargetPlatform.iOS: GlassPageTransitionsBuilder(),
          TargetPlatform.windows: GlassPageTransitionsBuilder(),
          TargetPlatform.macOS: GlassPageTransitionsBuilder(),
          TargetPlatform.linux: GlassPageTransitionsBuilder(),
        },
      ),
    );
  }
}
