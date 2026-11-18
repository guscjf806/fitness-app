import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

/// PT 예약 시간 칸의 모양. 회원 화면과 선생님 화면이 같이 쓴다 (디자인 리뷰 11/18 #3)
enum SlotTone {
  /// 신청 가능 / 열림: 연한 초록
  open,

  /// 다른 회원이 잡음: 회색, 누를 수 없음
  taken,

  /// 내 신청·예약 / 회원 신청·예약: 진한 초록
  filled,

  /// 선생님이 닫아 둔 시간: 테두리만
  closed,
}

({Color? bg, Color fg, Color border}) slotColors(SlotTone tone) => switch (tone) {
      SlotTone.open => (bg: AppColors.primarySoft, fg: AppColors.primaryDark, border: AppColors.primary),
      SlotTone.taken => (bg: AppColors.line, fg: AppColors.textSub, border: AppColors.line),
      SlotTone.filled => (bg: AppColors.primary, fg: Colors.white, border: AppColors.primary),
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
