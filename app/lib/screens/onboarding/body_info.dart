import 'package:flutter/material.dart';

import '../../logic/tdee.dart';
import '../../routes.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'setup_page.dart';

/// S02 몸 정보 입력
class BodyInfoScreen extends StatefulWidget {
  const BodyInfoScreen({super.key});

  @override
  State<BodyInfoScreen> createState() => _BodyInfoScreenState();
}

class _BodyInfoScreenState extends State<BodyInfoScreen> {
  /// [다음]을 한 번 누른 뒤부터 칸 아래에 안내를 보여 준다
  bool tried = false;

  Map<String, String> _check() => validateBody(
      height: demo.height,
      age: demo.age,
      weight: demo.weight,
      muscle: demo.muscleUnknown ? '' : demo.muscle,
      bodyFat: demo.bodyFatUnknown ? '' : demo.bodyFat,
      bodyFatPercent: demo.bodyFatUnit == '%',);

  bool _valid() {
    final errors = _check();
    if (errors.isNotEmpty) {
      setState(() => tried = true);
      toast(context, errors['age'] == underAgeError ? '$underAgeError.' : '입력한 값을 확인해 주세요.');
      return false;
    }
    demo.update(() {}); // 입력한 숫자를 기기에 저장
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final errors = tried ? _check() : const <String, String>{};
    final teen = (int.tryParse(demo.age) ?? 99) >= minAge && (int.tryParse(demo.age) ?? 99) <= teenMaxAge;
    return SetupPage(title: '몸 정보', step: 1, canSave: _valid, onNext: () => Navigator.pushNamed(context, Routes.condition), children: [
      // 로그인 전에 넣은 정보가 어디에 있는지 알린다 (결정 d1029-local-notice)
      if (demo.isGuest) const Muted('입력한 정보는 이 폰에만 저장돼요. 로그인하기 전엔 어디에도 보내지 않아요'),
      const FieldLabel('성별'),
      Seg(options: const ['남', '여'], value: demo.sex, onChanged: (v) => demo.update(() => demo.sex = v)),
      // 폰에서 라벨이 잘리지 않게 한 줄에 한 칸씩 (리뷰 10/29 #2)
      NumField(label: '키 (cm)', value: demo.height, error: errors['height'], onChanged: (v) => demo.update(() => demo.height = v)),
      const SizedBox(height: AppSpace.m),
      NumField(label: '나이 (만)', value: demo.age, error: errors['age'], onChanged: (v) => demo.update(() => demo.age = v)),
      // 놓치면 안 되는 안내는 큰 경고 상자로, 나이 칸 바로 아래에 (리뷰 10/29 #6, 디자인 리뷰 11/05 #5)
      if (errors['age'] == underAgeError)
        const WarningBox('만 14세 미만은 보호자 동의 절차가 필요해서 지금은 이용할 수 없어요.'),
      const SizedBox(height: AppSpace.m),
      NumField(label: '몸무게 (kg)', value: demo.weight, error: errors['weight'], onChanged: (v) => demo.update(() => demo.weight = v)),
      const SizedBox(height: AppSpace.m),
      _OptionalField(
        label: '근육량 (kg, 선택)',
        value: demo.muscle,
        unknown: demo.muscleUnknown,
        error: errors['muscle'],
        onChanged: (v) => demo.update(() => demo.muscle = v),
        onUnknown: () => demo.update(() => demo.muscleUnknown = !demo.muscleUnknown),
      ),
      _OptionalField(
        label: demo.bodyFatUnit == '%' ? '체지방률 (%, 선택)' : '체지방량 (kg, 선택)',
        value: demo.bodyFat,
        unknown: demo.bodyFatUnknown,
        error: errors['bodyFat'],
        onChanged: (v) => demo.update(() => demo.bodyFat = v),
        onUnknown: () => demo.update(() => demo.bodyFatUnknown = !demo.bodyFatUnknown),
      ),
      // 인바디 결과지에 따라 kg이나 %로 적는다 (결정 d1029-bodyfat-unit)
      if (!demo.bodyFatUnknown)
        Seg(options: const ['kg', '%'], value: demo.bodyFatUnit, onChanged: (v) => demo.update(() => demo.bodyFatUnit = v)),
      const Muted("체지방을 알면 더 정확한 공식으로 계산해요. 모르면 '잘 모르겠음'을 눌러 주세요."),
      const FieldLabel('목표'),
      Seg(options: const ['감량', '유지', '증량'], value: demo.goal, onChanged: (v) => demo.update(() => demo.goal = v)),
      if (teen && demo.goal == '감량')
        const AppCard(
          accent: true,
          child: Text('성장기에는 키가 크는 데도 에너지가 필요해요. 그래서 감량 폭을 줄여서 계산해요. '
              '보호자나 전문가와 상의하며 천천히 관리하는 걸 권해요.'),
        ),
    ]);
  }
}

class _OptionalField extends StatelessWidget {
  const _OptionalField({required this.label, required this.value, required this.unknown, required this.onChanged, required this.onUnknown, this.error});
  final String label;
  final String? error;
  final String value;
  final bool unknown;
  final ValueChanged<String> onChanged;
  final VoidCallback onUnknown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: NumField(
              key: ValueKey('$label$unknown'),
              label: label,
              value: unknown ? '' : value,
              enabled: !unknown,
              error: unknown ? null : error,
              onChanged: onChanged),
        ),
        const SizedBox(width: 8),
        SelectChip('잘 모르겠음', selected: unknown, onSelected: (_) => onUnknown()),
      ]),
    );
  }
}
