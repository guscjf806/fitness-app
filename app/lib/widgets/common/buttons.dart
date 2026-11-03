/// 공용 부품: 버튼·고르기 버튼·요일 칩
library;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

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
        child: Text(label),
      ),
    );
  }
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
          for (final o in options)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _SegButton(
                    label: o, selected: o == value, onTap: () => onChanged(o)),
              ),
            ),
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

/// 가로로 스크롤되는 날짜·요일 칩
class DayChips extends StatelessWidget {
  /// '화 휴식' 같은 뒷말은 그대로 두고 요일 바로 뒤에 '·오늘'을 넣는다
  String _label(int i) {
    final l = labels[i];
    if (i != today) return l;
    final space = l.indexOf(' ');
    return space < 0 ? '$l·오늘' : '${l.substring(0, space)}·오늘${l.substring(space)}';
  }

  const DayChips({super.key, required this.labels, required this.selected, required this.onSelect, this.today});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  /// 오늘인 칸. 주면 그 칩에 '·오늘'을 붙여 식단·운동 탭이 같은 모양이 된다 (리뷰 11/01 #6)
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
                  label: Text(_label(i)),
                  selected: i == selected,
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                      color: i == selected ? Colors.white : AppColors.text),
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
