import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // AppTextStyles definitions using Google Fonts Cairo

  static TextStyle displayLarge(bool isDark) => GoogleFonts.cairo(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkText : AppColors.lightText,
      );

  static TextStyle displayMedium(bool isDark) => GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkText : AppColors.lightText,
      );

  static TextStyle titleLarge(bool isDark) => GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkText : AppColors.lightText,
      );

  static TextStyle titleMedium(bool isDark) => GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkText : AppColors.lightText,
      );

  static TextStyle bodyLarge(bool isDark) => GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: isDark ? AppColors.darkText : AppColors.lightText,
      );

  static TextStyle bodyMedium(bool isDark) => GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      );

  static TextStyle labelLarge(bool isDark) => GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkText : AppColors.lightText,
      );
}
