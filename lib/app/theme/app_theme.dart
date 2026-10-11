import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  static const bgTop = Color(0xFF1B0F45);
  static const bgMid = Color(0xFF3A1A72);
  static const bgBottom = Color(0xFF0B3E5C);
  static const gold = Color(0xFFFFD166);
  static const orange = Color(0xFFFF8A3D);
  static const pink = Color(0xFFFF5E8A);
  static const violet = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF22D3EE);
  static const green = Color(0xFF34D399);
  static const red = Color(0xFFF87171);
  static const ink = Color(0xFF2B1460);
  static const glass = Color(0x1FFFFFFF);
  static const glassBorder = Color(0x33FFFFFF);
}

abstract class AppGradients {
  static const gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE29A), AppColors.gold, AppColors.orange],
  );
  static const hot = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.pink, AppColors.orange],
  );
  static const cool = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.violet, AppColors.cyan],
  );
  static const success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6EE7B7), Color(0xFF10B981)],
  );
  static const danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)],
  );
  static const tile = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, Color(0xFFE9E2FF)],
  );
}

abstract class AppText {
  static TextStyle display(double size,
          {Color color = Colors.white, FontWeight weight = FontWeight.w700, double spacing = 0}) =>
      GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing);

  static TextStyle body(double size,
          {Color color = Colors.white, FontWeight weight = FontWeight.w500, double spacing = 0}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing);
}

abstract class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgTop,
        colorScheme: const ColorScheme.dark(primary: AppColors.gold, secondary: AppColors.pink),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        splashFactory: InkSparkle.splashFactory,
      );
}
