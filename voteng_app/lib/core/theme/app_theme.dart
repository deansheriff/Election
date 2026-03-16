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
    textTheme: GoogleFonts.publicSansTextTheme(base.textTheme).copyWith(
      displayMedium: GoogleFonts.publicSans(
        fontSize: 45,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: AppColors.white,
      ),
      displaySmall: GoogleFonts.publicSans(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.white,
      ),
      headlineLarge: GoogleFonts.publicSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.white,
      ),
      headlineMedium: GoogleFonts.publicSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.white,
      ),
      headlineSmall: GoogleFonts.publicSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      titleLarge: GoogleFonts.publicSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.publicSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.publicSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.publicSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.publicSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: AppColors.textPrimary,
      ),
      bodySmall: GoogleFonts.publicSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.publicSans(
        color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 15,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.publicSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.textPrimary,
      ),
      labelSmall: GoogleFonts.publicSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.textPrimary,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.publicSans(
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
        textStyle: GoogleFonts.publicSans(fontWeight: FontWeight.w600, fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.textMuted),
        textStyle: GoogleFonts.publicSans(fontWeight: FontWeight.w600, fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.green,
        textStyle: GoogleFonts.publicSans(fontWeight: FontWeight.w600, fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBg),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBg),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.green),
      ),
      labelStyle: GoogleFonts.publicSans(color: AppColors.textMuted),
      hintStyle: GoogleFonts.publicSans(color: AppColors.textMuted.withOpacity(0.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceElevated,
      labelStyle: GoogleFonts.publicSans(color: AppColors.textSecondary, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.green.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.publicSans(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w600);
        }
        return GoogleFonts.publicSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.surface,
      selectedIconTheme: const IconThemeData(color: AppColors.green),
      unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
      selectedLabelTextStyle: GoogleFonts.publicSans(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: GoogleFonts.publicSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
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
