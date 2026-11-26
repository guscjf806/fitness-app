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
import 'pt_booking_cards.dart';

export 'pt_schedule.dart';

/// 회원 신청의 종류: 보통 신청, 시간 바꾸기, 보강
enum _RequestKind { normal, change, makeup }

/// S24 수업 예약 (PT 회원)
class PtBookingScreen extends StatefulWidget {
  const PtBookingScreen({super.key, this.embedded = false});

  /// 탭 안에 넣을 때는 제목·뒤로가기 없이 내용만 (PT 탭 나누기, 결정 A)
  final bool embedded;

  @override
  State<PtBookingScreen> createState() => _PtBookingScreenState();
}

class _PtBookingScreenState extends State<PtBookingScreen> {
  int day = 0;

  /// [시간 바꾸기]를 누른 예약. 이때 고른 칸은 '바꾸기 신청'이 된다 (결정 d1122-2)
  PtBooking? changing;

  /// [시간 바꾸기]를 누르면 화면 밖의 안내 카드로 내려 준다 (디자인 리뷰 11/23 #3)
  final _changeGuide = GlobalKey();

  /// [보강 신청하기]를 누른 선생님 취소 수업. 이때 고른 칸은 '보강 신청'이 된다 (결정 d1123-1)
  PtBooking? makeup;

  void _startMakeup(PtBooking b) {
    setState(() {
      makeup = b;
      changing = null;
    });
    _scrollToGuide();
  }

  void _startChange(PtBooking b) {
    setState(() {
      changing = b;
      makeup = null;
    });
    _scrollToGuide();
  }

  void _scrollToGuide() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _changeGuide.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
    });
  }

  String get me => demo.memberName;

  Future<void> _request(DateTime start) async {
    final now = DateTime.now();
    // 하루 1회까지 (결정 d1117-pt4)
    final from = changing;
    final sameDay = demo.ptBookings
        .any((b) => b != from && b.member == me && ptDay(b.start) == ptDay(start) && ptHoldsSlot(ptStatusAt(b, now)));
    if (sameDay) {
      toast(context, '하루에 한 번만 신청할 수 있어요. 이미 신청한 날이에요');
      return;
    }
    // 남은 횟수가 잡아 둔 수업만큼 다 찼으면 신청을 막는다 (결정 d1119-1)
    final booked = demo.ptBookedOf(me, now);
    // 시간 바꾸기는 잡힌 수업을 옮기는 것이라 횟수를 더 쓰지 않는다
    if (from == null && (demo.ptLeft[me] ?? 0) - booked <= 0) {
      toast(context, '남은 PT가 없어요. 선생님께 재등록을 문의해 주세요');
      return;
    }
    final urgent = start.difference(now) < const Duration(hours: AppConfig.ptAutoRejectHours);
    // 무료 취소 기한이 이미 지난 칸이면 승인 뒤 취소가 차감된다는 걸 미리 알린다 (리뷰 11/19 #2)
    final late = start.difference(now) < const Duration(hours: AppConfig.ptFreeCancelHours);
    final forMakeup = makeup;
    // 신청 종류를 한 번 정하고 제목·안내·알림 띠 문구를 함께 고른다 (디자인 리뷰 11/24 #3)
    final kind = from != null ? _RequestKind.change : (forMakeup != null ? _RequestKind.makeup : _RequestKind.normal);
    final title = switch (kind) {
      _RequestKind.change => '${ptWhen(start)}(으)로 바꿔 달라고 신청할까요?',
      _RequestKind.makeup => '${ptWhen(start)}에 보강을 신청할까요?',
      _RequestKind.normal => '${ptWhen(start)} 수업을 신청할까요?',
    };
    final body = switch (kind) {
      _RequestKind.change => '선생님이 승인하면 원래 예약(${ptWhen(from!.start)})은 자동으로 취소돼요. 거절되거나 답이 없으면 원래 예약이 그대로 남아요.',
      _ when urgent => '곧 시작하는 수업이라 선생님께 바로 알려 드려요. 선생님이 승인하면 예약이 확정돼요.',
      _ => '선생님이 승인하면 예약이 확정돼요. ${AppConfig.ptAutoRejectHours}시간 안에 답이 없으면 자동으로 취소돼요.',
    };
    final ok = await confirmDialog(
      context,
      title: title,
      body: body +
          // 바꾸기 신청도 24시간 안 칸이면 승인 뒤 취소가 차감된다 (리뷰 11/23 #5)
          (late ? '\n\n수업 ${AppConfig.ptFreeCancelHours}시간 전이 지나서, 승인된 뒤 취소하면 PT 1회가 차감돼요.' : ''),
      keepLabel: '그만두기',
      okLabel: '신청하기',
    );
    if (!ok || !mounted) return;
    demo.update(() => demo.ptBookings
        .add(PtBooking(member: me, start: start, requestedAt: DateTime.now(), replaces: from, makeupFor: forMakeup)));
    setState(() {
      changing = null;
      makeup = null;
    });
    toast(
        context,
        switch (kind) {
          _RequestKind.change => '시간 바꾸기를 신청했어요. 선생님이 답하면 알려 드릴게요',
          _RequestKind.makeup => '보강을 신청했어요. 선생님이 답하면 알려 드릴게요',
          _RequestKind.normal => '신청했어요. 선생님이 답하면 알려 드릴게요',
        });
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
      // 원래 예약을 취소하면 그 예약의 시간 바꾸기 신청도 함께 정리 (결정 d1122-2)
      for (final c in demo.ptBookings) {
        if (c.replaces == b && ptStatusAt(c, now) == PtStatus.requested) c.status = PtStatus.cancelled;
      }
      if (changing == b) changing = null;
    });
    toast(context, free ? '수업을 취소했어요' : '수업을 취소했어요. PT 1회가 차감됐어요');
  }

  @override
  Widget build(BuildContext context) {
    // 홈 카드에서 왔으면 그려진 다음 바로 보강 고르기를 시작한다 (디자인 리뷰 11/24 #1)
    if (demo.ptMakeupStart case final b?) {
      demo.ptMakeupStart = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startMakeup(b);
      });
    }
    final now = DateTime.now();
    final days = ptBookingDays(now);
    final mine = demo.ptBookings.where((b) => b.member == me).toList()..sort((a, b) => a.start.compareTo(b.start));
    // 시간이 지난 수업은 취소할 수 없게 '내 예약'에서 빼고 아래 기록으로 (리뷰 11/19 #1)
    bool isUpcoming(PtBooking b) => ptHoldsSlot(ptStatusAt(b, now)) && b.start.isAfter(now);
    bool changeRequested(PtBooking b) => demo.ptBookings.any((c) => c.replaces == b && ptStatusAt(c, now) == PtStatus.requested);
    final upcoming = [for (final b in mine) if (isUpcoming(b)) b];
    // 선생님이 취소한 앞으로의 수업은 '지난 기록'이 아니라 위에서 알린다 (리뷰 11/23 #1)
    final cancelledAhead = demo.ptTrainerCancelledAhead(me, now);
    final past = [for (final b in mine.reversed) if (!isUpcoming(b) && !cancelledAhead.contains(b)) b].take(3).toList();
    final opened = [
      for (final h in AppConfig.ptLessonHours)
        if (demo.ptOpenSlots.contains(days[day].add(Duration(hours: h)))) days[day].add(Duration(hours: h)),
    ];
    final slots = [for (final s in opened) if (s.isAfter(now)) s];
    final children = <Widget>[
      LineRow(
        left: const Text('남은 PT', style: AppText.bodyStrong),
        right: Text('${demo.ptLeft[me] ?? 0}회', style: AppText.bodyStrongAccent),
      ),
      // 갑자기 0회를 만나지 않게 2회 남으면 미리 알린다 (결정 d1121-2)
      if (demo.ptLowOf(me))
        WarningBox('남은 PT가 ${demo.ptLeft[me]}회예요. 이어서 받으려면 선생님께 재등록을 이야기해 보세요', top: 0, caution: true),
      const H2('내 예약'),
      for (final b in cancelledAhead) ...[
        WarningBox('선생님이 수업을 취소했어요 · ${ptTrainerCancelText(b)}', top: 0, caution: true),
        // 빠진 수업을 버튼 하나로 다시 잡게 (결정 d1123-1)
        if (demo.ptMakeupOf(b, now) case final m?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            // 신청 중인지 잡혔는지 나눠 알린다 (디자인 리뷰 11/24 #5)
            child: WordText(ptMakeupNote(m, now), style: AppText.captionAccent),
          )
        else if (demo.ptMakeupRedone(b, now) case final r?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: WordText('보강 수업(${ptWhen(r.start)})도 선생님이 취소했어요 · 그 알림에서 다시 신청해 주세요', style: AppText.captionCaution),
          )
        else ...[
          if (demo.ptMakeupMissText(b, now) case final miss?)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: WordText(miss, style: AppText.captionCaution),
            ),
          AppButton('보강 신청하기', kind: ButtonKind.soft, top: AppSpace.xs, onPressed: () => _startMakeup(b)),
        ],
        const SizedBox(height: AppSpace.s),
      ],
      if (upcoming.isEmpty) const Muted('잡힌 수업이 없어요. 아래에서 시간을 골라 신청해 보세요.'),
      for (final b in upcoming)
        MyBookingCard(
          b,
          now: now,
          onCancel: () => _cancel(b),
          changeRequested: changeRequested(b),
          // 무료 취소 기한 안의 확정 수업만, 그리고 이미 바꾸기 신청 중이면 숨긴다 (결정 d1122-2, 설계: 24시간 전까지 변경 신청)
          onChange: ptStatusAt(b, now) == PtStatus.approved && ptFreeCancel(b, now) && !changeRequested(b)
              ? () => _startChange(b)
              : null,
          choosing: changing == b,
        ),
      const H2('시간 고르기'),
      if (makeup case final c?)
        ChooseGuide(
          key: _changeGuide,
          title: '선생님이 취소한 ${ptWhen(c.start)} 수업의 보강 시간을 골라 주세요',
          note: '선생님 화면에 보강 신청으로 따로 보여요.',
          onStop: () => setState(() => makeup = null),
        ),
      if (changing case final c?)
        ChooseGuide(
          key: _changeGuide,
          title: '${ptWhen(c.start)} 수업을 옮길 시간을 골라 주세요',
          note: '선생님이 승인할 때까지 원래 예약은 그대로 있어요.',
          onStop: () => setState(() => changing = null),
        ),
      Muted('${AppConfig.ptBookingDays ~/ 7}주 앞까지, 하루 한 번 신청할 수 있어요.'),
      DayChips(labels: ptDayChipLabels(days), selected: day, today: 0, onSelect: (i) => setState(() => day = i)),
      // 열린 시간이 다 지나서 빈 날과, 처음부터 안 연 날을 나눠 알린다 (디자인 리뷰 11/19 #1)
      if (slots.isEmpty && opened.isNotEmpty)
        const SlotEmpty.passed()
      else if (slots.isEmpty)
        const SlotEmpty('이날은 선생님이 수업 시간을 열지 않았어요. 다른 날을 골라 주세요.')
      else
        SlotGrid(children: [
          for (final s in slots) MemberSlot(start: s, now: now, me: me, onRequest: () => _request(s)),
        ]),
      const SlotLegend([(SlotTone.open, '신청 가능'), (SlotTone.taken, '마감'), (SlotTone.pending, '내 신청'), (SlotTone.filled, '내 예약')]),
      if (past.isNotEmpty) ...[
        // 안의 상태 글 '지난 신청'과 헷갈리지 않게, 수업 완료도 들어가니 '지난 기록' (리뷰 11/19 #7)
        const H2('지난 기록'),
        for (final b in past)
          LineRow(
            // 긴 상태 글이 날짜를 밀지 않게, 선생님 취소는 놓치지 않게 주황 (디자인 리뷰 11/23 #5)
            rightBelowOnLargeText: true,
            left: WordText(ptWhen(b.start)),
            right: b.status == PtStatus.trainerCancelled
                ? WordText(ptMemberLabel(b, now), style: AppText.captionCaution)
                : Muted(ptMemberLabel(b, now), bottom: 0),
          ),
      ],
      const SizedBox(height: AppSpace.l),
      Muted('수업 ${AppConfig.ptFreeCancelHours}시간 전까지는 무료로 취소할 수 있어요. 그 뒤에 취소하거나 오지 않으면 PT 1회가 차감돼요. '
          '사정이 있으면 선생님이 차감을 빼 줄 수 있어요.'),
    ];
    return widget.embedded
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)
        : AppPage(title: '수업 예약', children: children);
  }
}
