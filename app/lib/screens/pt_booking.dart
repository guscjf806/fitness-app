/// PT 수업 예약 연습용 화면. 회원 신청(S24), 선생님 일정·승인(S25) (docs/PT예약_설계.md)
/// 데이터는 폰 메모리에만 있다. 서버 저장은 약관 검토 뒤에 만든다
library;

import 'package:flutter/material.dart';

import '../config.dart';
import '../data/mock_data.dart';
import '../logic/pt_booking.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pt_slot.dart';

/// 오늘부터 신청할 수 있는 날들
List<DateTime> _bookingDays(DateTime now) =>
    [for (var d = 0; d < AppConfig.ptBookingDays; d++) ptDay(now).add(Duration(days: d))];

/// 날짜 칩 글: 위는 요일, 아래는 날짜
List<String> _dayChipLabels(List<DateTime> days) => [for (final d in days) '${dayLabels[d.weekday - 1]} ${d.day}일'];

/// 잘못 눌렀을 때 바로 앞 상태(상태·차감·남은 횟수)로 되돌리는 함수. 알림 띠의 '되돌리기'에 쓴다 (디자인 리뷰 11/18 #2)
VoidCallback _undoOf(PtBooking b) {
  final status = b.status;
  final waived = b.waived;
  final left = demo.ptLeft[b.member];
  return () => demo.update(() {
        b.status = status;
        b.waived = waived;
        if (left != null) demo.ptLeft[b.member] = left;
      });
}

String _hourText(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:00';

/// S24 수업 예약 (PT 회원)
class PtBookingScreen extends StatefulWidget {
  const PtBookingScreen({super.key});

  @override
  State<PtBookingScreen> createState() => _PtBookingScreenState();
}

class _PtBookingScreenState extends State<PtBookingScreen> {
  int day = 0;

  String get me => demo.memberName;

  Future<void> _request(DateTime start) async {
    final now = DateTime.now();
    // 하루 1회까지 (결정 d1117-pt4)
    final sameDay = demo.ptBookings.any((b) => b.member == me && ptDay(b.start) == ptDay(start) && ptHoldsSlot(ptStatusAt(b, now)));
    if (sameDay) {
      toast(context, '하루에 한 번만 신청할 수 있어요. 이미 신청한 날이에요');
      return;
    }
    final urgent = start.difference(now) < const Duration(hours: AppConfig.ptAutoRejectHours);
    final ok = await confirmDialog(
      context,
      title: '${ptWhen(start)} 수업을 신청할까요?',
      body: urgent
          ? '곧 시작하는 수업이라 선생님께 바로 알려 드려요. 선생님이 승인하면 예약이 확정돼요.'
          : '선생님이 승인하면 예약이 확정돼요. ${AppConfig.ptAutoRejectHours}시간 안에 답이 없으면 자동으로 취소돼요.',
      keepLabel: '그만두기',
      okLabel: '신청하기',
    );
    if (!ok || !mounted) return;
    demo.update(() => demo.ptBookings.add(PtBooking(member: me, start: start, requestedAt: DateTime.now())));
    toast(context, '신청했어요. 선생님이 답하면 알려 드릴게요');
  }

  Future<void> _cancel(PtBooking b) async {
    final now = DateTime.now();
    final status = ptStatusAt(b, now);
    if (status == PtStatus.requested) {
      final undo = _undoOf(b);
      demo.update(() => b.status = PtStatus.cancelled);
      toast(context, '신청을 취소했어요', actionLabel: '되돌리기', onAction: undo);
      return;
    }
    // 24시간 전까지는 무료, 지나면 1회 차감 (결정 d1117-pt2·pt3)
    final free = ptFreeCancel(b, now);
    final ok = await confirmDialog(
      context,
      title: '${ptWhen(b.start)} 수업을 취소할까요?',
      body: free
          ? '수업 ${AppConfig.ptFreeCancelHours}시간 전이라 횟수는 줄지 않아요.'
          : '수업 ${AppConfig.ptFreeCancelHours}시간 전이 지나서 PT 1회가 차감돼요. 사정이 있으면 선생님께 말씀해 주세요.',
      keepLabel: '그대로 두기',
      okLabel: free ? '취소하기' : '1회 차감하고 취소',
      danger: !free,
    );
    if (!ok || !mounted) return;
    demo.update(() {
      b.status = free ? PtStatus.cancelled : PtStatus.lateCancelled;
      if (!free) demo.ptLeft[me] = (demo.ptLeft[me] ?? 0) - 1;
    });
    toast(context, free ? '수업을 취소했어요' : '수업을 취소했어요. PT 1회가 차감됐어요');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = _bookingDays(now);
    final mine = demo.ptBookings.where((b) => b.member == me).toList()..sort((a, b) => a.start.compareTo(b.start));
    final upcoming = [for (final b in mine) if (ptHoldsSlot(ptStatusAt(b, now))) b];
    final past = [for (final b in mine.reversed) if (!ptHoldsSlot(ptStatusAt(b, now))) b].take(3).toList();
    final slots = [
      for (final h in AppConfig.ptLessonHours)
        if (demo.ptOpenSlots.contains(days[day].add(Duration(hours: h))) && days[day].add(Duration(hours: h)).isAfter(now))
          days[day].add(Duration(hours: h)),
    ];
    return AppPage(title: '수업 예약', children: [
      LineRow(
        left: const Text('남은 PT', style: AppText.bodyStrong),
        right: Text('${demo.ptLeft[me] ?? 0}회', style: AppText.bodyStrong.copyWith(color: AppColors.primaryDark)),
      ),
      const H2('내 예약'),
      if (upcoming.isEmpty) const Muted('잡힌 수업이 없어요. 아래에서 시간을 골라 신청해 보세요.'),
      for (final b in upcoming) _MyBookingCard(b, now: now, onCancel: () => _cancel(b)),
      const H2('시간 고르기'),
      Muted('${AppConfig.ptBookingDays ~/ 7}주 앞까지, 하루 한 번 신청할 수 있어요.'),
      DayChips(labels: _dayChipLabels(days), selected: day, today: 0, onSelect: (i) => setState(() => day = i)),
      if (slots.isEmpty)
        const AppCard(child: WordText('이날은 선생님이 수업 시간을 열지 않았어요. 다른 날을 골라 주세요.'))
      else
        SlotGrid(children: [
          for (final s in slots) _MemberSlot(start: s, now: now, me: me, onRequest: () => _request(s)),
        ]),
      const SizedBox(height: AppSpace.l),
      const SlotLegend([(SlotTone.open, '신청 가능'), (SlotTone.taken, '마감'), (SlotTone.filled, '내 신청·예약')]),
      if (past.isNotEmpty) ...[
        const H2('지난 신청'),
        for (final b in past)
          LineRow(
            left: WordText(ptWhen(b.start)),
            right: Muted(ptStatusLabel(ptStatusAt(b, now), waived: b.waived), bottom: 0),
          ),
      ],
      const SizedBox(height: AppSpace.l),
      Muted('수업 ${AppConfig.ptFreeCancelHours}시간 전까지는 무료로 취소할 수 있어요. 그 뒤에 취소하거나 오지 않으면 PT 1회가 차감돼요. '
          '사정이 있으면 선생님이 차감을 빼 줄 수 있어요.'),
    ]);
  }
}

class _MyBookingCard extends StatelessWidget {
  const _MyBookingCard(this.b, {required this.now, required this.onCancel});
  final PtBooking b;
  final DateTime now;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final status = ptStatusAt(b, now);
    final left = b.answerBy.difference(now);
    return AppCard(
      accent: status == PtStatus.approved,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WordText(ptWhen(b.start), style: AppText.bodyStrong),
        Text(ptStatusLabel(status), style: status == PtStatus.approved ? AppText.captionAccent : AppText.caption),
        if (status == PtStatus.requested && !b.urgent)
          Muted('${ptLeftText(left)} 안에 답이 없으면 자동으로 취소돼요', top: AppSpace.xxs, bottom: 0),
        Align(
          alignment: Alignment.centerRight,
          // 차감될 수 있는 수업 취소는 다른 화면의 지우기·빼기처럼 경고색 (디자인 리뷰 11/18 #6)
          child: status == PtStatus.requested
              ? TextButton(onPressed: onCancel, child: const Text('신청 취소'))
              : DangerTextButton('수업 취소', onPressed: onCancel),
        ),
      ]),
    );
  }
}

/// 회원이 보는 시간 칸: 신청 가능(연한 초록) · 마감(회색) · 내 신청(진한 초록 + 체크)
class _MemberSlot extends StatelessWidget {
  const _MemberSlot({required this.start, required this.now, required this.me, required this.onRequest});
  final DateTime start;
  final DateTime now;
  final String me;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final taken = demo.ptBookingAt(start, now);
    final mine = taken?.member == me;
    final label = mine ? '내 신청' : (taken != null ? '마감' : '신청 가능');
    return TimeSlotButton(
      time: _hourText(start),
      label: label,
      tone: mine ? SlotTone.filled : (taken != null ? SlotTone.taken : SlotTone.open),
      selected: mine,
      onTap: taken == null ? onRequest : null,
    );
  }
}

/// S25 수업 일정 (선생님): 답을 기다리는 신청 승인·거절, 지난 수업 처리, 수업 시간 열고 닫기
class PtScheduleScreen extends StatefulWidget {
  const PtScheduleScreen({super.key});

  @override
  State<PtScheduleScreen> createState() => _PtScheduleScreenState();
}

class _PtScheduleScreenState extends State<PtScheduleScreen> {
  int day = 0;

  void _answer(PtBooking b, bool approve) {
    final undo = _undoOf(b);
    demo.update(() => b.status = approve ? PtStatus.approved : PtStatus.rejected);
    toast(context, '${b.member} 님 ${ptWhen(b.start)} 신청을 ${approve ? '승인' : '거절'}했어요. 회원에게 알려 드려요',
        actionLabel: '되돌리기', onAction: undo);
  }

  /// 지난 수업: 했으면 1회 차감, 안 왔으면 1회 차감 (결정 d1117-pt3)
  void _finish(PtBooking b, PtStatus result) {
    final undo = _undoOf(b);
    demo.update(() {
      b.status = result;
      demo.ptLeft[b.member] = (demo.ptLeft[b.member] ?? 0) - 1;
    });
    toast(context, result == PtStatus.done ? '${b.member} 님 수업을 기록했어요. PT 1회가 차감됐어요' : '${b.member} 님이 오지 않은 것으로 기록했어요. PT 1회가 차감됐어요',
        actionLabel: '되돌리기', onAction: undo);
  }

  /// 사정이 있으면 차감을 되돌린다 (결정 d1117-pt3)
  void _waive(PtBooking b) {
    demo.update(() {
      b.waived = true;
      demo.ptLeft[b.member] = (demo.ptLeft[b.member] ?? 0) + 1;
    });
    toast(context, '${b.member} 님 차감을 이번만 빼 줬어요');
  }

  void _toggle(DateTime start, DateTime now) {
    if (demo.ptBookingAt(start, now) != null) {
      toast(context, '신청이나 예약이 있는 시간은 닫을 수 없어요');
      return;
    }
    demo.update(() => demo.ptOpenSlots.contains(start) ? demo.ptOpenSlots.remove(start) : demo.ptOpenSlots.add(start));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = _bookingDays(now);
    // 급한 신청을 맨 위로, 그다음 자동 거절이 가까운 순서
    final waiting = [for (final b in demo.ptBookings) if (ptStatusAt(b, now) == PtStatus.requested) b]
      ..sort((a, b) => a.urgent != b.urgent ? (a.urgent ? -1 : 1) : a.answerBy.compareTo(b.answerBy));
    final toFinish = [
      for (final b in demo.ptBookings)
        if (b.status == PtStatus.approved && !b.start.isAfter(now)) b
    ];
    final toWaive = [
      for (final b in demo.ptBookings)
        if (!b.waived && (b.status == PtStatus.lateCancelled || b.status == PtStatus.noShow)) b
    ];
    return AppPage(title: '수업 일정', children: [
      const H2('답을 기다리는 신청'),
      if (waiting.isEmpty) const Muted('답할 신청이 없어요.'),
      for (final b in waiting) _RequestCard(b, now: now, onAnswer: (ok) => _answer(b, ok)),
      if (toFinish.isNotEmpty || toWaive.isNotEmpty) ...[
        const H2('지난 수업 처리'),
        for (final b in toFinish)
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              WordText('${b.member} · ${ptWhen(b.start)}', style: AppText.bodyStrong),
              const Muted('수업을 했는지 기록해 주세요. 어느 쪽이든 PT 1회가 차감돼요.', bottom: 0),
              ButtonPair(
                left: AppButton('수업 했어요', onPressed: () => _finish(b, PtStatus.done)),
                right: AppButton('안 왔어요', kind: ButtonKind.quiet, onPressed: () => _finish(b, PtStatus.noShow)),
              ),
            ]),
          ),
        for (final b in toWaive)
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              WordText('${b.member} · ${ptWhen(b.start)}', style: AppText.bodyStrong),
              Text(ptStatusLabel(b.status), style: AppText.captionCaution),
              AppButton('이번만 빼 주기', kind: ButtonKind.soft, onPressed: () => _waive(b)),
            ]),
          ),
      ],
      const H2('수업 시간 열기'),
      const Muted('눌러서 회원이 신청할 수 있는 시간을 열고 닫아요.'),
      DayChips(labels: _dayChipLabels(days), selected: day, today: 0, onSelect: (i) => setState(() => day = i)),
      SlotGrid(children: [
        for (final h in AppConfig.ptLessonHours)
          if (days[day].add(Duration(hours: h)).isAfter(now))
            _TrainerSlot(start: days[day].add(Duration(hours: h)), now: now, onTap: () => _toggle(days[day].add(Duration(hours: h)), now)),
      ]),
      const SizedBox(height: AppSpace.m),
      const SlotLegend([(SlotTone.closed, '닫힘'), (SlotTone.open, '열림'), (SlotTone.filled, '회원 신청·예약')]),
    ]);
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard(this.b, {required this.now, required this.onAnswer});
  final PtBooking b;
  final DateTime now;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final left = b.answerBy.difference(now);
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 수업이 곧이라 먼저 봐야 하는 신청 (사용자 결정 2026-11-17)
        if (b.urgent) const Text('급한 신청 · 곧 시작하는 수업', style: AppText.captionCaution),
        WordText('${b.member} · ${ptWhen(b.start)}', style: AppText.bodyStrong),
        Muted(
          b.urgent
              ? '수업 시간이 지나도록 답하지 않으면 지난 신청으로 정리돼요'
              : '${ptLeftText(left)} 안에 답하지 않으면 자동으로 거절돼요',
          top: AppSpace.xxs,
          bottom: 0,
        ),
        ButtonPair(
          left: AppButton('승인', onPressed: () => onAnswer(true)),
          right: AppButton('거절', kind: ButtonKind.quiet, onPressed: () => onAnswer(false)),
        ),
      ]),
    );
  }
}

/// 선생님이 보는 시간 칸: 닫힘(점선) · 열림(연한 초록) · 신청·예약(회원 이름)
class _TrainerSlot extends StatelessWidget {
  const _TrainerSlot({required this.start, required this.now, required this.onTap});
  final DateTime start;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final open = demo.ptOpenSlots.contains(start);
    final b = demo.ptBookingAt(start, now);
    final label = b != null
        ? '${b.member} ${ptStatusAt(b, now) == PtStatus.approved ? '예약' : '신청'}'
        : (open ? '열림' : '닫힘');
    return TimeSlotButton(
      time: _hourText(start),
      label: label,
      tone: b != null ? SlotTone.filled : (open ? SlotTone.open : SlotTone.closed),
      onTap: onTap,
    );
  }
}
