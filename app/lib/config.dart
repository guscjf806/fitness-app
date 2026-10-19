/// 출시 직전에 바꿀 수 있는 값은 여기에만 둔다 (기획서 7번).
class AppConfig {
  /// 무료 회원의 월 AI 사용 횟수 (식단·운동 루틴 생성 + 식단 AI 답변). 초안 값
  static const freeMonthlyAiLimit = 5;

  /// 무료 횟수가 다시 채워지는 날. 임시로 '매월 1일' (사용자 확정 대기)
  static DateTime nextQuotaReset(DateTime now) => DateTime(now.year, now.month + 1, 1);

  /// 무료 회원의 월 스트릭 프리즈 횟수. 초안 값
  static const freeMonthlyFreezes = 1;

  /// 한 번에 고를 수 있는 운동 수
  static const maxExercisePick = 10;
}
