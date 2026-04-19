import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark palette
  static const Color primaryColor  = Color(0xFF00E5FF);
  static const Color accentColor   = Color(0xFF00FFA3);
  static const Color bgColor       = Color(0xFF121212);
  static const Color surfaceColor  = Color(0xFF1E1E1E);

  // Light palette
  static const Color lightPrimary  = Color(0xFF0077B6);
  static const Color lightAccent   = Color(0xFF00B07A);
  static const Color lightBg       = Color(0xFFF5F7FA);
  static const Color lightSurface  = Color(0xFFFFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge:   GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge:    GoogleFonts.inter(fontSize: 16, color: Colors.white70),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightAccent,
        surface: lightSurface,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E)),
        titleLarge:   GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),
        bodyLarge:    GoogleFonts.inter(fontSize: 16, color: const Color(0xFF444466)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Color(0xFF1A1A2E),
        iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightPrimary,
        unselectedItemColor: Colors.black38,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
