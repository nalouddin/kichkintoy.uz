import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bolalar uchun yorqin, ammo ko'zni charchatmaydigan ranglar va dizayn.
class AppTheme {
  // ============ RANGLAR ============
  // Asosiy ranglar - yumshoq, do'stona
  static const Color primaryColor = Color(0xFF4ECDC4);    // Yumshoq turquoise
  static const Color secondaryColor = Color(0xFFFF6B6B);  // Yumshoq qizil
  static const Color accentColor = Color(0xFFFFE66D);     // Quyoshli sariq
  static const Color successColor = Color(0xFF95E1A3);    // Yumshoq yashil

  // Fon ranglari
  static const Color backgroundColor = Color(0xFFFFF9F0); // Issiq krem
  static const Color cardColor = Colors.white;

  // Matn
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);

  // O'yin kategoriyalari uchun ranglar
  static const Color letterColor = Color(0xFFFF6B9D);   // Harflar - pushti
  static const Color numberColor = Color(0xFF4ECDC4);   // Sonlar - turquoise
  static const Color colorGameColor = Color(0xFFFFA502); // Ranglar - to'q sariq
  static const Color shapeColor = Color(0xFF6C5CE7);    // Shakllar - binafsha

  // ============ TEMA ============
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundColor,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),

    // Bolalar uchun katta, o'qish oson font
    textTheme: GoogleFonts.comicNeueTextTheme().copyWith(
      displayLarge: GoogleFonts.comicNeue(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.comicNeue(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.comicNeue(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.comicNeue(
        fontSize: 18,
        color: textPrimary,
      ),
    ),

    // Katta, bosish oson tugmalar (bolalar uchun)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(150, 60),
        textStyle: GoogleFonts.comicNeue(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
      ),
    ),

    // Yumaloq kartalar
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: cardColor,
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.comicNeue(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    // Forma maydonchalari
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),
  );
}
