import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../routes.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import 'logbook.dart';
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
      ('식단 1끼 기록하기', demo.mealPostedToday, () => Navigator.pushNamed(context, Routes.mealPost)),
      // 쉬는 날에는 끝낼 방법이 없는 목표라 뺀다 (리뷰 11/06 #3)
      if (!today.isRest) ('오늘 운동 완료', demo.workoutDone, () => demo.update(() => demo.tab = 2)),
      ('이번 주 몸무게 기록', demo.weightLoggedThisWeek, () => showWeightSheet(context)),
    ];
    if (demo.isGuest) return _guestHome(context, target, today);
    if (demo.role == 'trainer') return _trainerHome();
    return TabBody(children: [
      H1(demo.greeting),
      // 연속 기록은 작은 한 줄로, 오늘의 작은 목표를 맨 위로 (결정 dd1029-home-order)
      LineRow(
        onTap: () => Navigator.pushNamed(context, Routes.records),
        left: Row(children: [
          const Icon(Icons.local_fire_department, size: 20, color: AppColors.streakFire),
          const SizedBox(width: AppSpace.xsPlus),
          Text('연속 ${demo.streak}일째', style: AppText.bodyStrong),
          const SizedBox(width: AppSpace.s),
          Expanded(
            child: Muted(
                demo.restMode ? '쉬기 모드 중' : (demo.recordedToday ? '오늘 기록 완료!' : '오늘 하나만 기록하면 ${demo.streak + 1}일'),
                bottom: 0),
          ),
        ]),
        showArrow: true,
      ),
      // 쉬는 동안에는 목표로 재촉하지 않는다 (결정 d1106-4)
      if (demo.restMode) ...[
        // 위 구분선에 붙지 않게 (디자인 리뷰 11/07 #6)
        const SizedBox(height: AppSpace.s),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('쉬는 중이에요', style: AppText.bodyStrong),
            const Muted('연속 기록은 그대로 유지돼요.', bottom: 0),
            AppButton('쉬기 모드 끄기', kind: ButtonKind.soft, onPressed: () => demo.update(() => demo.restMode = false)),
          ]),
        ),
      ] else ...[
        const H2('오늘의 작은 목표', top: AppSpace.m),
        for (final g in goals)
          LineRow(
            onTap: g.$2 ? null : g.$3,
            // 큰 글씨에서 '완료'와 겹쳐 넘치지 않게 (디자인 리뷰 11/12 #3)
            rightBelowOnLargeText: true,
            left: Row(children: [CheckCircle(g.$2), const SizedBox(width: AppSpace.sPlus), Expanded(child: WordText(g.$1))]),
            right: g.$2 ? const Muted('완료', bottom: 0) : null,
            showArrow: !g.$2,
          ),
      ],
      const SizedBox(height: AppSpace.mPlus),
      if (demo.role == 'member')
        AppCard(
          accent: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Muted('선생님이 준 이번 주 미션', bottom: AppSpace.xxs),
            Text(demo.missions[demo.memberName] ?? '아직 미션이 없어요'),
          ]),
        ),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('오늘 먹은 칼로리', bottom: AppSpace.xxs),
          Text.rich(TextSpan(children: [
            TextSpan(text: formatNumber(demo.todayEatenKcal), style: AppText.number),
            TextSpan(text: ' / ${formatNumber(target)} kcal'),
          ])),
          ProgressBar(demo.todayEatenKcal / target),
          // 목표를 넘으면 막대만 꽉 차지 않게 한 줄로 알린다 (겁주지 않는 말투, 리뷰 10/30 #7)
          if (demo.todayEatenKcal > target)
            Muted('목표보다 ${formatNumber(demo.todayEatenKcal - target)} kcal 더 드셨어요. 내일 조금 가볍게 맞춰 봐요.', bottom: 0),
        ]),
      ),
      const H2('오늘 식단'),
      const _TodayMealRows(),
      const H2('오늘 운동'),
      _TodayWorkoutCard(today),
      const Disclaimer(),
    ]);
  }

  /// 선생님 전용 홈: 오늘 일지 쓸 회원과 이번 주 미션을 먼저 보여 준다 (결정 d1030-1)
  Widget _trainerHome() {
    return TabBody(children: [
      H1(demo.greeting),
      if (demo.activeMembers.isEmpty) ...[
        const Muted('연결된 회원이 없어요. 초대 코드를 만들어 보세요.'),
        AppButton('초대 코드 만들기', onPressed: () => demo.update(() => demo.tab = 3)),
      ] else ...[
      const H2('일지 쓸 회원', top: AppSpace.xs),
      for (final m in demo.activeMembers) MemberLogRow(m),
      const H2('이번 주 미션'),
      for (final m in demo.activeMembers)
        LineRow(
          // 누른 회원을 미리 골라 다른 회원의 미션을 바꾸지 않게 (리뷰 11/07 #6)
          onTap: () => demo.update(() {
            demo.missionMember = m;
            demo.tab = 3;
          }),
          // 화살표가 같은 줄에 서게 미션 글은 왼쪽 칸 안에서 오른쪽으로 붙인다
          left: Row(children: [
            Text(m, style: AppText.bodyStrong),
            const SizedBox(width: AppSpace.m),
            Expanded(child: Muted(demo.missions[m] ?? '아직 없어요', bottom: 0, align: TextAlign.right)),
          ]),
          showArrow: true,
        ),
      AppButton('회원 관리·초대 코드', kind: ButtonKind.soft, onPressed: () => demo.update(() => demo.tab = 3)),
      ],
    ]);
  }

  /// 게스트 홈: 기록·목표 대신 내 칼로리와 예시 식단·운동만 보여 준다.
  Widget _guestHome(BuildContext context, int target, WorkoutDay today) {
    return TabBody(children: [
      H1(demo.greeting),
      const GuestBanner('로그인하면 내 몸에 맞춘 식단·운동 루틴을 AI가 만들고, 연속 기록도 쌓을 수 있어요.'),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('내 칼로리', style: AppText.bodyStrong),
          const SizedBox(height: AppSpace.s),
          if (demo.calorieCalculated) ...[
            const Muted('하루에 쓰는 칼로리', bottom: AppSpace.xxs),
            BigNumber('${formatNumber(demo.tdee.tdee)} kcal'),
            const SizedBox(height: AppSpace.s),
            Muted('${demo.goal} 목표 칼로리', bottom: AppSpace.xxs),
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
            rightBelowOnLargeText: true,
            showArrow: true,
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
        showArrow: true,
        onTap: () => demo.update(() => demo.tab = 2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(today.title, style: AppText.bodyStrong),
          // 쉬는 날은 '0종목'이 아니라 쉬는 날 안내, '외'는 3개 이상일 때만 (리뷰 10/30 #4)
          if (today.isRest || today.items.isEmpty)
            const Muted('오늘은 쉬는 날이에요 · 가벼운 걷기 30분 추천', bottom: 0)
          else ...[
            Muted(
                '${today.items.length}종목 · ${today.items.take(2).map((e) => e.name).join(', ')}${today.items.length > 2 ? ' 외' : ''}',
                bottom: AppSpace.s),
            // 좁은 폰에서 줄이 넘어가도 그림끼리 붙지 않게
            Wrap(spacing: 6, runSpacing: 6, children: [for (final e in today.items) ExerciseThumb(e.name)]),
          ],
        ]),
      );
}
