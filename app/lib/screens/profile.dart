import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// S15 내 정보
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final role = demo.role;
    Widget arrow([String text = '›']) => Muted(text, bottom: 0);
    return TabBody(children: [
      const H1('내 정보'),
      Muted(role == 'trainer'
          ? '선생님 계정'
          : role == 'member'
              ? 'PT 회원 · 담당 선생님 연결됨'
              : '일반 회원'),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Expanded(child: Text('이번 달 AI 사용', style: TextStyle(fontWeight: FontWeight.w700))),
            Muted('2 / 5회', bottom: 0),
          ]),
          const ProgressBar(0.4),
          AppButton('더 많이 쓰기',
              kind: ButtonKind.soft, top: 4, onPressed: () => Navigator.pushNamed(context, Routes.subscribe)),
        ]),
      ),
      LineRow(left: const Text('몸 정보 수정'), right: arrow(), onTap: () => Navigator.pushNamed(context, Routes.body)),
      LineRow(
        left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('운동 장소·장비 수정'),
          Muted(demo.conditionText, bottom: 0),
        ]),
        right: arrow(),
        onTap: () => Navigator.pushNamed(context, Routes.condition),
      ),
      LineRow(
        left: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('매일 알림'),
          Muted('식단·운동 확인 리마인더', bottom: 0),
        ]),
        right: Switch(
          value: demo.pushOn,
          activeTrackColor: AppColors.primary,
          onChanged: (v) => demo.update(() => demo.pushOn = v),
        ),
      ),
      LineRow(
        left: const Text('알림 시간'),
        right: TextButton(
          onPressed: () async {
            final picked = await showTimePicker(context: context, initialTime: demo.pushTime);
            if (picked != null) demo.update(() => demo.pushTime = picked);
          },
          child: Text(demo.pushTime.format(context)),
        ),
      ),
      LineRow(
        left: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('쉬기 모드'),
          Muted('아프거나 다칠 때 켜면 연속 기록이 유지돼요', bottom: 0),
        ]),
        right: Switch(
          value: demo.restMode,
          activeTrackColor: AppColors.primary,
          onChanged: (v) => demo.update(() => demo.restMode = v),
        ),
      ),
      LineRow(
        left: const Text('연속 기록 · 배지'),
        right: arrow('${demo.streak}일 · 프리즈 ${demo.freezesLeft}회 ›'),
        onTap: () => Navigator.pushNamed(context, Routes.records),
      ),
      if (role == 'user')
        LineRow(left: const Text('PT 코드 입력'), right: arrow(), onTap: () => Navigator.pushNamed(context, Routes.ptCode)),
      if (role == 'trainer')
        LineRow(left: const Text('회원 관리'), right: arrow(), onTap: () => demo.update(() => demo.tab = 3)),
      LineRow(left: const Text('구독'), right: arrow(), onTap: () => Navigator.pushNamed(context, Routes.subscribe)),
      LineRow(left: const Text('로그아웃'), onTap: () => demo.switchRole('guest')),
      LineRow(
        left: const Text('계정 삭제', style: TextStyle(color: AppColors.warning)),
        onTap: () => toast(context, '계정 삭제 확인 화면이 열려요 (데모)'),
      ),
    ]);
  }
}

/// S16 PT 코드 입력
class PtCodeScreen extends StatefulWidget {
  const PtCodeScreen({super.key});

  @override
  State<PtCodeScreen> createState() => _PtCodeScreenState();
}

class _PtCodeScreenState extends State<PtCodeScreen> {
  String code = '';

  @override
  Widget build(BuildContext context) {
    return AppPage(title: 'PT 코드 입력', children: [
      const Muted('선생님께 받은 6자리 코드를 입력하면 운동일지가 열려요.'),
      TextField(
        maxLength: 6,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, letterSpacing: 4),
        decoration: const InputDecoration(hintText: '예: 482915', counterText: ''),
        onChanged: (v) => code = v,
      ),
      AppButton('연결하기', onPressed: () {
        if (code.length < 6) {
          toast(context, '6자리 코드를 입력해 주세요');
          return;
        }
        demo.update(() {
          demo.role = 'member';
          demo.tab = 3;
        });
        Navigator.pushNamedAndRemoveUntil(context, Routes.main, (_) => false);
        toast(context, 'PT 회원으로 연결됐어요. 운동일지가 열렸어요');
      }),
    ]);
  }
}

/// S17 구독
class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  String bill = '연';

  @override
  Widget build(BuildContext context) {
    return AppPage(title: '구독', children: [
      const H1('AI를 마음껏 쓰세요'),
      const AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('식단·루틴 생성 횟수 확대'),
          Text('AI 식단 답변 횟수 확대'),
          Text('스트릭 프리즈 추가'),
        ]),
      ),
      Seg(options: const ['월', '연'], value: bill, onChanged: (v) => setState(() => bill = v)),
      BigNumber(bill == '월' ? '월 9,900원' : '연 79,000원'),
      const Muted('예시 가격이에요. 실제 가격은 출시 전에 정해요.'),
      AppButton('구독하기', onPressed: () => toast(context, '실제 앱에서는 앱스토어 결제 창이 열려요 (데모)')),
    ]);
  }
}
