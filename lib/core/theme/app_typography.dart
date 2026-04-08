import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography scale derived from Figma design.
class AppTypography {
  AppTypography._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    required Color color,
    double height = 1.45,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.notoSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle get headlineLarge => _base(
        size: 30,
        weight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headlineMedium => _base(
        size: 24,
        weight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headlineSmall => _base(
        size: 20,
        weight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get titleLarge => _base(
        size: 18,
        weight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get titleMedium => _base(
        size: 16,
        weight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyLarge => _base(
        size: 16,
        weight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => _base(
        size: 14,
        weight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => _base(
        size: 13,
        weight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.45,
      );

  static TextStyle get labelLarge => _base(
        size: 14,
        weight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get labelSmall => _base(
        size: 12,
        weight: FontWeight.w600,
        color: AppColors.textSecondary,
        height: 1.35,
        letterSpacing: 0.25,
      );

  static TextStyle get button => _base(
        size: 15,
        weight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.4,
        letterSpacing: 0.2,
      );

  static TextTheme get textTheme => TextTheme(
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelSmall: labelSmall,
      );
}
