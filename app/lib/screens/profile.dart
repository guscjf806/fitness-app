import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        const Muted('로그인 없이 둘러보는 중'),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('로그인하면 이런 걸 쓸 수 있어요', style: AppText.bodyStrong),
            const SizedBox(height: 6),
            const BulletList(['내 몸에 맞춘 AI 식단·운동 루틴 (월 5회 무료)', '식단 사진 올리고 AI 답변 받기', '연속 기록, 배지, 운동 달력', '매일 알림, PT 운동일지']),
            AppButton('3초 만에 로그인하기', onPressed: () => Navigator.pushNamed(context, Routes.login)),
          ]),
        ),
        const _ConditionRows(),
        const Muted('둘러보며 입력한 정보는 이 기기에만 저장돼요.', bottom: 0),
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
            Muted('${demo.aiUsedShown} / ${AppConfig.freeMonthlyAiLimit}회', bottom: 0),
          ]),
          ProgressBar(demo.aiUsedShown / AppConfig.freeMonthlyAiLimit),
          AppButton('더 많이 쓰기',
              kind: ButtonKind.soft, top: 4, onPressed: () => Navigator.pushNamed(context, Routes.subscribe)),
        ]),
      ),
      const _ConditionRows(),
      SwitchRow(
        title: '매일 알림',
        subtitle: '식단·운동 확인 리마인더',
        value: demo.pushOn,
        onChanged: (v) => demo.update(() => demo.pushOn = v),
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
      // 알림 스위치 값은 그대로 두고, 쉬는 동안 멈춘다는 것만 알린다 (리뷰 11/03 #4)
      if (demo.restMode && demo.pushOn)
        const Padding(
          padding: EdgeInsets.only(top: AppSpace.s),
          child: Muted('쉬기 모드 중이라 알림이 잠시 멈췄어요', bottom: 0),
        ),
      const RestModeSwitch(),
      LineRow(
        left: const Text('연속 기록 · 배지'),
        right: Muted('${demo.streak}일 · 기록 지키기권 ${demo.freezesLeft}회', bottom: 0),
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
      // 잘못 눌러 다시 로그인하는 일이 없게 한 번 묻는다 (리뷰 11/03 #2)
      LineRow(
        left: const Text('로그아웃'),
        onTap: () async {
          final ok = await confirmDialog(context,
              title: '로그아웃할까요?',
              body: '다시 쓰려면 카카오·구글·애플로 로그인해야 해요. 기록은 계정에 그대로 남아 있어요.',
              keepLabel: '그만두기',
              okLabel: '로그아웃');
          if (ok) demo.switchRole('guest');
        },
      ),
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
      // 진짜 코드처럼 보이는 예시 대신 '숫자 6자리', 붙여 넣은 공백·하이픈은 빼고 숫자만 남긴다 (리뷰 11/03 #7)
      TextField(
        maxLength: 6,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: AppText.number.copyWith(fontWeight: FontWeight.w400, letterSpacing: 4),
        decoration: const InputDecoration(hintText: '숫자 6자리', counterText: ''),
        onChanged: (v) => setState(() => code = v),
      ),
      // 6자리가 되기 전에는 버튼을 흐리게
      AppButton('연결하기', onPressed: code.length < 6 ? null : () {
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
      // 무제한으로 오해하지 않게 '더 많이', 몇 회로 느는지와 자동 연장·해지를 함께 알린다 (리뷰 11/03 #6)
      const H1('AI를 더 많이 쓰세요'),
      const AppCard(child: BulletList(['식단·운동 루틴 생성 횟수 확대', 'AI 식단 답변 횟수 확대', '기록 지키기권 추가'])),
      Muted('무료는 AI를 한 달에 ${AppConfig.freeMonthlyAiLimit}회 쓸 수 있어요. 구독하면 몇 회로 늘어나는지는 출시 전에 정해요.',
          bottom: AppSpace.m),
      Seg(options: const ['월', '연'], value: bill, onChanged: (v) => setState(() => bill = v)),
      BigNumber(bill == '월' ? '월 ${formatNumber(AppConfig.monthlyPrice)}원' : '연 ${formatNumber(AppConfig.yearlyPrice)}원'),
      if (bill == '연') Muted('월 약 ${formatNumber((AppConfig.yearlyPrice / 12 / 100).round() * 100)}원꼴이에요', bottom: 2),
      const Muted('예시 가격이에요. 실제 가격은 출시 전에 정해요.'),
      AppButton('구독하기', onPressed: () => toast(context, '실제 앱에서는 앱스토어 결제 창이 열려요 (데모)')),
      const Padding(
        padding: EdgeInsets.only(top: AppSpace.s),
        child: Muted('기간이 끝나면 자동으로 연장돼요 · 앱스토어에서 언제든 해지할 수 있어요', align: TextAlign.center),
      ),
    ]);
  }
}
