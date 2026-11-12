import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'logbook.dart';
import 'onboarding/result.dart';

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
            const SizedBox(height: AppSpace.xsPlus),
            const BulletList(['내 몸에 맞춘 AI 식단·운동 루틴 (월 5회 무료)', '식단 사진 올리고 AI 답변 받기', '연속 기록, 배지, 운동 달력', '매일 알림, PT 운동일지']),
            AppButton('로그인하기', onPressed: () => Navigator.pushNamed(context, Routes.login)),
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
      // 선생님 계정에는 회원용 항목을 숨기고 회원 관리·초대 코드·알림만 (결정 d1103-4)
      if (role != 'trainer') ...[
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('이번 달 AI 사용', style: AppText.bodyStrong)),
            Muted('${demo.aiUsedShown} / ${AppConfig.freeMonthlyAiLimit}회', bottom: 0),
          ]),
          ProgressBar(demo.aiUsedShown / AppConfig.freeMonthlyAiLimit),
          AppButton('더 많이 쓰기',
              kind: ButtonKind.soft, top: AppSpace.xs, onPressed: () => Navigator.pushNamed(context, Routes.subscribe)),
        ]),
      ),
      // 묶음 제목으로 나눠 찾기 쉽게 (결정 dd1029-profile-head)
      const H2('내 몸·조건'),
      const _ConditionRows(),
      // 로그인한 회원 화면에 둔다. 둘러보기는 위 로그인 카드가 같은 역할 (디자인 리뷰 11/12 #1)
      // 조건을 고친 뒤 '나중에'를 눌렀거나 횟수를 다 썼을 때 다시 만들 곳 (리뷰 11/11 #2)
      LineRow(
        left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const WordText('식단·루틴 새로 만들기'),
          Muted('이번 달 AI ${demo.aiUsedShown} / ${AppConfig.freeMonthlyAiLimit}회 사용', bottom: 0),
        ]),
        showArrow: true,
        onTap: () => openPlanMaker(context),
      ),
      ],
      const H2('알림'),
      SwitchRow(
        title: '매일 알림',
        subtitle: '식단·운동 확인 리마인더',
        value: demo.pushOn,
        onChanged: (v) => demo.update(() => demo.pushOn = v),
      ),
      // 알림을 끄면 시간도 고를 수 없게 회색으로 (디자인 리뷰 10/29 #5)
      // 줄 전체를 누르게 하고, 시간 글자 끝을 위아래 스위치와 맞춘다 (디자인 리뷰 11/11 #5)
      LineRow(
        onTap: !demo.pushOn
            ? null
            : () async {
                final picked = await showTimePicker(context: context, initialTime: demo.pushTime);
                if (picked != null) demo.update(() => demo.pushTime = picked);
              },
        left: Text('알림 시간', style: TextStyle(color: demo.pushOn ? AppColors.text : AppColors.textSub)),
        right: Text(demo.pushTime.format(context),
            style: AppText.bodyStrong.copyWith(color: demo.pushOn ? AppColors.primaryDark : AppColors.textSub)),
      ),
      if (role != 'trainer')
        SwitchRow(
          title: '휴식 끝 알림음',
          subtitle: '휴식이 끝나면 진동과 함께 짧은 소리로 알려요',
          value: demo.restSound,
          onChanged: (v) => demo.update(() => demo.restSound = v),
        ),
      // 알림 스위치 값은 그대로 두고, 쉬는 동안 멈춘다는 것만 알린다 (리뷰 11/03 #4)
      if (role != 'trainer' && demo.restMode && demo.pushOn)
        const Muted('쉬기 모드 중이라 알림이 잠시 멈췄어요', top: AppSpace.s, bottom: 0),
      if (role != 'trainer') ...[
      const H2('기록'),
      const RestModeSwitch(),
      LineRow(
        left: const Text('연속 기록 · 배지'),
        right: Muted('${demo.streak}일 · 기록 지키기권 ${demo.freezesLeft}회', bottom: 0),
        showArrow: true,
        onTap: () => Navigator.pushNamed(context, Routes.records),
      ),
      ],
      const H2('계정'),
      if (role == 'user')
        LineRow(left: const Text('PT 코드 입력'), showArrow: true, onTap: () => Navigator.pushNamed(context, Routes.ptCode)),
      // 회원도 끊을 수 있고 선생님께 알린다 (결정 d1104-2). 받은 일지는 남는다 (결정 d1104-1)
      if (role == 'member')
        LineRow(
          left: const Text('선생님과 연결 끊기'),
          showArrow: true,
          onTap: () async {
            final ok = await confirmDialog(context,
                title: '선생님과 연결을 끊을까요?',
                body: '받은 일지와 영상은 계속 볼 수 있어요. 선생님은 더 이상 내 일지를 볼 수 없고, 선생님께 알림이 가요. 다시 이으려면 선생님께 새 PT 코드를 받아야 해요.',
                keepLabel: '그대로 두기',
                okLabel: '연결 끊기',
                danger: true);
            if (!ok || !context.mounted) return;
            demo.update(() {
              demo.role = 'user';
              demo.ptEnded = true;
            });
            toast(context, '선생님과 연결을 끊고 알렸어요');
          },
        ),
      if (role == 'trainer')
        LineRow(left: const Text('회원 관리·초대 코드'), showArrow: true, onTap: () => demo.update(() => demo.tab = 3)),
      if (role != 'trainer')
        LineRow(left: const Text('구독'), showArrow: true, onTap: () => Navigator.pushNamed(context, Routes.subscribe)),
      // 위험한 줄은 실수로 누르지 않게 떼어서 맨 아래에 (디자인 리뷰 10/29 #6)
      const SizedBox(height: AppSpace.m),
      // 잘못 눌러 다시 로그인하는 일이 없게 한 번 묻는다 (리뷰 11/03 #2)
      LineRow(
        left: const Text('로그아웃'),
        onTap: () async {
          final ok = await confirmDialog(context,
              title: '로그아웃할까요?',
              body: '다시 쓰려면 카카오·구글·애플로 로그인해야 해요. 기록은 계정에 그대로 남아 있어요.',
              keepLabel: '그만두기',
              okLabel: '로그아웃');
          if (ok) {
            clearLogDrafts();
            demo.logout();
          }
        },
      ),
      LineRow(
        left: const Text('계정 삭제', style: TextStyle(color: AppColors.warningText)),
        // 스토어 심사에 필요한 앱 안 계정 삭제. 무엇이 지워지는지 먼저 알린다 (리뷰 11/11 #5)
        onTap: () async {
          final ok = await confirmDialog(context,
              title: '계정을 지울까요?',
              body: '로그인 계정(카카오·구글 고유번호, 닉네임, 이메일)과 이 폰에 저장된 정보가 지워지고, 되돌릴 수 없어요.',
              keepLabel: '그만두기',
              okLabel: '지우기',
              danger: true);
          if (!ok || !context.mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          if (!await AuthService.deleteAccount()) {
            toastOn(messenger, '계정을 지우지 못했어요. 인터넷 연결을 확인하고 다시 시도해 주세요');
            return;
          }
          clearLogDrafts();
          demo.logout();
          toastOn(messenger, AuthService.enabled ? '계정을 지웠어요' : '계정을 지웠어요 (데모)');
        },
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
      // 큰 글씨에서 낱자가 다음 줄로 넘어가지 않게 (디자인 리뷰 11/11 #1)
      LineRow(left: const WordText('몸 정보 수정'), showArrow: true, onTap: () => Navigator.pushNamed(context, Routes.body, arguments: 'edit')),
      LineRow(
        left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const WordText('운동 장소·장비 수정'),
          Muted(demo.conditionText, bottom: 0),
        ]),
        showArrow: true,
        onTap: () => Navigator.pushNamed(context, Routes.condition, arguments: 'edit'),
      ),
      LineRow(
        left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const WordText('못 먹는 음식·아픈 부위 수정'),
          Muted(
              [
                demo.allergies.isEmpty && demo.allergyNote.isEmpty ? '못 먹는 음식 없음' : '못 먹는 음식 ${demo.allergies.length + (demo.allergyNote.isEmpty ? 0 : 1)}개',
                demo.painAreas.isEmpty ? '아픈 부위 없음' : demo.painAreas.join(', '),
              ].join(' · '),
              bottom: 0),
        ]),
        showArrow: true,
        onTap: () => Navigator.pushNamed(context, Routes.condition2, arguments: 'edit'),
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

  /// 코드가 안 맞을 때 이유별 안내. 코드는 지우지 않아 고쳐 쓸 수 있다 (리뷰 11/04 #6)
  /// 목업에서는 데모 바의 '상황'으로 미리 본다
  static const _codeErrors = {
    '코드 틀림': '코드가 맞지 않아요. 선생님께 다시 확인해 주세요',
    '코드 만료': '기간이 지난 코드예요. 선생님께 새 코드를 받아 주세요',
    '코드 사용됨': '이미 쓴 코드예요. 코드는 한 번만 쓸 수 있어요. 선생님께 새 코드를 받아 주세요',
  };
  String? error;

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
        decoration: InputDecoration(
          hintText: '숫자 6자리',
          counterText: '',
          errorText: error,
          // 안내가 놓치면 안 되는 내용이라 글씨만 본문 크기로
          errorStyle: AppText.body.copyWith(color: AppColors.warningText),
        ),
        onChanged: (v) => setState(() {
          code = v;
          error = null;
        }),
      ),
      // 6자리가 되기 전에는 버튼을 흐리게
      AppButton('연결하기', onPressed: code.length < 6 ? null : () {
        final problem = _codeErrors[demo.failMode];
        if (problem != null) {
          setState(() => error = problem);
          return;
        }
        demo.update(() {
          demo.role = 'member';
          demo.ptEnded = false;
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
  /// 처음엔 월 요금, 연 요금 칸에 얼마나 저렴한지 표시 (결정 d1103-3)
  String bill = '월';
  static final _yearLabel = '연 ${((1 - AppConfig.yearlyPrice / (AppConfig.monthlyPrice * 12)) * 100).floor()}% 저렴';

  @override
  Widget build(BuildContext context) {
    return AppPage(title: '구독', children: [
      // 무제한으로 오해하지 않게 '더 많이', 몇 회로 느는지와 자동 연장·해지를 함께 알린다 (리뷰 11/03 #6)
      const H1('AI를 더 많이 쓰세요'),
      const AppCard(child: BulletList(['식단·운동 루틴 생성 횟수 확대', 'AI 식단 답변 횟수 확대', '기록 지키기권 추가'])),
      Muted('무료는 AI를 한 달에 ${AppConfig.freeMonthlyAiLimit}회 쓸 수 있어요. 구독하면 몇 회로 늘어나는지는 출시 전에 정해요.',
          bottom: AppSpace.m),
      Seg(options: ['월', _yearLabel], value: bill, onChanged: (v) => setState(() => bill = v)),
      BigNumber(bill == '월' ? '월 ${formatNumber(AppConfig.monthlyPrice)}원' : '연 ${formatNumber(AppConfig.yearlyPrice)}원'),
      // 가격 판단에 중요한 월 환산은 회색 안내와 구분되게 굵은 주황 글씨로 (디자인 리뷰 11/03 #3)
      if (bill != '월')
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.xs),
          child: Text('월 약 ${formatNumber((AppConfig.yearlyPrice / 12 / 100).round() * 100)}원꼴이에요',
              style: AppText.bodyStrong.copyWith(color: AppColors.primary)),
        ),
      AppButton('구독하기', onPressed: () => toast(context, '실제 앱에서는 앱스토어 결제 창이 열려요 (데모)')),
      const Muted('기간이 끝나면 자동으로 연장돼요 · 앱스토어에서 언제든 해지할 수 있어요', top: AppSpace.s),
      // 목업 표시는 로그인 화면처럼 맨 아래 안내(Disclaimer)로
      const Disclaimer(text: '예시 가격이에요. 실제 가격은 출시 전에 정해요.'),
    ]);
  }
}
