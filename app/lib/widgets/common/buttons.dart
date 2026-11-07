/// 공용 부품: 버튼·고르기 버튼·요일 칩
library;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'text.dart';

enum ButtonKind { primary, soft }

class AppButton extends StatelessWidget {
  const AppButton(this.label,
      {super.key, required this.onPressed, this.kind = ButtonKind.primary, this.top = 12});
  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: FilledButton(
        onPressed: onPressed,
        style: kind == ButtonKind.soft
            ? FilledButton.styleFrom(
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.primaryDark)
            : null,
        // 큰 글씨에서 단어 중간에 끊기지 않게 (디자인 리뷰 11/07 #3)
        child: WordText(label, textAlign: TextAlign.center),
      ),
    );
  }
}

/// 지우기·빼기 글자 버튼. 글자색만 바꾸면 눌림 물결이 초록이라 물결까지 경고색으로 (디자인 리뷰 11/07 #7)
class DangerTextButton extends StatelessWidget {
  const DangerTextButton(this.label, {super.key, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        style: TextButton.styleFrom(foregroundColor: AppColors.warningText),
        onPressed: onPressed,
        child: Text(label),
      );
}

/// '더 보기' 글자 링크: 글자 + 화살표 아이콘. 목록 줄의 화살표와 같은 모양 (디자인 리뷰 10/31 #2)
class MoreLink extends StatelessWidget {
  const MoreLink(this.text, {super.key, this.color = AppColors.primaryDark});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(text, style: AppText.bodyStrong.copyWith(color: color)),
        Icon(Icons.chevron_right, size: 18, color: color),
      ]);
}

/// 여러 개 중 하나 고르기 (예: 남/여, 상/중/하)
class Seg extends StatelessWidget {
  const Seg({super.key, required this.options, required this.value, required this.onChanged});
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Row(
        children: [
          // 버튼 사이만 띄워서 양 끝이 카드·입력 칸과 줄이 맞게 (디자인 리뷰 11/06 #7)
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpace.xsPlus),
            Expanded(
              child: _SegButton(
                  label: options[i], selected: options[i] == value, onTap: () => onChanged(options[i])),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.small),
        onTap: onTap,
        // 손가락으로 누르기 쉽게 높이 48px 이상 (디자인 리뷰 10/30 #1)
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: selected ? AppColors.primaryDark : AppColors.text,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
          ),
        ),
      ),
    );
  }
}

/// 고르는 칩. 선택 표시는 체크 없이 색과 굵은 글씨로 통일한다 (디자인 리뷰 11/05 #4)
class SelectChip extends StatelessWidget {
  const SelectChip(this.label, {super.key, required this.selected, required this.onSelected});
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: selected,
        labelStyle: TextStyle(
            color: selected ? AppColors.primaryDark : AppColors.text,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400),
        onSelected: onSelected,
      );
}

/// 가로로 스크롤되는 날짜·요일 칩
class DayChips extends StatelessWidget {
  /// 두 줄 칩: 위는 요일, 아래는 작은 글씨로 '오늘'/'휴식' (결정 dd1031-daychip).
  /// labels의 '화 휴식'을 나눠 쓴다. 칩 높이가 같게 아랫줄이 비어도 자리를 둔다
  Widget _label(int i) {
    final parts = labels[i].split(' ');
    final day = parts.first;
    final notes = [if (i == today) '오늘', ...parts.skip(1)];
    final on = i == selected;
    // 칩 폭이 들쭉날쭉하지 않게 최소 폭. '오늘·휴식'처럼 길어질 수 있어 고정 폭은 쓰지 않는다
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(day, style: TextStyle(color: on ? Colors.white : AppColors.text, fontWeight: on ? FontWeight.w700 : FontWeight.w400)),
      Text(notes.isEmpty ? ' ' : notes.join('·'), style: AppText.small.copyWith(color: on ? Colors.white : AppColors.textSub)),
      ]),
    );
  }

  const DayChips({super.key, required this.labels, required this.selected, required this.onSelect, this.today});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  /// 오늘인 칸. 주면 그 칩 아랫줄에 '오늘'을 써서 식단·운동 탭이 같은 모양이 된다 (리뷰 11/01 #6)
  final int? today;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: _label(i),
                  selected: i == selected,
                  showCheckmark: false,
                  // 흰 글씨가 잘 읽히게 진한 청록으로 (디자인 리뷰 11/06 #5)
                  selectedColor: AppColors.primaryDark,
                  shape: const StadiumBorder(),
                  onSelected: (_) => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CheckCircle extends StatelessWidget {
  const CheckCircle(this.on, {super.key});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? AppColors.primary : null,
        border: Border.all(
            color: on ? AppColors.primary : AppColors.lineStrong, width: 2),
      ),
      child: on ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
    );
  }
}
