import 'package:flutter/material.dart';

/// Design tokens extracted from Figma design screenshots.
/// Color palette for the factory production tracking system.
class AppColors {
  AppColors._();

  // Primary palette – from Stitch design (#2e75b8)
  static const Color primary = Color(0xFF15558C);
  static const Color primaryLight = Color(0xFF2E73B0);
  static const Color primaryDark = Color(0xFF0D3D66);

  // Dark header color (login screen top area)
  static const Color headerDark = Color(0xFF1A2332);

  // Accent – matches primary for consistency
  static const Color accent = Color(0xFF1B67A7);
  static const Color accentLight = Color(0xFF3B82C2);
  static const Color accentDark = Color(0xFF114D7D);

  // Semantic colors
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF92400E);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Neutral palette
  static const Color background = Color(0xFFF3F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE4EAF2);
  static const Color border = Color(0xFFB9C3CF);
  static const Color divider = Color(0xFFC9D3DE);
  static const Color inputFill = Color(0xFFF9FBFD);

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF344054);
  static const Color textHint = Color(0xFF667085);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // Shift indicator colors
  static const Color shift1 = Color(0xFF6C5CE7);
  static const Color shift2 = Color(0xFF00B894);
  static const Color shift3 = Color(0xFFE17055);

  // Chart/distribution colors
  static const Color chartBlue = Color(0xFF2563EB);
  static const Color chartGreen = Color(0xFF16A34A);
  static const Color chartRed = Color(0xFFDC2626);
  static const Color chartOrange = Color(0xFFF59E0B);

  // Section progress bar color
  static const Color progressBar = Color(0xFF2563EB);
  static const Color progressBarBg = Color(0xFFE5E7EB);

  // Stage colors (for dashboard cards)
  static const List<Color> stageColors = [
    Color(0xFF6C5CE7),
    Color(0xFF0984E3),
    Color(0xFF00B894),
    Color(0xFFFDAA1B),
    Color(0xFFE17055),
    Color(0xFFA29BFE),
    Color(0xFF00CEC9),
    Color(0xFFFF7675),
    Color(0xFF55EFC4),
    Color(0xFFDFE6E9),
    Color(0xFF636E72),
  ];
}
