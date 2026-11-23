/// PT 수업 일정 연습용 화면: 선생님 승인·거절, 지난 수업 처리, 수업 시간 열기(S25) (docs/PT예약_설계.md)
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../logic/pt_booking.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pt_slot.dart';
import 'pt_cancel_sheet.dart';

/// S25 수업 일정 (선생님): 답을 기다리는 신청 승인·거절, 지난 수업 처리, 수업 시간 열고 닫기
class PtScheduleScreen extends StatefulWidget {
  const PtScheduleScreen({super.key, this.embedded = false});

  /// 탭 안에 넣을 때는 제목·뒤로가기 없이 내용만 (PT 탭 나누기, 결정 A)
  final bool embedded;

  @override
  State<PtScheduleScreen> createState() => _PtScheduleScreenState();
}

class _PtScheduleScreenState extends State<PtScheduleScreen> {
  int day = 0;

  /// 열어 둔 동안에도 '○시간 안에 답하지 않으면'과 자동 거절이 줄어들게 1분마다 다시 그린다 (리뷰 11/22 #6)
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _answer(PtBooking b, bool approve) {
    final undo = demo.ptUndo(b);
    demo.update(() {
      b.status = approve ? PtStatus.approved : PtStatus.rejected;
      // 시간 바꾸기를 승인하면 원래 예약은 자동으로 취소 (차감 없음). 거절하면 원래 예약이 그대로 (결정 d1122-2)
      if (approve && b.replaces != null && ptHoldsSlot(b.replaces!.status)) b.replaces!.status = PtStatus.cancelled;
    });
    toast(context, '${b.member} 님 ${ptWhen(b.start)} 신청을 ${approve ? '승인' : '거절'}했어요. 회원에게 알려 드려요',
        actionLabel: '되돌리기', onAction: undo);
  }

  /// 지난 수업: 했으면 1회 차감, 안 왔으면 1회 차감 (결정 d1117-pt3)
  void _finish(PtBooking b, PtStatus result) {
    final undo = demo.ptUndo(b);
    demo.update(() {
      b.status = result;
      // 0 아래로는 내려가지 않게 (리뷰 11/22 #1)
      demo.ptLeft[b.member] = ((demo.ptLeft[b.member] ?? 0) - 1).clamp(0, 999);
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
    final b = demo.ptBookingAt(start, now);
    if (b != null) {
      _showBooking(b, now);
      return;
    }
    demo.update(() => demo.ptOpenSlots.contains(start) ? demo.ptOpenSlots.remove(start) : demo.ptOpenSlots.add(start));
  }

  /// 신청·예약이 있는 칸을 누르면 닫는 대신 그 내용을 보여 준다. 신청이면 바로 답할 수 있게 (리뷰 11/22 #3)
  /// 확정된 수업은 선생님이 취소할 수 있다 (결정 d1122-1)
  Future<void> _showBooking(PtBooking b, DateTime now) async {
    final requested = ptStatusAt(b, now) == PtStatus.requested;
    final picked = await showAppSheet<String>(
      context,
      builder: (sheet) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SheetTitle('${b.member} 님 · ${ptWhen(b.start)}'),
        Muted(
          requested
              ? (b.replaces != null
                  ? '시간 바꾸기 신청이에요. 승인하면 원래 예약(${ptWhen(b.replaces!.start)})은 자동으로 취소돼요.'
                  : b.urgent
                      ? '곧 시작하는 급한 신청이에요. 승인하거나 거절해 주세요.'
                      : '답을 기다리는 신청이에요. 승인하거나 거절해 주세요.')
              // '닫기' 버튼과 헷갈리지 않게 시간 칸 이야기는 '취소'로 (디자인 리뷰 11/23 #4)
              : '확정된 수업이에요. 수업이 끝나면 지난 수업 처리에서 기록해요. 이 시간을 닫으려면 먼저 수업을 취소해 주세요.',
          top: AppSpace.xs,
        ),
        if (requested)
          ButtonPair(
            left: AppButton('승인', onPressed: () => Navigator.pop(sheet, 'approve')),
            right: AppButton('거절', kind: ButtonKind.quiet, onPressed: () => Navigator.pop(sheet, 'reject')),
          )
        else ...[
          AppButton('확인', kind: ButtonKind.soft, onPressed: () => Navigator.pop(sheet)),
          // 아프거나 일이 생기면 앱에서 바로 취소하고 회원에게 알린다. 차감 없음 (결정 d1122-1)
          Align(
            alignment: Alignment.centerRight,
            child: DangerTextButton('이 수업 취소하기', onPressed: () => Navigator.pop(sheet, 'cancel')),
          ),
        ],
      ]),
    );
    if (picked == null || !mounted) return;
    if (picked == 'cancel') {
      await _trainerCancel(b);
    } else {
      _answer(b, picked == 'approve');
    }
  }

  /// 선생님 쪽 수업 취소: 짧은 이유를 적고, 횟수는 줄지 않고, 회원에게 바로 알린다 (결정 d1122-1)
  Future<void> _trainerCancel(PtBooking b) async {
    final reason = await showAppSheet<String>(context, builder: (_) => TrainerCancelSheet(b));
    if (reason == null || !mounted) return;
    final undoBooking = demo.ptUndo(b);
    // 이 수업의 시간 바꾸기 신청은 원래 수업이 없어졌으니 보통 신청으로 남긴다 (리뷰 11/23 #4)
    final changes = [for (final c in demo.ptBookings) if (c.replaces == b && ptStatusAt(c, DateTime.now()) == PtStatus.requested) c];
    void undo() {
      undoBooking();
      demo.update(() {
        for (final c in changes) {
          c.replaces = b;
        }
      });
    }

    demo.update(() {
      b.status = PtStatus.trainerCancelled;
      b.cancelReason = reason;
      for (final c in changes) {
        c.replaces = null;
      }
    });
    toast(context, '${b.member} 님 ${ptWhen(b.start)} 수업을 취소하고 알렸어요. 횟수는 줄지 않아요', actionLabel: '되돌리기', onAction: undo);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = ptBookingDays(now);
    // 급한 신청을 맨 위로, 그다음 자동 거절이 가까운 순서
    final waiting = demo.ptWaitingAt(now)
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
    final children = <Widget>[
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
    ];
    return widget.embedded
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)
        : AppPage(title: '수업 일정', children: children);
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
        // 승인하면 원래 예약이 없어진다는 걸 알고 답하게 (결정 d1122-2)
        if (b.replaces != null) Muted('시간 바꾸기 신청 · 원래 ${ptWhen(b.replaces!.start)}', top: AppSpace.xxs, bottom: 0),
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
