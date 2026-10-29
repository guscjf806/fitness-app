import 'package:flutter/material.dart';

import '../screens/onboarding.dart';
import '../state/demo_state.dart';
import 'common.dart';

/// 이번 주 몸무게 기록 (기획서 B4: 몸무게 재입력 → TDEE 재계산 → 식단·운동 루틴 재생성 제안).
/// 몸무게가 늘거나 줄었다고 칭찬·경고하지 않는다 (기획서 14번 원칙). 기록한 행동만 인정한다.
void showWeightSheet(BuildContext context) {
  final controller = TextEditingController(text: demo.weight);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 28 + MediaQuery.of(sheetContext).viewInsets.bottom),
      child: _WeightForm(controller: controller, parentContext: context),
    ),
  ).whenComplete(controller.dispose);
}

class _WeightForm extends StatefulWidget {
  const _WeightForm({required this.controller, required this.parentContext});
  final TextEditingController controller;
  final BuildContext parentContext;

  @override
  State<_WeightForm> createState() => _WeightFormState();
}

class _WeightFormState extends State<_WeightForm> {
  (int before, int after)? saved;
  String? error;

  void _save() {
    final kg = double.tryParse(widget.controller.text);
    if (kg == null || kg < 30 || kg > 250) {
      setState(() => error = '30~250kg 사이로 입력해 주세요.');
      return;
    }
    final before = demo.tdee.target;
    final now = DateTime.now();
    demo.update(() {
      demo.weight = widget.controller.text;
      demo.weightLogs.add(WeightLog('${now.month}월 ${now.day}일', kg));
    });
    setState(() => saved = (before, demo.tdee.target));
  }

  @override
  Widget build(BuildContext context) {
    final result = saved;
    if (result != null) {
      final changed = (result.$2 - result.$1).abs() >= 50;
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SheetTitle('이번 주 몸무게를 기록했어요'),
        const SizedBox(height: 10),
        Muted(result.$1 == result.$2
            ? '목표 칼로리는 ${formatNumber(result.$2)}kcal 그대로예요.'
            : '목표 칼로리가 ${formatNumber(result.$1)} → ${formatNumber(result.$2)}kcal로 바뀌었어요.'),
        if (changed) ...[
          const Muted('지금 식단·운동 루틴은 바뀌기 전 칼로리로 만들었어요. 새로 만들면 바뀐 칼로리에 맞춰져요.'),
          AppButton('새 식단·운동 루틴 만들기', onPressed: () {
            Navigator.pop(context);
            openPlanMaker(widget.parentContext);
          }),
        ],
        AppButton('닫기', kind: changed ? ButtonKind.soft : ButtonKind.primary, onPressed: () => Navigator.pop(context)),
      ]);
    }
    final last = demo.weightLogs.isEmpty ? null : demo.weightLogs.last;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SheetTitle('이번 주 몸무게'),
      const SizedBox(height: 6),
      Muted(last == null ? '일주일에 한 번, 같은 시간대(예: 아침 공복)에 재면 좋아요.' : '지난 기록: ${last.date} ${last.kg}kg'),
      TextField(
        controller: widget.controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: '몸무게 (kg)', errorText: error),
        onSubmitted: (_) => _save(),
      ),
      AppButton('기록하기', onPressed: _save),
    ]);
  }
}
