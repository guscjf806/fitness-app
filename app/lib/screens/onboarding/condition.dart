import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// S03 운동 강도·조건 선택
class ConditionScreen extends StatelessWidget {
  const ConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget title(String t, [String? sub]) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: AppText.bodyStrong),
            if (sub != null) Muted(sub, bottom: 0),
          ]),
        );
    return AppPage(title: '운동 강도와 조건', children: [
      // 고르기 전에 기준을 먼저 보게 맨 위에, 본문 글씨로 (리뷰 10/29 #5)
      const AppCard(
        child: Text('하: 주 1~3회 가볍게 · 중: 주 3~5회 · 상: 주 6회 이상 또는 고강도',
            style: AppText.body),
      ),
      title('지금 하고 있는 강도', '칼로리 계산에 쓰여요'),
      Seg(options: const ['하', '중', '상'], value: demo.currentIntensity, onChanged: (v) => demo.update(() => demo.currentIntensity = v)),
      title('앞으로 원하는 강도', '운동 루틴의 세기에 쓰여요'),
      Seg(options: const ['하', '중', '상'], value: demo.desiredIntensity, onChanged: (v) => demo.update(() => demo.desiredIntensity = v)),
      title('운동 장소'),
      Seg(options: const ['헬스장', '집', '둘 다'], value: demo.place, onChanged: (v) => demo.update(() => demo.place = v)),
      if (demo.place != '헬스장') ...[
        title('집에 있는 장비'),
        Seg(options: const ['맨몸', '밴드·덤벨'], value: demo.equipment, onChanged: (v) => demo.update(() => demo.equipment = v)),
        title('층간소음이 걱정돼요', '예를 고르면 점프 동작을 빼요'),
        Seg(options: const ['예', '아니오'], value: demo.noise, onChanged: (v) => demo.update(() => demo.noise = v)),
      ],
      title('한 번에 운동할 시간'),
      Seg(options: const ['15분', '30분', '45분'], value: demo.minutes, onChanged: (v) => demo.update(() => demo.minutes = v)),
      AppButton('다음', onPressed: () => Navigator.pushNamed(context, Routes.condition2)),
    ]);
  }
}
