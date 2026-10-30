import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../routes.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/weight_sheet.dart';
import 'onboarding.dart';

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
      ('이번 주 몸무게 기록', demo.weightLoggedThisWeek, () => showWeightSheet(context)),
    ];
    if (demo.isGuest) return _guestHome(context, target, today);
    return TabBody(children: [
      H1('안녕하세요, ${demo.displayName}'),
      AppCard(
        onTap: () => Navigator.pushNamed(context, Routes.records),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Muted('연속 기록${demo.restMode ? ' · 쉬기 모드 중' : ''}', bottom: 2),
          BigNumber('${demo.streak}일째'),
          Muted('${demo.recordedToday ? '오늘 기록 완료!' : '오늘 하나만 기록하면 ${demo.streak + 1}일이에요'} · 자세히 ›', bottom: 0),
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
          right: g.$2 ? const Muted('완료', bottom: 0) : null,
          showArrow: !g.$2,
        ),
      const SizedBox(height: 14),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('오늘 먹은 칼로리', bottom: 2),
          Text.rich(TextSpan(children: [
            TextSpan(text: formatNumber(todayEatenKcal), style: AppText.number),
            TextSpan(text: ' / ${formatNumber(target)} kcal'),
          ])),
          ProgressBar(todayEatenKcal / target),
        ]),
      ),
      const H2('오늘 식단'),
      const _TodayMealRows(),
      const H2('오늘 운동'),
      _TodayWorkoutCard(today),
      const Disclaimer(),
    ]);
  }

  /// 게스트 홈: 기록·목표 대신 내 칼로리와 예시 식단·운동만 보여 준다.
  Widget _guestHome(BuildContext context, int target, WorkoutDay today) {
    return TabBody(children: [
      H1('안녕하세요, ${demo.displayName}'),
      const GuestBanner('로그인하면 내 몸에 맞춘 식단·운동 루틴을 AI가 만들고, 연속 기록도 쌓을 수 있어요.'),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('내 칼로리', style: AppText.bodyStrong),
          const SizedBox(height: 8),
          if (demo.calorieCalculated) ...[
            const Muted('하루에 쓰는 칼로리', bottom: 2),
            BigNumber('${formatNumber(demo.tdee.tdee)} kcal'),
            const SizedBox(height: 8),
            Muted('${demo.goal} 목표 칼로리', bottom: 2),
            BigNumber('${formatNumber(target)} kcal'),
          ] else
            const Muted('몸 정보를 입력하면 하루 소비 칼로리와 목표 칼로리를 계산해 드려요.', bottom: 0),
          AppButton(demo.calorieCalculated ? '다시 계산하기' : '내 칼로리 계산하기',
              kind: demo.calorieCalculated ? ButtonKind.soft : ButtonKind.primary,
              onPressed: () => Navigator.pushNamed(context, Routes.body)),
          if (demo.calorieCalculated) AppButton('식단·운동 루틴 만들기', onPressed: () => openPlanMaker(context)),
        ]),
      ),
      const H2('예시 식단'),
      const Muted('로그인하면 내 목표 칼로리에 맞춰 새로 만들어요.'),
      const _TodayMealRows(),
      const H2('예시 운동'),
      _TodayWorkoutCard(today),
      const Disclaimer(text: '예시 식단과 운동 루틴은 의료 조언이 아닙니다.'),
    ]);
  }
}

/// 오늘 식단 줄. 누르면 식단 탭으로 간다 (디자인 리뷰 10/29 #2)
class _TodayMealRows extends StatelessWidget {
  const _TodayMealRows();

  @override
  Widget build(BuildContext context) => Column(children: [
        for (final m in mealDays[0])
          LineRow(
            onTap: () => demo.update(() => demo.tab = 1),
            left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.title, style: AppText.bodyStrong),
              Muted(m.foods.map((f) => '${f.name} ${f.grams}g').join(' · '), bottom: 0),
            ]),
            right: Muted('${m.kcal} kcal', bottom: 0),
          ),
      ]);
}

/// 오늘 운동 카드. 누르면 운동 탭으로 간다
class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard(this.today);
  final WorkoutDay today;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: () => demo.update(() => demo.tab = 2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(today.title, style: AppText.bodyStrong),
          // 쉬는 날은 '0종목'이 아니라 쉬는 날 안내, '외'는 3개 이상일 때만 (리뷰 10/30 #4)
          if (today.isRest || today.items.isEmpty)
            const Muted('오늘은 쉬는 날이에요 · 가벼운 걷기 30분 추천', bottom: 0)
          else ...[
            Muted(
                '${today.items.length}종목 · ${today.items.take(2).map((e) => e.name).join(', ')}${today.items.length > 2 ? ' 외' : ''}',
                bottom: 8),
            // 좁은 폰에서 줄이 넘어가도 그림끼리 붙지 않게
            Wrap(spacing: 6, runSpacing: 6, children: [for (final e in today.items) ExerciseThumb(e.name)]),
          ],
        ]),
      );
}
