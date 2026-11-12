import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/failure.dart';

/// S04 TDEE 결과
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = demo.tdee;
    demo.calorieCalculated = true;
    final hasMuscle = !demo.muscleUnknown && (double.tryParse(demo.muscle) ?? 0) > 0;
    return AppPage(title: '내 칼로리', children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('하루에 쓰는 칼로리', bottom: AppSpace.xxs),
          BigNumber('${formatNumber(r.tdee)} kcal'),
          if (hasMuscle) const Muted('근육량은 AI가 식단·운동 루틴을 짤 때 참고해요', bottom: 0),
          // 영어 공식 이름은 궁금한 사람만 펼쳐 보게 접어 둔다 (리뷰 10/29 #4)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text('어떻게 계산했나요?', style: AppText.body.copyWith(color: AppColors.primaryDark)),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Muted(
                  '가만히 있어도 쓰는 칼로리(기초대사량) ${formatNumber(r.bmr)} kcal에 '
                  '지금 운동 강도(${demo.currentIntensity})를 곱했어요.\n'
                  '${r.usedKatchMcArdle ? '체지방량을 반영한 Katch-McArdle 공식' : '키·나이·몸무게로 계산하는 Mifflin-St Jeor 공식'}을 썼어요.',
                  bottom: 0,
                ),
              ],
            ),
          ),
        ]),
      ),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Muted('${demo.goal} 목표 칼로리', bottom: AppSpace.xxs),
          BigNumber('${formatNumber(r.target)} kcal'),
          if (r.teen && demo.goal == '감량')
            const Muted('성장기라 감량 폭을 줄여서(−10%) 계산했어요.', bottom: 0),
          if (r.clampedToFloor) WarningBox('너무 낮은 칼로리는 위험해서 최소 ${formatNumber(r.floor)} kcal로 맞췄어요.', top: AppSpace.s),
        ]),
      ),
      const Disclaimer(text: '의료 조언이 아닙니다. 건강 상태에 따라 전문가와 상의하세요.'),
      AppButton('식단·운동 루틴 만들기', onPressed: () => openPlanMaker(context)),
      if (!demo.loggedIn)
        const Muted('만들려면 로그인이 필요해요.', top: AppSpace.s, align: TextAlign.center),
    ]);
  }
}

/// '식단·운동 루틴 만들기': 로그인했으면 기간 선택(S06)으로, 아니면 로그인 안내 후 S06으로 이어진다.
void openPlanMaker(BuildContext context) {
  // 로그인만 하고 동의를 안 했으면 동의 화면부터 (리뷰 10/29 #1)
  if (demo.loggedIn && !demo.consented) {
    demo.update(() => demo.continueToGenerate = true);
    Navigator.pushNamed(context, Routes.consent);
  // 못 먹는 음식·아픈 부위가 바뀐 뒤 새로 만드는 건 안전 문제라 횟수를 따지지 않는다 (리뷰 11/12 #5, 결정 d1107-1)
  } else if (demo.loggedIn && demo.quotaExhausted && !demo.planOutdated) {
    showQuotaExhausted(context);
  } else if (demo.loggedIn) {
    Navigator.pushNamed(context, Routes.generate);
  } else {
    requireLogin(context, 'AI가 내 몸에 맞춘 식단·운동 루틴을 만들려면 로그인이 필요해요. 로그인하면 바로 이어서 만들 수 있어요.',
        thenGenerate: true);
  }
}
