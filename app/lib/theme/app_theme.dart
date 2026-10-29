import 'package:flutter/material.dart';

/// 앱의 모든 색은 여기서만 정의한다 (기획서 4번). 포인트 색은 임시값.
class AppColors {
  static const primary = Color(0xFF0E9F8E);
  static const primaryDark = Color(0xFF0A7A6D);
  static const primarySoft = Color(0xFFE3F5F2);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F7F6);
  static const text = Color(0xFF14211F);
  static const textSub = Color(0xFF5B6B68);
  static const line = Color(0xFFE4EAE8);
  static const warning = Color(0xFFD9534F);

  /// 경고 상자 배경
  static const warningSoft = Color(0xFFFCECEB);

  /// 웹 미리보기에서 폰 화면 바깥 배경
  static const pageBackground = Color(0xFFE9EEED);

  /// 운동한 날 달력의 불꽃 색
  static const streakFire = Color(0xFFFF7A45);

  /// 동작 그림의 팔다리 색 (배경은 primaryDark)
  static const figureLimb = Color(0xFFA7DCD3);

  static const kakao = Color(0xFFFEE500);
  static const kakaoText = Color(0xFF191600);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.background,
      error: AppColors.warning,
    );
    final roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.line),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: AppColors.text),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: roundedBorder,
        enabledBorder: roundedBorder,
        focusedBorder: roundedBorder.copyWith(
            borderSide: const BorderSide(color: AppColors.primary)),
        labelStyle: const TextStyle(color: AppColors.textSub),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, color: AppColors.text)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
      ),
      // 아래에서 올라오는 창의 배경색은 여기서만 정한다 (디자인 리뷰 10/28 #4)
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.background),
      dividerColor: AppColors.line,
    );
  }
}
