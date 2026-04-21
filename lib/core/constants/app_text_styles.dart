import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle heading1 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryText,
  );

  static TextStyle heading2 = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );

  static TextStyle heading3 = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );

  static TextStyle body = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: primaryText,
  );

  static TextStyle bodySecondary = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: secondaryText,
  );

  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: secondaryText,
  );

  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );

  static TextStyle orange = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: primary,
  );
}
