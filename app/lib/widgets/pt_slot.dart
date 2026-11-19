import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

/// PT 예약 시간 칸의 모양. 회원 화면과 선생님 화면이 같이 쓴다 (디자인 리뷰 11/18 #3)
enum SlotTone {
  /// 신청 가능 / 열림: 연한 초록
  open,

  /// 다른 회원이 잡음: 회색, 누를 수 없음
  taken,

  /// 확정된 예약: 진한 초록
  filled,

  /// 승인을 기다리는 신청: 주황 (결정 d1118-1, '급한 신청' 주황과 같은 뜻)
  pending,

  /// 선생님이 닫아 둔 시간: 테두리만
  closed,
}

({Color? bg, Color fg, Color border}) slotColors(SlotTone tone) => switch (tone) {
      SlotTone.open => (bg: AppColors.primarySoft, fg: AppColors.primaryDark, border: AppColors.primary),
      SlotTone.taken => (bg: AppColors.line, fg: AppColors.textSub, border: AppColors.line),
      SlotTone.filled => (bg: AppColors.primary, fg: Colors.white, border: AppColors.primary),
      SlotTone.pending => (bg: AppColors.cautionSoft, fg: AppColors.caution, border: AppColors.caution),
      SlotTone.closed => (bg: null, fg: AppColors.textSub, border: AppColors.line),
    };

/// 위는 굵은 시각, 아래는 상태 글(두 줄까지). [selected]면 상태 글 앞에 체크를 붙이고 읽어 주기에도 알린다
class TimeSlotButton extends StatelessWidget {
  const TimeSlotButton({super.key, required this.time, required this.label, required this.tone, this.onTap, this.selected = false});
  final String time;
  final String label;
  final SlotTone tone;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = slotColors(tone);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: c.bg ?? Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          side: BorderSide(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s, horizontal: AppSpace.xs),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(time, style: AppText.bodyStrong.copyWith(color: c.fg)),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (selected) Icon(Icons.check, size: MediaQuery.textScalerOf(context).scale(14), color: c.fg),
                  Flexible(child: WordText(label, textAlign: TextAlign.center, style: AppText.small.copyWith(color: c.fg))),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// 시간 칸을 한 줄에 3개씩, 줄 폭을 꽉 채워 놓는다. 큰 글씨에서는 칸이 아래로 늘어난다
class SlotGrid extends StatelessWidget {
  const SlotGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        const gap = AppSpace.s;
        final w = (box.maxWidth - gap * 2) / 3;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final c in children) SizedBox(width: w, child: c),
        ]);
      });
}

/// 고를 시간 칸이 없을 때의 안내 카드. 회원·선생님 화면이 같이 쓴다 (디자인 리뷰 11/19 #1)
class SlotEmpty extends StatelessWidget {
  const SlotEmpty(this.message, {super.key});

  /// 오늘 시간이 다 지나서 빈 날
  const SlotEmpty.passed({super.key}) : message = '오늘 수업 시간은 다 지났어요. 다른 날을 골라 주세요.';

  final String message;

  @override
  Widget build(BuildContext context) => AppCard(child: WordText(message));
}

/// 시간 칸 색 설명. 견본은 칸과 같은 바탕·테두리이고 글씨 크기를 따라 커진다 (디자인 리뷰 11/18 #5)
/// 위 여백은 여기 한 곳에서 정해 회원·선생님 화면이 같게 둔다 (디자인 리뷰 11/19 #5)
class SlotLegend extends StatelessWidget {
  const SlotLegend(this.items, {super.key});
  final List<(SlotTone, String)> items;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.textScalerOf(context).scale(12);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.l),
      child: Wrap(spacing: AppSpace.m, runSpacing: AppSpace.xs, children: [
      for (final (tone, text) in items)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: slotColors(tone).bg,
              border: Border.all(color: slotColors(tone).border),
              // 12px 작은 견본이라 칸 모서리(AppRadius.small 10)를 그대로 쓰면 동그라미가 된다. 비율을 맞춰 1/4로
              borderRadius: BorderRadius.circular(AppRadius.small / 4),
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          Text(text, style: AppText.caption.copyWith(color: AppColors.textSub)),
        ]),
      ]),
    );
  }
}
