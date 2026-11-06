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

  /// 경고 글씨. 흰 배경·경고 상자에서 글자가 잘 읽히는 진한 빨강. 아이콘과 테두리는 warning (디자인 리뷰 11/04 #3)
  static const warningText = Color(0xFFB3362F);

  /// 정보 표시의 주의(소음 큼 등). 빨강(위험)과 구분되는 주황 (결정 dd1101-infotag)
  static const caution = Color(0xFFC2410C);
  static const cautionSoft = Color(0xFFFFF1E8);

  /// 경고 상자 배경
  static const warningSoft = Color(0xFFFCECEB);

  /// 웹 미리보기에서 폰 화면 바깥 배경
  static const pageBackground = Color(0xFFE9EEED);

  /// 운동한 날 달력의 불꽃 색
  static const streakFire = Color(0xFFFF7A45);

  /// 진한 청록 위의 작은 불꽃 (달력 전용). 잘 보이게 밝은 색
  static const streakFireOnDark = Color(0xFFFFD9C2);

  /// 동작 그림의 팔다리 색 (배경은 primaryDark)
  static const figureLimb = Color(0xFFA7DCD3);

  /// 진행 막대·빈 점 배경
  static const track = Color(0xFFDBE6E3);

  /// 빈 체크 동그라미 테두리
  static const lineStrong = Color(0xFFCFD8D5);

  /// 흰 소셜 로그인 버튼 테두리와 글씨
  static const socialBorder = Color(0xFFD5DCDA);
  static const googleText = Color(0xFF222222);

  static const kakao = Color(0xFFFEE500);
  static const kakaoText = Color(0xFF191600);
}

/// 여백은 여기서만 정한다 (디자인 리뷰 11/02 #4). 화면 바깥 여백부터 옮기는 중
class AppSpace {
  /// 화면 왼쪽·오른쪽 바깥 여백
  static const double page = 18;

  /// 스크롤 맨 아래 여백
  static const double pageBottom = 28;

  /// 바텀시트 왼쪽·오른쪽 여백
  static const double sheet = 20;

  static const double xs = 4;
  static const double xsPlus = 6;
  static const double s = 8;
  static const double sPlus = 10;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
}

/// 모서리 둥글기는 여기서만 정한다 (디자인 리뷰 10/31 #5)
class AppRadius {
  /// 카드·큰 상자
  static const double card = 14;

  /// 버튼·경고 상자·세트 줄
  static const double box = 12;

  /// 입력칸·작은 칩·썸네일·진행 막대
  static const double small = 10;

  /// 확인 창·운동 진행의 동작 그림 (디자인 리뷰 11/01 #7)
  static const double medium = 16;

  /// 운동 상세의 큰 동작 그림
  static const double large = 20;
}

/// 글자 크기는 여기서만 정한다 (디자인 리뷰 10/29 #4, 10/31 #4)
class AppText {
  /// 앱 글꼴 (결정 dd1103-font). 글꼴을 직접 지정하는 곳은 이 값을 쓴다
  static const fontFamily = 'Pretendard';

  /// 데모 바·작은 안내처럼 가장 작은 글씨
  static const small = TextStyle(fontFamily: fontFamily, fontSize: 12);
  static const caption = TextStyle(fontFamily: fontFamily, fontSize: 13);
  static const body = TextStyle(fontFamily: fontFamily, fontSize: 14);
  static const bodyStrong = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w700);
  static const title = TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w700);
  static const number = TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w700);

  /// 큰 경고 상자 글씨
  static const warning = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700, height: 1.4);

  /// 화면 제목(H1), 운동 진행의 운동 이름
  static const h1 = TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);

  /// 큰 숫자(BigNumber)
  static const bigNumber = TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w700);

  /// 시작 화면의 큰 문구
  static const display = TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w700, height: 1.3);

  /// 휴식 타이머 숫자
  static const timer = TextStyle(fontFamily: fontFamily, fontSize: 38, fontWeight: FontWeight.w700);
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
      borderRadius: BorderRadius.circular(AppRadius.small),
      borderSide: const BorderSide(color: AppColors.line),
    );
    return ThemeData(
      useMaterial3: true,
      // 앱 글꼴은 여기서만 정한다 (결정 dd1103-font)
      fontFamily: AppText.fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: AppColors.text),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.title.copyWith(color: AppColors.text),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.box)),
          // 버튼 글자 모양을 직접 정하면 글꼴이 빠지니 함께 지정한다
          textStyle: const TextStyle(fontFamily: AppText.fontFamily, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      // 테두리 버튼·글자 버튼·확인 창도 여기서 한 번만 정한다 (디자인 리뷰 10/30 #4)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.box)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark, minimumSize: const Size(48, 48)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: roundedBorder,
        enabledBorder: roundedBorder,
        focusedBorder: roundedBorder.copyWith(
            borderSide: const BorderSide(color: AppColors.primary)),
        labelStyle: const TextStyle(color: AppColors.textSub),
        // 오류 글씨가 잘 읽히게, 좁은 칸에서도 잘리지 않게 (디자인 리뷰 11/05 #3)
        errorStyle: const TextStyle(color: AppColors.warningText),
        errorMaxLines: 3,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStateProperty.all(
            AppText.small.copyWith(color: AppColors.text)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
      ),
      // 아래에서 올라오는 창의 배경색은 여기서만 정한다 (디자인 리뷰 10/28 #4)
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.background),
      // 켜진 스위치 색은 여기서만 정한다 (디자인 리뷰 11/02 #2)
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : null),
      ),
      // 칩 모양은 여기서 정한다. 고르는 칩은 공용 SelectChip을 쓴다 (디자인 리뷰 11/05 #4)
      chipTheme: const ChipThemeData(selectedColor: AppColors.primarySoft, shape: StadiumBorder(), showCheckmark: false),
      dividerColor: AppColors.line,
    );
  }
}
