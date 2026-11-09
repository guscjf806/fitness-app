/// 출시 직전에 바꿀 수 있는 값은 여기에만 둔다 (기획서 7번).
class AppConfig {
  /// 무료 회원의 월 AI 사용 횟수 (식단·운동 루틴 생성 + 식단 AI 답변). 초안 값
  static const freeMonthlyAiLimit = 5;

  /// 무료 횟수가 다시 채워지는 날: 매월 1일 (확정, 기획서 12번 B8)
  static DateTime nextQuotaReset(DateTime now) => DateTime(now.year, now.month + 1, 1);

  /// 무료 회원의 월 기록 지키기권(스트릭 프리즈) 횟수. 초안 값
  static const freeMonthlyFreezes = 1;

  /// 구독 예시 가격(원). 실제 가격은 출시 전에 정한다
  static const monthlyPrice = 9900;
  static const yearlyPrice = 79000;

  /// Supabase 연결 정보. 공개용 키라 앱에 넣어도 된다 (데이터는 RLS가 지킨다)
  static const supabaseUrl = 'https://feqxciztzgadnvamwakv.supabase.co';
  static const supabasePublishableKey = 'sb_publishable_XQscU0ZAjgeQup9hfgM7ZQ_syv2RkR1';

  /// 카카오 네이티브 앱 키. 앱 안에 들어가는 공개용 값이다 (REST API 키·클라이언트 시크릿과 다름, 결정 d1105-1)
  static const kakaoNativeAppKey = '61af430dbe6ecd7ebf85305f218afb13';

  /// 구글 iOS 클라이언트 ID. 앱 안에 들어가는 공개용 값이다 (결정 d1105-1)
  static const googleIosClientId = '886730617819-2ipfquhk4rn8ok7t4n6sfe1kov2r1geq.apps.googleusercontent.com';

  /// 소셜 로그인을 마치고 폰 앱으로 돌아오는 주소 (iOS Info.plist·안드로이드 매니페스트와 같아야 한다)
  static const loginRedirect = 'com.guscjf806.fitnessapp://login-callback';

  /// 'PT 문의하기'를 누르면 여는 카카오톡 채널 주소 (결정 d1104-5). 채널을 만들면 넣는다. 비어 있으면 준비 중 안내
  static const kakaoChannelUrl = '';

  /// 한 번에 고를 수 있는 운동 수
  static const maxExercisePick = 10;
}
