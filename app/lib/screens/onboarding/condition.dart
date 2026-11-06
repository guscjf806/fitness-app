import 'package:flutter/material.dart';

import '../../logic/routine.dart';
import '../../routes.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'setup_page.dart';

/// S03 운동 강도·조건 선택
class ConditionScreen extends StatelessWidget {
  const ConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SetupPage(title: '운동 강도와 조건', step: 2, onNext: () => Navigator.pushNamed(context, Routes.condition2), children: [
      // 고르기 전에 기준을 먼저 보게 맨 위에, 본문 글씨로 (리뷰 10/29 #5)
      const AppCard(
        child: WordText('안 함: 거의 앉아서 지내요 · 하: 주 1~3회 가볍게 · 중: 주 3~5회 · 상: 주 6회 이상 또는 고강도',
            style: AppText.body),
      ),
      const FieldLabel('지금 하고 있는 강도', sub: '칼로리 계산에 쓰여요'),
      Seg(options: const ['안 함', '하', '중', '상'], value: demo.currentIntensity, onChanged: (v) => demo.update(() => demo.currentIntensity = v)),
      const FieldLabel('앞으로 원하는 강도', sub: '운동 루틴의 세기에 쓰여요'),
      Seg(options: const ['하', '중', '상'], value: demo.desiredIntensity, onChanged: (v) => demo.update(() => demo.desiredIntensity = v)),
      const FieldLabel('운동 장소'),
      Seg(options: const ['헬스장', '집', '둘 다'], value: demo.place, onChanged: (v) => demo.update(() => demo.place = v)),
      if (demo.place != '헬스장') ...[
        // 가진 것만 추천되게 여러 개 고른다 (결정 d1027-home-gear)
        const FieldLabel('집에 있는 장비', sub: '있는 것을 모두 골라 주세요. 없으면 맨몸 운동으로 짜요'),
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.xsPlus, bottom: AppSpace.m),
          child: Wrap(spacing: AppSpace.xsPlus, runSpacing: AppSpace.xsPlus, children: [
            for (final g in homeGearOptions)
              SelectChip(g,
                  selected: demo.homeGear.contains(g),
                  onSelected: (_) => demo.update(() => demo.homeGear.contains(g) ? demo.homeGear.remove(g) : demo.homeGear.add(g))),
          ]),
        ),
        const FieldLabel('층간소음이 걱정돼요', sub: '예를 고르면 점프 동작을 빼요'),
        Seg(options: const ['예', '아니오'], value: demo.noise, onChanged: (v) => demo.update(() => demo.noise = v)),
      ],
      const FieldLabel('한 번에 운동할 시간'),
      Seg(options: const ['15분', '30분', '45분'], value: demo.minutes, onChanged: (v) => demo.update(() => demo.minutes = v)),
    ]);
  }
}
