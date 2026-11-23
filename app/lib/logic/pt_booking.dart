import '../config.dart';
import '../data/mock_data.dart';

/// PT 예약 상태 (docs/PT예약_설계.md)
enum PtStatus {
  /// 회원이 신청하고 선생님 답을 기다리는 중
  requested,
  approved,
  rejected,

  /// 선생님이 5시간 안에 답하지 않아 자동 거절 (차감 없음)
  autoRejected,

  /// 급한 신청에 답이 없는 채 수업 시간이 지남. 알림 없이 정리 (차감 없음)
  expired,

  /// 마감 전 취소 (차감 없음)
  cancelled,

  /// 마감 뒤 취소 (1회 차감, 선생님이 빼 줄 수 있음)
  lateCancelled,

  /// 수업을 했음 (1회 차감)
  done,

  /// 안 옴 (1회 차감, 선생님이 빼 줄 수 있음)
  noShow,

  /// 선생님이 확정된 수업을 취소 (차감 없음, 회원에게 바로 알림, 짧은 이유) (결정 d1122-1)
  trainerCancelled,
}

/// 예약 한 건. 목업이라 폰 메모리에만 있다. 실제 표는 약관 검토 뒤에 만든다
class PtBooking {
  PtBooking({required this.member, required this.start, required this.requestedAt, this.status = PtStatus.requested, this.replaces});
  final String member;
  final DateTime start;
  final DateTime requestedAt;
  PtStatus status;

  /// 선생님이 '이번만 빼 주기'를 눌러 차감을 되돌렸는지
  bool waived = false;

  /// 선생님이 '차감 그대로 두기'를 눌러 처리를 끝냈는지. 지난 수업 처리 목록에서 빠진다 (리뷰 11/19 #4)
  bool settled = false;

  /// 선생님이 취소할 때 적은 짧은 이유 (결정 d1122-1)
  String? cancelReason;

  /// 시간 바꾸기 신청이면 원래 예약. 선생님이 승인하면 원래 예약이 자동으로 취소된다 (결정 d1122-2)
  /// 선생님이 원래 예약을 취소하면 끊겨서 보통 신청이 된다 (리뷰 11/23 #4)
  PtBooking? replaces;

  /// 수업까지 5시간이 안 남았을 때 들어온 신청. 선생님께 따로 알린다
  bool get urgent => start.difference(requestedAt) < const Duration(hours: AppConfig.ptAutoRejectHours);

  /// 자동 거절되는 시각
  DateTime get answerBy => requestedAt.add(const Duration(hours: AppConfig.ptAutoRejectHours));
}

/// 지금 시각으로 본 실제 상태. 답이 없으면 수업 시간이 먼저 지났는지(지난 신청), 5시간이 먼저 지났는지(자동 거절)로 나눈다
PtStatus ptStatusAt(PtBooking b, DateTime now) {
  if (b.status != PtStatus.requested) return b.status;
  if (!now.isBefore(b.start) && b.start.isBefore(b.answerBy)) return PtStatus.expired;
  if (!now.isBefore(b.answerBy)) return PtStatus.autoRejected;
  return PtStatus.requested;
}

/// 칸을 차지하고 있는 상태 (다른 회원이 신청할 수 없음)
bool ptHoldsSlot(PtStatus s) => s == PtStatus.requested || s == PtStatus.approved;

/// 무료로 취소할 수 있는지 (수업 24시간 전까지)
bool ptFreeCancel(PtBooking b, DateTime now) =>
    b.start.difference(now) >= const Duration(hours: AppConfig.ptFreeCancelHours);

/// 횟수를 차감한 상태인지. '이번만 빼 주기'를 누른 건 빼지 않는다
bool ptCharged(PtBooking b) =>
    !b.waived && (b.status == PtStatus.done || b.status == PtStatus.lateCancelled || b.status == PtStatus.noShow);

/// 회원에게 보여 줄 상태 글
String ptStatusLabel(PtStatus s, {bool waived = false}) => switch (s) {
      PtStatus.requested => '승인 기다리는 중',
      PtStatus.approved => '예약 확정',
      // 이유 대신 다음에 할 일을 고정 문구로 알린다 (결정 d1119-2)
      PtStatus.rejected => '거절됨 · 다른 시간을 신청해 주세요',
      PtStatus.autoRejected => '선생님이 답하지 않아 취소됨',
      PtStatus.expired => '지난 신청',
      PtStatus.cancelled => '취소함',
      PtStatus.lateCancelled => waived ? '늦은 취소 · 차감 안 함' : '늦은 취소 · 1회 차감',
      PtStatus.done => '수업 완료',
      PtStatus.noShow => waived ? '안 옴 · 차감 안 함' : '안 옴 · 1회 차감',
      PtStatus.trainerCancelled => '선생님이 취소함 · 차감 없음',
    };

/// 남은 시간을 쉬운 말로: '2시간 15분', 0이 들어가는 쪽은 뺀다('3시간', '40분'). 1분 안 남았으면 '1분' (디자인 리뷰 11/18 #4)
String ptLeftText(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h <= 0) return '${m < 1 ? 1 : m}분';
  return m == 0 ? '$h시간' : '$h시간 $m분';
}

/// 회원에게 보여 줄 상태 글. 시간이 지난 확정 수업은 선생님이 기록할 때까지 '확인 기다리는 중' (리뷰 11/19 #1)
String ptMemberLabel(PtBooking b, DateTime now) {
  final s = ptStatusAt(b, now);
  if (s == PtStatus.approved && !b.start.isAfter(now)) return '선생님 확인 기다리는 중';
  if (b.replaces case final from?) {
    if (s == PtStatus.requested) return '시간 바꾸기 · 승인 기다리는 중';
    // 바꾸기가 안 됐을 때 원래 수업까지 없어진 줄 알지 않게 결과를 풀어 쓴다 (리뷰 11/23 #3)
    final kept = from.status == PtStatus.approved ? ' · 원래 예약 그대로' : '';
    if (s == PtStatus.rejected) return '시간 바꾸기 거절$kept';
    if (s == PtStatus.autoRejected || s == PtStatus.expired) return '시간 바꾸기 답 없음$kept';
    if (s == PtStatus.cancelled) return '시간 바꾸기 신청 취소';
  }
  if (s == PtStatus.trainerCancelled && (b.cancelReason ?? '').isNotEmpty) return '${ptStatusLabel(s)} · ${b.cancelReason}';
  return ptStatusLabel(s, waived: b.waived);
}

/// 선생님 취소를 회원에게 알리는 한 줄: '11월 24일(화) 19:00 · 몸이 안 좋아요 · 횟수는 그대로예요' (리뷰 11/23 #1)
String ptTrainerCancelText(PtBooking b) =>
    [ptWhen(b.start), if ((b.cancelReason ?? '').isNotEmpty) b.cancelReason!, '횟수는 그대로예요'].join(' · ');

/// '11월 18일(화) 19:00'
String ptWhen(DateTime d) =>
    '${d.month}월 ${d.day}일(${dayLabels[d.weekday - 1]}) ${d.hour.toString().padLeft(2, '0')}:00';

/// 오늘 0시
DateTime ptDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// 목업 처음 데이터: 다른 회원 예약·신청, 내 예약 1건, 처리할 지난 수업
List<PtBooking> seedPtBookings(DateTime now, String me) {
  final today = ptDay(now);
  DateTime at(int day, int hour) => today.add(Duration(days: day, hours: hour));
  return [
    PtBooking(member: me, start: at(3, 19), requestedAt: now.subtract(const Duration(days: 1)), status: PtStatus.approved),
    PtBooking(member: '이도현', start: at(1, 19), requestedAt: now.subtract(const Duration(days: 2)), status: PtStatus.approved),
    PtBooking(member: '박서연', start: at(2, 18), requestedAt: now.subtract(const Duration(hours: 4))),
    // 수업까지 3시간도 안 남은 급한 신청
    PtBooking(member: '이도현', start: DateTime(now.year, now.month, now.day, now.hour + 3), requestedAt: now.subtract(const Duration(minutes: 20))),
    PtBooking(member: '박서연', start: at(-1, 18), requestedAt: now.subtract(const Duration(days: 3)), status: PtStatus.approved),
  ];
}

/// 오늘부터 신청할 수 있는 날들
List<DateTime> ptBookingDays(DateTime now) =>
    [for (var d = 0; d < AppConfig.ptBookingDays; d++) ptDay(now).add(Duration(days: d))];

/// 날짜 칩 글: 위는 요일, 아래는 날짜
List<String> ptDayChipLabels(List<DateTime> days) => [for (final d in days) '${dayLabels[d.weekday - 1]} ${d.day}일'];

/// '19:00'
String ptHourText(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:00';

/// PT가 끝났을 때 회원에게 보내는 알림 한 건
class PtNotice {
  const PtNotice(this.at, this.title, this.body, {this.toSubscribe = false});
  final DateTime at;
  final String title;
  final String body;

  /// 누르면 구독 화면으로 가는 알림인지. 아니면 운동일지(영상)로 간다 (디자인 리뷰 11/23 #6)
  final bool toSubscribe;
}

/// PT가 끝난 날 한 번 + 무료 이용이 끝나기 하루 전 한 번 (결정 d1121-1).
/// 서버를 붙이면 같은 시각에 푸시로 보낸다. 지금은 홈 카드로 보여 준다
List<PtNotice> ptEndNotices(DateTime finishedAt) {
  final freeUntil = finishedAt.add(const Duration(days: AppConfig.ptGraceDays));
  final videoUntil = finishedAt.add(const Duration(days: AppConfig.videoKeepDays));
  String md(DateTime d) => '${d.month}월 ${d.day}일';
  return [
    PtNotice(finishedAt, 'PT가 끝났어요',
        '${md(freeUntil)}까지 무료로 쓸 수 있어요. 수업 영상은 ${md(videoUntil)}에 사라지니 남기려면 미리 내 폰에 저장하세요.'),
    PtNotice(freeUntil.subtract(const Duration(days: 1)), '내일 무료 이용이 끝나요',
        '그 뒤에는 AI 기능을 한 달 ${AppConfig.freeMonthlyAiLimit}회까지 무료로 쓰고, 더 쓰려면 구독해요.',
        toSubscribe: true),
  ];
}
