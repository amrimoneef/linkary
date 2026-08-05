import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.lightBg,
      cardColor: AppColors.lightCard,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.accentGreen,
        surface: AppColors.lightCard,
        error: AppColors.errorRed,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge(false),
        displayMedium: AppTextStyles.displayMedium(false),
        titleLarge: AppTextStyles.titleLarge(false),
        titleMedium: AppTextStyles.titleMedium(false),
        bodyLarge: AppTextStyles.bodyLarge(false),
        bodyMedium: AppTextStyles.bodyMedium(false),
        labelLarge: AppTextStyles.labelLarge(false),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkCard,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        secondary: AppColors.accentGreen,
        surface: AppColors.darkCard,
        error: AppColors.errorRed,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge(true),
        displayMedium: AppTextStyles.displayMedium(true),
        titleLarge: AppTextStyles.titleLarge(true),
        titleMedium: AppTextStyles.titleMedium(true),
        bodyLarge: AppTextStyles.bodyLarge(true),
        bodyMedium: AppTextStyles.bodyMedium(true),
        labelLarge: AppTextStyles.labelLarge(true),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.accentGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
      ),
    );
  }
}
