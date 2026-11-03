import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// S01 시작
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(children: [
      const SizedBox(height: 28),
      Text(keepWords('내 몸에 맞춘 식단과 운동, AI가 짜드려요'),
          semanticsLabel: '내 몸에 맞춘 식단과 운동, AI가 짜드려요', style: AppText.display),
      const SizedBox(height: 8),
      const Muted('몸 정보로 하루에 쓰는 칼로리를 계산하고, 일주일 또는 한 달치 식단과 운동 루틴을 만들어요.'),
      const SizedBox(height: 10),
      const AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('식단과 운동 루틴을 한 번에 생성'),
          Text('올린 식단에 AI가 답변'),
          Text('PT 회원님은 운동일지까지'),
        ]),
      ),
      AppButton('내 칼로리 계산하기',
          onPressed: () => Navigator.pushNamed(context, Routes.body)),
      AppButton('로그인',
          kind: ButtonKind.soft,
          onPressed: () => Navigator.pushNamed(context, Routes.login)),
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: TextButton(
          onPressed: () {
            demo.update(() {
              demo.tab = 0;
              demo.entered = true;
            });
            Navigator.pushNamedAndRemoveUntil(context, Routes.main, (_) => false);
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.textSub),
          child: const Text('로그인 없이 둘러보기'), // 50대 이상에게 낯선 '게스트' 대신 (리뷰 10/29 #7)
        ),
      ),
      const Muted('로그인 없이 예시 식단·운동 루틴과 칼로리 계산을 써 볼 수 있어요.', align: TextAlign.center),
    ]);
  }
}
