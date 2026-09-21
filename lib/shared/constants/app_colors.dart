import 'package:flutter/material.dart';

/// Centralized color tokens for the CAGH app.
///
/// Replaces the many hardcoded `Color(0x...)` literals scattered across the UI
/// so the brand palette is defined in one place.
class AppColors {
  // Brand
  static const Color primaryGreen = Color(0xFF315E26);
  static const Color primaryGreenDark = Color(0xFF2E5B2E);
  static const Color accentYellow = Color(0xFFFFD22B);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentPurpleDark = Color(0xFF5B4075);
  static const Color purple = Color(0xFF6B4B9A);
  static const Color purpleLight = Color(0xFFB39DDB);

  // Greens / mint
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color lightGreenAlt = Color(0xFFF1F8E9);
  static const Color mint = Color(0xFFA5D6A7);
  static const Color mintLight = Color(0xFFC8E6C9);

  // Creams / backgrounds
  static const Color cream = Color(0xFFFFF8E1);
  static const Color creamAlt = Color(0xFFFFF5E6);
  static const Color backgroundOffWhite = Color(0xFFF8F8F4);
  static const Color backgroundPinkGray = Color(0xFFF9FAF8);
  static const Color backgroundMintWhite = Color(0xFFF7FBF5);
  static const Color backgroundPale = Color(0xFFF8FAF7);
  static const Color backgroundTealWhite = Color(0xFFF1F4EE);
  static const Color backgroundSoftPink = Color(0xFFFFEBEE);

  // Text / neutral
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textDarkAlt = Color(0xFF121212);
  static const Color textNearBlack = Color(0xFF1E1E1E);
  static const Color textGray = Color(0xFF333333);
  static const Color textGrayDark = Color(0xFF2C2C2C);
  static const Color textBrown = Color(0xFF4A2A2A);

  // Error / red
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color errorRedBright = Color(0xFFE53935);
  static const Color errorRedDark = Color(0xFFC62828);
  static const Color errorRedDeep = Color(0xFFB71C1C);
  static const Color errorRedMaroon = Color(0xFF900000);

  // Extended green shades
  static const Color primaryGreenDarker = Color(0xFF1B3E19);
  static const Color primaryGreenDarkest = Color(0xFF0C210A);
  static const Color accentGreenDark = Color(0xFF2E7D32);
  static const Color darkGreen = Color(0xFF33691E);
  static const Color gradientGreenStart = Color(0xFF3B6B2B);
  static const Color gradientGreenEnd = Color(0xFF4C7B38);
  static const Color buttonGreen = Color(0xFF4C7B41);
  static const Color lightGreenAccent = Color(0xFF81C784);
  static const Color lightGreenBorder = Color(0xFFDCEDC8);

  // Yellow / orange / brown accents
  static const Color accentYellowBright = Color(0xFFFFCC02);
  static const Color deepOrange = Color(0xFFE65100);
  static const Color brownText = Color(0xFF795548);

  // Neutral backgrounds / borders
  static const Color backgroundGrayWhite = Color(0xFFF9F9F9);
  static const Color backgroundLightGray = Color(0xFFF5F5F5);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color dividerGray = Color(0xFFEEEEEE);
  static const Color backgroundMintGray = Color(0xFFF4F6F4);
  static const Color backgroundSoftGreen = Color(0xFFEAEFE9);
  static const Color backgroundPaleGreen = Color(0xFFF7F9F4);
  static const Color backgroundMintWhiteAlt = Color(0xFFF4F8F3);
  static const Color backgroundPaleMint = Color(0xFFF9FBF6);
  static const Color backgroundSoftMint = Color(0xFFF8FBF7);
  static const Color backgroundMintGray2 = Color(0xFFF4F6ED);
  static const Color backgroundMintGray3 = Color(0xFFF1F6EE);
  static const Color backgroundWarmWhite = Color(0xFFFAF9F6);
  static const Color backgroundCreamWhite = Color(0xFFFCF9F6);
  static const Color borderGrayLight = Color(0xFFEFEFEF);
  static const Color borderGreenGray = Color(0xFFD6E3D6);
  static const Color backgroundSoftRed = Color(0xFFFFF0F0);
  static const Color borderRedLight = Color(0xFFFFCDD2);
  static const Color borderRedSoft = Color(0xFFF4C7C7);
  static const Color backgroundPinkWhite = Color(0xFFFFF7F7);
  static const Color accentPeach = Color(0xFFFFF0E0);
  static const Color infoBlueBg = Color(0xFFE1F5FE);
  static const Color infoBlue = Color(0xFF0288D1);
  static const Color accentPurpleBg = Color(0xFFF3E5F5);
  static const Color accentPurpleStrong = Color(0xFF7B1FA2);
  static const Color textNearBlackAlt = Color(0xFF222222);

  // Additional tints / dark-mode variants
  static const Color backgroundSoftMintAlt = Color(0xFFF9FBF7);
  static const Color borderGreenGrayLight = Color(0xFFE5E9DF);
  static const Color darkPurple = Color(0xFF2C2533);
  static const Color backgroundCreamYellow = Color(0xFFFDF7E7);
  static const Color darkRed = Color(0xFF331E1E);
  static const Color backgroundRedWhite = Color(0xFFFFF4F4);
  static const Color borderRedPale = Color(0xFFFFEAEA);
  static const Color errorRedLight = Color(0xFFE57373);
  static const Color errorRedDeepAlt = Color(0xFFA12C2C);
  static const Color backgroundRedPale = Color(0xFFFFE5E5);
  static const Color brandPurple = Color(0xFF7C5B8B);
  static const Color backgroundGrayLight = Color(0xFFF8F8F8);
  static const Color accentOrange = Color(0xFFF57C00);
  static const Color accentBlue = Color(0xFF1976D2);
  static const Color frostedMint = Color(0xF5F6F9F4);
  static const Color sageGrey = Color(0xFF4E574B);

  // Hex-string variants for APIs that require a color as a string (e.g. CallKit).
  static const String primaryGreenHex = '#315E26';
  static const String accentYellowHex = '#FFD22B';
  static const String accentGreenHex = '#4CAF50';

  // Intentional Dark Mode Tokens (Botanical Slate & Soothing Emerald)
  static const Color darkBackground = Color(0xFF0F1712);
  static const Color darkSurface = Color(0xFF18221B);
  static const Color darkSurfaceVariant = Color(0xFF222F26);
  static const Color darkBorder = Color(0xFF2C3E32);
  static const Color darkPrimary = Color(0xFF52B75A);
  static const Color darkButtonGreen = Color(0xFF2E5E2A);
  static const Color darkTextPrimary = Color(0xFFF0F5F1);
  static const Color darkTextSecondary = Color(0xFF9EB1A3);
  static const Color darkAccentYellow = Color(0xFFFFD54F);
  static const Color darkAccentPurple = Color(0xFFC594E8);
  static const Color darkPurpleSurface = Color(0xFF2D2338);

  // High-contrast text gold token for light backgrounds
  static const Color textGold = Color(0xFFB78103);
}

