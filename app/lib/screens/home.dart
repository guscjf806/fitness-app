import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../routes.dart';
import '../state/demo_state.dart';
import '../widgets/common.dart';

/// S07 홈
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final target = demo.tdee.target;
    final today = demo.week[0];
    final goals = [
      ('식단 1끼 올리기', demo.mealPostedToday, () => Navigator.pushNamed(context, Routes.mealPost)),
      ('오늘 운동 완료', demo.workoutDone, () => demo.update(() => demo.tab = 2)),
      ('이번 주 몸무게 기록', demo.weightLogged, () {
        demo.update(() => demo.weightLogged = true);
        toast(context, '이번 주 몸무게를 기록했어요 (${demo.weight}kg)');
      }),
    ];
    return TabBody(children: [
      H1('안녕하세요, ${demo.displayName}'),
      AppCard(
        onTap: () => Navigator.pushNamed(context, Routes.records),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Muted('연속 기록${demo.restMode ? ' · 쉬기 모드 중' : ''}', bottom: 2),
          BigNumber('${demo.streak}일째'),
          Muted('${demo.recordedToday ? '오늘 기록 완료!' : '오늘 하나만 기록하면 7일이에요'} · 자세히 ›', bottom: 0),
        ]),
      ),
      if (demo.role == 'member')
        AppCard(
          accent: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Muted('선생님이 준 이번 주 미션', bottom: 2),
            Text(demo.missions['김지아'] ?? '아직 미션이 없어요'),
          ]),
        ),
      const H2('오늘의 작은 목표', top: 6),
      for (final g in goals)
        LineRow(
          onTap: g.$2 ? null : g.$3,
          left: Row(children: [CheckCircle(g.$2), const SizedBox(width: 10), Text(g.$1)]),
          right: Muted(g.$2 ? '완료' : '›', bottom: 0),
        ),
      const SizedBox(height: 14),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('오늘 먹은 칼로리', bottom: 2),
          Text.rich(TextSpan(children: [
            TextSpan(text: formatNumber(todayEatenKcal), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            TextSpan(text: ' / ${formatNumber(target)} kcal'),
          ])),
          ProgressBar(todayEatenKcal / target),
        ]),
      ),
      const H2('오늘 식단'),
      for (final m in mealDays[0])
        LineRow(
          left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Muted(m.foods.map((f) => '${f.name} ${f.grams}g').join(' · '), bottom: 0),
          ]),
          right: Muted('${m.kcal} kcal', bottom: 0),
        ),
      const H2('오늘 운동'),
      AppCard(
        onTap: () => demo.update(() => demo.tab = 2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(today.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Muted('${today.items.length}종목 · ${today.items.take(2).map((e) => e.name).join(', ')} 외', bottom: 8),
          Wrap(spacing: 6, children: [for (final e in today.items) ExerciseThumb(e.name)]),
        ]),
      ),
      const Disclaimer(),
    ]);
  }
}
