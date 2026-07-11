import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.gold,
      scaffoldBackgroundColor: AppColors.darkNavy,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.blueAccent,
        surface: AppColors.navy,
        error: AppColors.expense,
        onPrimary: AppColors.navy,
        onSecondary: AppColors.white,
        onSurface: AppColors.white,
        surfaceContainer: AppColors.darkNavy, // Explicit for older Flutter support
        onSurfaceVariant: AppColors.grey,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: AppColors.white),
        bodyMedium: GoogleFonts.inter(color: AppColors.offWhite),
      ),
      cardTheme: CardThemeData(
        color: AppColors.navy,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: AppColors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navy,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navy,
      ),
      elevatedButtonTheme: _buttonTheme(isDark: true),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.gold,
      scaffoldBackgroundColor: AppColors.offWhite,
      colorScheme: ColorScheme.light(
        primary: AppColors.gold,
        secondary: AppColors.blueAccent,
        surface: Colors.white,
        error: AppColors.expense,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.navy,
        surfaceContainer: Colors.grey[100]!, // Explicit
        onSurfaceVariant: Colors.grey[700]!,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(color: AppColors.navy, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.inter(color: AppColors.navy, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.inter(color: AppColors.navy, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.offWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: AppColors.navy, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: AppColors.navy),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: _buttonTheme(isDark: false),
    );
  }

  static ElevatedButtonThemeData _buttonTheme({required bool isDark}) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: isDark ? AppColors.navy : Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: isDark ? 0 : 2,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
