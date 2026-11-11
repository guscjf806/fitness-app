import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'setup_page.dart';

/// S03-2 식단·몸 상태 (기획서 B1: 못 먹는 음식, 아픈 부위, 주당 운동 일수)
class FoodBodyScreen extends StatelessWidget {
  const FoodBodyScreen({super.key});

  /// 식품 알레르기 표시 대상 중 자주 있는 것
  static const allergyOptions = ['우유', '달걀', '땅콩', '견과류', '대두', '밀가루', '메밀', '갑각류(새우·게)', '조개류', '생선', '복숭아', '토마토'];
  static const painOptions = ['목', '어깨', '허리', '손목', '무릎', '발목'];

  @override
  Widget build(BuildContext context) {
    void toggle(List<String> list, String v) => demo.update(() => list.contains(v) ? list.remove(v) : list.add(v));
    Widget chips(List<String> options, List<String> selected, {String? noneLabel}) => Padding(
          padding: const EdgeInsets.only(top: AppSpace.xsPlus, bottom: AppSpace.m),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            if (noneLabel != null)
              SelectChip(noneLabel, selected: selected.isEmpty, onSelected: (_) => demo.update(selected.clear)),
            for (final o in options)
              SelectChip(o, selected: selected.contains(o), onSelected: (_) => toggle(selected, o)),
          ]),
        );
    return SetupPage(
        title: '식단·몸 상태',
        step: 3,
        nextLabel: '결과 보기',
        onNext: () {
          demo.update(() {}); // 직접 입력한 음식을 기기에 저장
          Navigator.pushNamed(context, Routes.result);
        },
        children: [
      const FieldLabel('못 먹는 음식', sub: '알레르기가 있거나 못 먹는 음식은 식단에서 빼요. 여러 개 고를 수 있어요.'),
      chips(allergyOptions, demo.allergies, noneLabel: '없음'),
      TextFormField(
        initialValue: demo.allergyNote,
        decoration: const InputDecoration(labelText: '그 밖에 못 먹는 음식 (선택)', hintText: '예: 오이, 고수'),
        onChanged: (v) => demo.allergyNote = v,
      ),
      const SizedBox(height: AppSpace.l),
      const FieldLabel('아픈 부위', sub: '고른 부위에 무리가 가는 운동은 루틴에서 빼요.'),
      chips(painOptions, demo.painAreas, noneLabel: '없음'),
      if (demo.painAreas.isNotEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpace.m),
          child: WarningBox('통증이 심하거나 질환이 있다면 운동 전에 의사와 먼저 상담하세요.', top: 0),
        ),
      const FieldLabel('일주일에 운동할 수 있는 날'),
      Seg(options: const ['2일', '3일', '4일', '5일', '6일'], value: demo.daysPerWeek, onChanged: (v) => demo.update(() => demo.daysPerWeek = v)),
    ]);
  }
}
