import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF3778FF); // Professional blue
  static const Color accentColor = Color(0xFF47B881); // Soothing green
  static const Color warningColor = Color(0xFFF7B500); // Warning yellow
  static const Color dangerColor = Color(0xFFE7513B); // Alert red
  static const Color neutralColor = Color(0xFF475467); // Neutral gray

  // Light theme
  static ThemeData get lightTheme => ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: accentColor,
          error: dangerColor,
        ),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1D2939),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D2939),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: primaryColor,
          unselectedItemColor: neutralColor,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 8,
          selectedIconTheme: const IconThemeData(size: 24),
          unselectedIconTheme: const IconThemeData(size: 22),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.black.withOpacity(0.1),
          color: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge: TextStyle(color: Color(0xFF475467), fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFF475467)),
        ),
        dividerTheme: const DividerThemeData(
          thickness: 1,
          space: 32,
          color: Color(0xFFEAECF0),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: primaryColor,
          inactiveTrackColor: primaryColor.withOpacity(0.2),
          thumbColor: primaryColor,
          overlayColor: primaryColor.withOpacity(0.1),
          valueIndicatorColor: primaryColor,
          valueIndicatorTextStyle: const TextStyle(color: Colors.white),
        ),
      );
  // Dark theme
  static ThemeData get darkTheme => ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          secondary: accentColor.withOpacity(0.8),
          error: dangerColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.white,
          onSurface: Colors.white,
          onError: Colors.white,
          surface: const Color(0xFF252525),
        ),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF1A1A1A),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey[400],
          backgroundColor: const Color(0xFF1A1A1A),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[850],
          labelStyle: const TextStyle(color: Colors.grey),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: const Color(0xFF252525),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 24, color: Colors.white),
          titleMedium: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
          bodyLarge: TextStyle(color: Colors.grey, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.grey),
        ),
        dividerTheme: const DividerThemeData(
          thickness: 1,
          space: 32,
          color: Color(0xFF2A2A2A),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: primaryColor,
          inactiveTrackColor: primaryColor.withOpacity(0.2),
          thumbColor: primaryColor,
          overlayColor: primaryColor.withOpacity(0.1),
          valueIndicatorColor: primaryColor,
          valueIndicatorTextStyle: const TextStyle(color: Colors.white),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF2A2A2A),
          disabledColor: Colors.grey[800],
          selectedColor: primaryColor,
          secondarySelectedColor: primaryColor,
          labelStyle: const TextStyle(color: Colors.white),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          brightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white70,
        ),
      );
}
