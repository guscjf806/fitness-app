/// 회원 수업 예약 화면(pt_booking.dart)의 카드·시간 칸 부품 (디자인 리뷰 11/24 #3)
library;

import 'package:flutter/material.dart';

import '../config.dart';
import '../logic/pt_booking.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pt_slot.dart';

class MyBookingCard extends StatelessWidget {
  const MyBookingCard(this.b,
      {super.key,
      required this.now, required this.onCancel, this.onChange, this.changeRequested = false, this.choosing = false});
  final PtBooking b;
  final DateTime now;
  final VoidCallback onCancel;

  /// [시간 바꾸기]. 바꿀 수 없을 때는 null이라 버튼이 숨는다 (결정 d1122-2)
  final VoidCallback? onChange;

  /// 이 예약을 다른 시간으로 바꾸기 신청 중인지 (리뷰 11/23 #2)
  final bool changeRequested;

  /// 지금 이 예약을 옮길 시간을 고르는 중인지
  final bool choosing;

  @override
  Widget build(BuildContext context) {
    final status = ptStatusAt(b, now);
    final left = b.answerBy.difference(now);
    return AppCard(
      accent: status == PtStatus.approved,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WordText(ptWhen(b.start), style: AppText.bodyStrong),
        WordText(ptMemberLabel(b, now), style: status == PtStatus.approved ? AppText.captionAccent : AppText.caption),
        // 바꾸기 신청이 안 되면 원래 수업이 남는다는 걸 분명히 (리뷰 11/23 #2)
        if (status == PtStatus.requested && b.replaces != null)
          Muted(
              '${b.urgent ? '수업 시간 전까지' : '${ptLeftText(left)} 안에'} 답이 없으면 원래 예약(${ptWhen(b.replaces!.start)})이 그대로 남아요',
              top: AppSpace.xxs,
              bottom: 0)
        else if (status == PtStatus.requested && !b.urgent)
          Muted('${ptLeftText(left)} 안에 답이 없으면 자동으로 취소돼요', top: AppSpace.xxs, bottom: 0)
        // 급한 신청도 어떻게 되는지 알린다 (리뷰 11/19 #7)
        else if (status == PtStatus.requested && b.urgent)
          const Muted('수업 시간 전까지 답이 없으면 신청이 정리돼요', top: AppSpace.xxs, bottom: 0),
        if (changeRequested) const WordText('다른 시간으로 바꾸기 신청 중', style: AppText.captionCaution),
        if (choosing) const WordText('아래에서 바꿀 시간 고르는 중', style: AppText.captionAccent),
        // 날짜 계산을 하지 않아도 되게 무료 취소 기한을 바로 적는다 (리뷰 11/19 #3)
        if (status == PtStatus.approved)
          ptFreeCancel(b, now)
              ? Muted('${ptWhen(b.start.subtract(const Duration(hours: AppConfig.ptFreeCancelHours)))}까지 무료로 취소할 수 있어요',
                  top: AppSpace.xxs, bottom: 0)
              : const Padding(
                  padding: EdgeInsets.only(top: AppSpace.xxs),
                  child: WordText('지금 취소하면 PT 1회가 차감돼요', style: AppText.captionCaution),
                ),
        // 좁은 화면·큰 글씨에서 넘치지 않게 자리가 모자라면 두 줄로 (디자인 리뷰 11/23 #2)
        Wrap(alignment: WrapAlignment.end, spacing: AppSpace.xs, children: [
          if (onChange != null) TextButton(onPressed: onChange, child: const Text('시간 바꾸기')),
          // 차감될 수 있는 수업 취소는 다른 화면의 지우기·빼기처럼 경고색 (디자인 리뷰 11/18 #6)
          status == PtStatus.requested
              ? TextButton(onPressed: onCancel, child: const Text('신청 취소'))
              : DangerTextButton('수업 취소', onPressed: onCancel),
        ]),
      ]),
    );
  }
}

/// 회원이 보는 시간 칸: 신청 가능(연한 초록) · 마감(회색) · 내 신청(진한 초록 + 체크)
class MemberSlot extends StatelessWidget {
  const MemberSlot({super.key, required this.start, required this.now, required this.me, required this.onRequest});
  final DateTime start;
  final DateTime now;
  final String me;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final taken = demo.ptBookingAt(start, now);
    final mine = taken?.member == me;
    // 위 카드의 '예약 확정'과 맞게, 확정이면 '내 예약', 기다리는 중이면 '내 신청' (디자인 리뷰 11/19 #3)
    final approved = mine && ptStatusAt(taken!, now) == PtStatus.approved;
    final label = mine ? (approved ? '내 예약' : '내 신청') : (taken != null ? '마감' : '신청 가능');
    return TimeSlotButton(
      time: ptHourText(start),
      label: label,
      // 승인을 기다리는 내 신청은 주황, 확정은 초록 (결정 d1118-1)
      tone: mine ? (approved ? SlotTone.filled : SlotTone.pending) : (taken != null ? SlotTone.taken : SlotTone.open),
      selected: mine,
      onTap: taken == null ? onRequest : null,
    );
  }
}

/// '시간 고르기' 위에 뜨는 안내 카드. 보강과 시간 바꾸기가 같은 모양을 쓴다 (디자인 리뷰 11/24 #2)
class ChooseGuide extends StatelessWidget {
  const ChooseGuide({super.key, required this.title, required this.note, required this.onStop});
  final String title;
  final String note;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) => AppCard(
        accent: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          WordText(title, style: AppText.bodyStrong),
          Muted(note, bottom: 0),
          AppButton('그만두기', kind: ButtonKind.quiet, onPressed: onStop),
        ]),
      );
}
