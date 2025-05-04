
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Primary purple colors
const primaryColor = Color(0xFF8B5CF6); 
const primaryLightColor = Color(0xFFA78BFA);
const primaryDarkColor = Color(0xFF7C3AED);
const secondaryColor = Color(0xFF6D28D9);

final ColorScheme colorScheme = ColorScheme.light(
  primary: primaryColor,
  secondary: secondaryColor,
  surface: Colors.white,
  background: Colors.white,
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onSurface: Colors.black,
  onBackground: Colors.black,
  error: Colors.red.shade700,
  onError: Colors.white,
);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: colorScheme,
  scaffoldBackgroundColor: const Color(0xFFF9FAFB),
  fontFamily: GoogleFonts.inter().fontFamily,
  
  appBarTheme: AppBarTheme(
    elevation: 0.5,
    centerTitle: true,
    backgroundColor: Colors.white,
    titleTextStyle: TextStyle(
      fontFamily: GoogleFonts.inter().fontFamily,
      color: Colors.black,
      fontWeight: FontWeight.w600,
      fontSize: 18,
    ),
    iconTheme: const IconThemeData(color: Colors.black),
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: TextStyle(
        fontFamily: GoogleFonts.inter().fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      side: const BorderSide(color: primaryColor),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: TextStyle(
        fontFamily: GoogleFonts.inter().fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      textStyle: TextStyle(
        fontFamily: GoogleFonts.inter().fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.error),
    ),
    hintStyle: TextStyle(
      color: Colors.grey.shade500,
      fontSize: 15,
    ),
  ),
  
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
    shadowColor: Colors.black.withOpacity(0.1),
  ),
  
  dividerTheme: const DividerThemeData(
    color: Color(0xFFE5E7EB),
    thickness: 1,
    space: 1,
  ),
  
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: primaryColor,
    unselectedItemColor: Colors.grey,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    unselectedLabelStyle: TextStyle(fontSize: 12),
  ),
);
