import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Nigeria national colors
  static const green = Color(0xFF008751);
  static const darkGreen = Color(0xFF005C36);
  static const lightGreen = Color(0xFF00B86B);
  static const gold = Color(0xFFFFD700);
  static const white = Color(0xFFFFFFFF);

  // Party colors
  static const apcGreen = Color(0xFF008751);
  static const pdpRed = Color(0xFFC8102E);
  static const lpOrange = Color(0xFFFF6B00);
  static const adcBlue = Color(0xFF003893);
  static const nnppPurple = Color(0xFF6A0DAD);
  static const apgaTeal = Color(0xFF007A5E);

  // Backgrounds (matched to UI reference)
  static const bgDark = Color(0xFF0F231B);
  static const surface = Color(0xFF122A20);
  static const surfaceElevated = Color(0xFF1E4434);
  static const cardBg = Color(0xFF122A20);
  static const borderDark = Color(0xFF1E4434);
  static const hoverBg = Color(0xFF173629);

  // Text
  static const textPrimary = Color(0xFFEEF2EE);
  static const textSecondary = Color(0xFFAABBAA);
  static const textMuted = Color(0xFF677A67);

  // Geopolitical zones
  static const zoneNW = Color(0xFF6A0DAD);
  static const zoneNE = Color(0xFF003893);
  static const zoneNC = Color(0xFF008751);
  static const zoneSW = Color(0xFFFF6B00);
  static const zoneSE = Color(0xFFC8102E);
  static const zoneSS = Color(0xFF0077B6);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: AppColors.green,
      onPrimary: AppColors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.bgDark,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      background: AppColors.bgDark,
      onBackground: AppColors.textPrimary,
      error: AppColors.pdpRed,
      tertiary: AppColors.lightGreen,
    ),
    scaffoldBackgroundColor: AppColors.bgDark,
    textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 32,
      ),
      displayMedium: GoogleFonts.inter(
        color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 26,
      ),
      headlineLarge: GoogleFonts.inter(
        color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 22,
      ),
      headlineMedium: GoogleFonts.inter(
        color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 18,
      ),
      titleLarge: GoogleFonts.inter(
        color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16,
      ),
      bodyLarge: GoogleFonts.inter(
        color: AppColors.textPrimary, fontSize: 16,
      ),
      bodyMedium: GoogleFonts.inter(
        color: AppColors.textSecondary, fontSize: 14,
      ),
      labelLarge: GoogleFonts.inter(
        color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 15,
        letterSpacing: 0.5,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardTheme(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.green,
        side: const BorderSide(color: AppColors.green, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.green, width: 2),
      ),
      labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
      hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceElevated,
      labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.green.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w600);
        }
        return GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.green);
        }
        return const IconThemeData(color: AppColors.textMuted);
      }),
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.textMuted.withOpacity(0.15),
      thickness: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );
}
