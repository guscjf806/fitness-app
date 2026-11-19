/// PT 수업 예약 연습용 화면: 회원 신청(S24). 선생님 화면은 pt_schedule.dart (docs/PT예약_설계.md, 디자인 리뷰 11/18 #7)
/// 데이터는 폰 메모리에만 있다. 서버 저장은 약관 검토 뒤에 만든다
library;

import 'package:flutter/material.dart';

import '../config.dart';
import '../logic/pt_booking.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pt_slot.dart';

export 'pt_schedule.dart';

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
      final undo = demo.ptUndo(b);
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
    final days = ptBookingDays(now);
    final mine = demo.ptBookings.where((b) => b.member == me).toList()..sort((a, b) => a.start.compareTo(b.start));
    final upcoming = [for (final b in mine) if (ptHoldsSlot(ptStatusAt(b, now))) b];
    final past = [for (final b in mine.reversed) if (!ptHoldsSlot(ptStatusAt(b, now))) b].take(3).toList();
    final opened = [
      for (final h in AppConfig.ptLessonHours)
        if (demo.ptOpenSlots.contains(days[day].add(Duration(hours: h)))) days[day].add(Duration(hours: h)),
    ];
    final slots = [for (final s in opened) if (s.isAfter(now)) s];
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
      DayChips(labels: ptDayChipLabels(days), selected: day, today: 0, onSelect: (i) => setState(() => day = i)),
      // 열린 시간이 다 지나서 빈 날과, 처음부터 안 연 날을 나눠 알린다 (디자인 리뷰 11/19 #1)
      if (slots.isEmpty && opened.isNotEmpty)
        const SlotEmpty.passed()
      else if (slots.isEmpty)
        const SlotEmpty('이날은 선생님이 수업 시간을 열지 않았어요. 다른 날을 골라 주세요.')
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
      time: ptHourText(start),
      label: label,
      tone: mine ? SlotTone.filled : (taken != null ? SlotTone.taken : SlotTone.open),
      selected: mine,
      onTap: taken == null ? onRequest : null,
    );
  }
}
