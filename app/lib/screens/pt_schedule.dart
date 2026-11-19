/// PT 수업 일정 연습용 화면: 선생님 승인·거절, 지난 수업 처리, 수업 시간 열기(S25) (docs/PT예약_설계.md)
library;

import 'package:flutter/material.dart';

import '../config.dart';
import '../logic/pt_booking.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pt_slot.dart';

/// S25 수업 일정 (선생님): 답을 기다리는 신청 승인·거절, 지난 수업 처리, 수업 시간 열고 닫기
class PtScheduleScreen extends StatefulWidget {
  const PtScheduleScreen({super.key});

  @override
  State<PtScheduleScreen> createState() => _PtScheduleScreenState();
}

class _PtScheduleScreenState extends State<PtScheduleScreen> {
  int day = 0;

  void _answer(PtBooking b, bool approve) {
    final undo = demo.ptUndo(b);
    demo.update(() => b.status = approve ? PtStatus.approved : PtStatus.rejected);
    toast(context, '${b.member} 님 ${ptWhen(b.start)} 신청을 ${approve ? '승인' : '거절'}했어요. 회원에게 알려 드려요',
        actionLabel: '되돌리기', onAction: undo);
  }

  /// 지난 수업: 했으면 1회 차감, 안 왔으면 1회 차감 (결정 d1117-pt3)
  void _finish(PtBooking b, PtStatus result) {
    final undo = demo.ptUndo(b);
    demo.update(() {
      b.status = result;
      demo.ptLeft[b.member] = (demo.ptLeft[b.member] ?? 0) - 1;
    });
    toast(context, result == PtStatus.done ? '${b.member} 님 수업을 기록했어요. PT 1회가 차감됐어요' : '${b.member} 님이 오지 않은 것으로 기록했어요. PT 1회가 차감됐어요',
        actionLabel: '되돌리기', onAction: undo);
  }

  /// 사정이 있으면 차감을 되돌린다 (결정 d1117-pt3)
  void _waive(PtBooking b) {
    final undo = demo.ptUndo(b);
    demo.update(() {
      b.waived = true;
      demo.ptLeft[b.member] = (demo.ptLeft[b.member] ?? 0) + 1;
    });
    // 다른 처리처럼 잘못 눌렀을 때 되돌릴 수 있게 (디자인 리뷰 11/19 #2)
    toast(context, '${b.member} 님 차감을 이번만 빼 줬어요', actionLabel: '되돌리기', onAction: undo);
  }

  void _settle(PtBooking b) {
    final undo = demo.ptUndo(b);
    demo.update(() => b.settled = true);
    toast(context, '${b.member} 님 차감을 그대로 두었어요', actionLabel: '되돌리기', onAction: undo);
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
    final days = ptBookingDays(now);
    // 급한 신청을 맨 위로, 그다음 자동 거절이 가까운 순서
    final waiting = [for (final b in demo.ptBookings) if (ptStatusAt(b, now) == PtStatus.requested) b]
      ..sort((a, b) => a.urgent != b.urgent ? (a.urgent ? -1 : 1) : a.answerBy.compareTo(b.answerBy));
    final toFinish = [
      for (final b in demo.ptBookings)
        if (b.status == PtStatus.approved && !b.start.isAfter(now)) b
    ];
    final toWaive = [
      for (final b in demo.ptBookings)
        if (!b.waived && !b.settled && (b.status == PtStatus.lateCancelled || b.status == PtStatus.noShow)) b
    ];
    // 지나간 시각은 열고 닫을 수 없어 뺀다. 오늘 시간이 다 지나면 안내만 보인다 (디자인 리뷰 11/19 #1)
    final hours = [
      for (final h in AppConfig.ptLessonHours)
        if (days[day].add(Duration(hours: h)).isAfter(now)) days[day].add(Duration(hours: h)),
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
              WordText(ptStatusLabel(b.status), style: AppText.captionCaution),
              // 차감을 그대로 두면 목록에서 빼서 계속 쌓이지 않게 (리뷰 11/19 #4)
              ButtonPair(
                left: AppButton('이번만 빼 주기', kind: ButtonKind.soft, onPressed: () => _waive(b)),
                right: AppButton('차감 그대로 두기', kind: ButtonKind.quiet, onPressed: () => _settle(b)),
              ),
            ]),
          ),
      ],
      const H2('수업 시간 열기'),
      const Muted('눌러서 회원이 신청할 수 있는 시간을 열고 닫아요.'),
      DayChips(labels: ptDayChipLabels(days), selected: day, today: 0, onSelect: (i) => setState(() => day = i)),
      if (hours.isEmpty)
        const SlotEmpty.passed()
      else
        SlotGrid(children: [
          for (final s in hours) _TrainerSlot(start: s, now: now, onTap: () => _toggle(s, now)),
        ]),
      const SlotLegend([(SlotTone.closed, '닫힘'), (SlotTone.open, '열림'), (SlotTone.pending, '답할 신청'), (SlotTone.filled, '확정 예약')]),
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
        if (b.urgent) const WordText('급한 신청 · 곧 시작하는 수업', style: AppText.captionCaution),
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
        ? '${b.member} ${ptStatusAt(b, now) == PtStatus.approved ? '예약' : '대기'}'
        : (open ? '열림' : '닫힘');
    return TimeSlotButton(
      time: ptHourText(start),
      label: label,
      // 답해야 할 신청은 주황으로 바로 눈에 띄게 (결정 d1118-1)
      tone: b == null
          ? (open ? SlotTone.open : SlotTone.closed)
          : (ptStatusAt(b, now) == PtStatus.approved ? SlotTone.filled : SlotTone.pending),
      onTap: onTap,
    );
  }
}
