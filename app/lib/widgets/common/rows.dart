/// 공용 부품: 한 줄 목록(LineRow, SwitchRow)과 입력 칸·진행 막대
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../common.dart';

/// 켜고 끄는 스위치가 있는 줄. 스위치 색은 테마(switchTheme)에서 정한다 (디자인 리뷰 11/02 #2)
class SwitchRow extends StatelessWidget {
  const SwitchRow({super.key, required this.title, required this.subtitle, required this.value, required this.onChanged});
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => LineRow(
        left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title),
          Muted(subtitle, bottom: 0),
        ]),
        right: Switch(value: value, onChanged: onChanged),
      );
}

/// 쉬기 모드 스위치. 내 정보와 내 기록이 같은 문구·안내를 쓴다 (리뷰 11/03 #3)
class RestModeSwitch extends StatelessWidget {
  const RestModeSwitch({super.key});

  @override
  Widget build(BuildContext context) => SwitchRow(
        title: '쉬기 모드',
        subtitle: '아프거나 다칠 때 켜 두세요. 연속 기록이 유지돼요 (최대 7일)',
        value: demo.restMode,
        onChanged: (v) {
          demo.update(() => demo.restMode = v);
          toast(context, v ? '쉬기 모드를 켰어요. 알림이 멈추고 기록이 유지돼요' : '쉬기 모드를 껐어요');
        },
      );
}

/// 아래 구분선이 있는 한 줄
class LineRow extends StatelessWidget {
  const LineRow({super.key, required this.left, this.right, this.onTap, this.showArrow = false, this.rightBelowOnLargeText = false});
  final Widget left;
  final Widget? right;
  final VoidCallback? onTap;

  /// 오른쪽 끝에 누를 수 있다는 화살표를 붙인다 (디자인 리뷰 10/29 #3)
  final bool showArrow;

  /// 글자가 크면(1.3배 이상) 오른쪽 글을 왼쪽 글 아래 줄로 내린다. 왼쪽 이름이 좁아져 쪼개지지 않게 (디자인 리뷰 11/06 #2)
  final bool rightBelowOnLargeText;

  @override
  Widget build(BuildContext context) {
    final below = rightBelowOnLargeText && right != null && MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    return InkWell(
      onTap: onTap,
      child: Container(
        // 글자 한 줄이어도 누르는 자리가 48px 이상 되게 (디자인 리뷰 11/04 #5)
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(
          children: [
            Expanded(
              child: below
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: AppSpace.xs), right!])
                  : left,
            ),
            if (right != null && !below) ...[const SizedBox(width: AppSpace.sPlus), right!],
            if (showArrow) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textSub),
            ],
          ],
        ),
      ),
    );
  }
}

/// 숫자 입력칸
class NumField extends StatelessWidget {
  const NumField({super.key, required this.label, required this.value, required this.onChanged, this.hint, this.error, this.enabled = true, this.decimal = true, this.suffix});
  final String label;
  final String value;
  final String? hint;
  final String? error;
  final bool enabled;

  /// 소수점을 받을지. 횟수·세트처럼 정수만 받는 칸은 false (리뷰 11/06 #2)
  final bool decimal;

  /// 칸 안쪽 오른쪽의 단위. 좁은 칸에서 라벨이 잘리지 않게 라벨과 나눈다 (디자인 리뷰 11/06 #4)
  final String? suffix;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      enabled: enabled,
      keyboardType: decimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
      inputFormatters: decimal ? null : [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        // suffixText는 비었을 때 안 보여서 늘 보이는 작은 글자로 (디자인 리뷰 11/07 #5)
        suffixIcon: suffix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: AppSpace.s),
                child: Text(suffix!, style: AppText.small.copyWith(color: AppColors.textSub)),
              ),
        suffixIconConstraints: const BoxConstraints(),
      ),
      onChanged: onChanged,
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar(this.value, {super.key});
  final double value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            color: AppColors.primary,
            backgroundColor: AppColors.track,
          ),
        ),
      );
}

/// 누르면 고르는 창이 뜨는 입력 칸 (종목, 수업 날짜 등) (디자인 리뷰 11/08 #5)
class PickerField extends StatelessWidget {
  const PickerField({super.key, required this.label, required this.child, required this.icon, required this.onTap});
  final String label;
  final Widget child;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(AppRadius.small),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Row(children: [Expanded(child: child), icon]),
        ),
      );
}
