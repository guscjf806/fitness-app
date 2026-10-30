import 'package:flutter/material.dart';

import '../config.dart';
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
    if (demo.isGuest) {
      return TabBody(children: [
        const H1('내 정보'),
        const Muted('게스트'),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('로그인하면 이런 걸 쓸 수 있어요', style: AppText.bodyStrong),
            const SizedBox(height: 6),
            const Text('· 내 몸에 맞춘 AI 식단·운동 루틴 (월 5회 무료)\n· 식단 사진 올리고 AI 답변 받기\n· 연속 기록, 배지, 운동 달력\n· 매일 알림, PT 운동일지'),
            AppButton('3초 만에 로그인하기', onPressed: () => Navigator.pushNamed(context, Routes.login)),
          ]),
        ),
        const _ConditionRows(),
        const Muted('게스트로 입력한 정보는 이 기기에만 저장돼요.', bottom: 0),
      ]);
    }
    return TabBody(children: [
      const H1('내 정보'),
      Muted(role == 'trainer'
          ? '선생님 계정'
          : role == 'member'
              ? 'PT 회원 · 담당 선생님 연결됨'
              : '일반 회원'),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('이번 달 AI 사용', style: AppText.bodyStrong)),
            Muted('${demo.quotaExhausted ? AppConfig.freeMonthlyAiLimit : demo.aiUsed} / ${AppConfig.freeMonthlyAiLimit}회', bottom: 0),
          ]),
          ProgressBar(demo.quotaExhausted ? 1 : demo.aiUsed / AppConfig.freeMonthlyAiLimit),
          AppButton('더 많이 쓰기',
              kind: ButtonKind.soft, top: 4, onPressed: () => Navigator.pushNamed(context, Routes.subscribe)),
        ]),
      ),
      const _ConditionRows(),
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
      // 알림을 끄면 시간도 고를 수 없게 회색으로 (디자인 리뷰 10/29 #5)
      LineRow(
        left: Text('알림 시간', style: TextStyle(color: demo.pushOn ? AppColors.text : AppColors.textSub)),
        right: TextButton(
          onPressed: !demo.pushOn
              ? null
              : () async {
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
        right: Muted('${demo.streak}일 · 프리즈 ${demo.freezesLeft}회', bottom: 0),
        showArrow: true,
        onTap: () => Navigator.pushNamed(context, Routes.records),
      ),
      if (role == 'user')
        LineRow(left: const Text('PT 코드 입력'), showArrow: true, onTap: () => Navigator.pushNamed(context, Routes.ptCode)),
      if (role == 'trainer')
        LineRow(left: const Text('회원 관리'), showArrow: true, onTap: () => demo.update(() => demo.tab = 3)),
      LineRow(left: const Text('구독'), showArrow: true, onTap: () => Navigator.pushNamed(context, Routes.subscribe)),
      // 위험한 줄은 실수로 누르지 않게 떼어서 맨 아래에 (디자인 리뷰 10/29 #6)
      const SizedBox(height: 24),
      LineRow(left: const Text('로그아웃'), onTap: () => demo.switchRole('guest')),
      LineRow(
        left: const Text('계정 삭제', style: TextStyle(color: AppColors.warning)),
        onTap: () => toast(context, '계정 삭제 확인 화면이 열려요 (데모)'),
      ),
    ]);
  }
}

/// 몸 정보·운동 조건·못 먹는 음식 수정 3줄. 게스트와 회원이 같이 쓴다 (디자인 리뷰 10/29 #1)
class _ConditionRows extends StatelessWidget {
  const _ConditionRows();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      LineRow(left: const Text('몸 정보 수정'), showArrow: true, onTap: () => Navigator.pushNamed(context, Routes.body)),
      LineRow(
        left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('운동 장소·장비 수정'),
          Muted(demo.conditionText, bottom: 0),
        ]),
        showArrow: true,
        onTap: () => Navigator.pushNamed(context, Routes.condition),
      ),
      LineRow(
        left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('못 먹는 음식·아픈 부위 수정'),
          Muted(
              [
                demo.allergies.isEmpty && demo.allergyNote.isEmpty ? '못 먹는 음식 없음' : '못 먹는 음식 ${demo.allergies.length + (demo.allergyNote.isEmpty ? 0 : 1)}개',
                demo.painAreas.isEmpty ? '아픈 부위 없음' : demo.painAreas.join(', '),
              ].join(' · '),
              bottom: 0),
        ]),
        showArrow: true,
        onTap: () => Navigator.pushNamed(context, Routes.condition2),
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
        style: AppText.number.copyWith(fontWeight: FontWeight.w400, letterSpacing: 4),
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
          Text('식단·운동 루틴 생성 횟수 확대'),
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
