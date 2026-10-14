import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// MasakYuk — Warm Spice Kitchen tokens (dari DesignMasakYukMobile/warm_spice_kitchen/DESIGN.md)
class AppColors {
  static const primary = Color(0xFF9F3C16); // terracotta tua (CTA)
  static const primaryContainer = Color(0xFFBF542C);
  static const amber = Color(0xFFE28743); // rating / aksen
  static const secondary = Color(0xFF944A05); // aksen tua (pita harga)
  static const cream = Color(0xFFFFF8F0); // background
  static const sand = Color(0xFFF3EBE1); // kartu / input
  static const chocolate = Color(0xFF3D2314); // teks
  static const chocolateMuted = Color(0xFF6E5343);
  static const error = Color(0xFFBA1A1A);
}

class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      secondary: Color(0xFF944A05),
      surface: AppColors.cream,
      onSurface: AppColors.chocolate,
      error: AppColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: GoogleFonts.nunitoSansTextTheme(
        ThemeData.light().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // Tombol pill 52px sesuai desain
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      // Kartu rounded 24px, bayangan hangat
      cardTheme: CardThemeData(
        color: AppColors.sand,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      // Chip: default sand, selected terracotta (atur via ChoiceChip selectedColor)
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sand,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(color: AppColors.chocolate),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.sand,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Color(0x663D2314),
      ),
    );
  }
}
