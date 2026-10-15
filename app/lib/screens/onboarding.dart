import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// S01 시작
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(children: [
      const SizedBox(height: 28),
      const Text('내 몸에 맞춘 식단과 운동, AI가 짜드려요',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.3)),
      const SizedBox(height: 8),
      const Muted('몸 정보로 하루 소비 칼로리(TDEE)를 계산하고, 일주일 또는 한 달치 식단과 운동 루틴을 만들어요.'),
      const SizedBox(height: 10),
      const AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('식단과 루틴을 한 번에 생성'),
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
            demo.update(() => demo.tab = 0);
            Navigator.pushNamedAndRemoveUntil(context, Routes.main, (_) => false);
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.textSub, minimumSize: const Size.fromHeight(44)),
          child: const Text('게스트로 시작하기'),
        ),
      ),
      const Muted('로그인 없이 예시 식단·루틴과 칼로리 계산을 써 볼 수 있어요.', align: TextAlign.center),
    ]);
  }
}

/// S02 몸 정보 입력
class BodyInfoScreen extends StatelessWidget {
  const BodyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(title: '몸 정보', children: [
      const Muted('성별', bottom: 0),
      Seg(options: const ['남', '여'], value: demo.sex, onChanged: (v) => demo.update(() => demo.sex = v)),
      Row(children: [
        Expanded(child: NumField(label: '키 (cm)', value: demo.height, onChanged: (v) => demo.height = v)),
        const SizedBox(width: 8),
        Expanded(child: NumField(label: '나이', value: demo.age, onChanged: (v) => demo.age = v)),
        const SizedBox(width: 8),
        Expanded(child: NumField(label: '몸무게 (kg)', value: demo.weight, onChanged: (v) => demo.weight = v)),
      ]),
      const SizedBox(height: 12),
      _OptionalField(
        label: '근육량 (kg, 선택)',
        value: demo.muscle,
        unknown: demo.muscleUnknown,
        onChanged: (v) => demo.muscle = v,
        onUnknown: () => demo.update(() => demo.muscleUnknown = !demo.muscleUnknown),
      ),
      _OptionalField(
        label: '체지방량 (kg, 선택)',
        value: demo.bodyFat,
        unknown: demo.bodyFatUnknown,
        onChanged: (v) => demo.bodyFat = v,
        onUnknown: () => demo.update(() => demo.bodyFatUnknown = !demo.bodyFatUnknown),
      ),
      const Muted("체지방량을 알면 더 정확한 공식으로 계산해요. 모르면 '잘 모르겠음'을 눌러 주세요."),
      const Muted('목표', bottom: 0),
      Seg(options: const ['감량', '유지', '증량'], value: demo.goal, onChanged: (v) => demo.update(() => demo.goal = v)),
      AppButton('다음', onPressed: () => Navigator.pushNamed(context, Routes.condition)),
    ]);
  }
}

class _OptionalField extends StatelessWidget {
  const _OptionalField({required this.label, required this.value, required this.unknown, required this.onChanged, required this.onUnknown});
  final String label;
  final String value;
  final bool unknown;
  final ValueChanged<String> onChanged;
  final VoidCallback onUnknown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(
          child: NumField(
              key: ValueKey('$label$unknown'),
              label: label,
              value: unknown ? '' : value,
              enabled: !unknown,
              onChanged: onChanged),
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('잘 모르겠음'),
          selected: unknown,
          selectedColor: AppColors.primarySoft,
          onSelected: (_) => onUnknown(),
        ),
      ]),
    );
  }
}

/// S03 운동 강도·조건 선택
class ConditionScreen extends StatelessWidget {
  const ConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget title(String t, [String? sub]) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (sub != null) Muted(sub, bottom: 0),
          ]),
        );
    return AppPage(title: '운동 강도와 조건', children: [
      title('지금 하고 있는 강도', '칼로리 계산에 쓰여요'),
      Seg(options: const ['하', '중', '상'], value: demo.currentIntensity, onChanged: (v) => demo.update(() => demo.currentIntensity = v)),
      title('앞으로 원하는 강도', '운동 루틴의 세기에 쓰여요'),
      Seg(options: const ['하', '중', '상'], value: demo.desiredIntensity, onChanged: (v) => demo.update(() => demo.desiredIntensity = v)),
      const AppCard(child: Muted('하: 주 1~3회 가볍게 · 중: 주 3~5회 · 상: 주 6회 이상 또는 고강도', bottom: 0)),
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
      AppButton('결과 보기', onPressed: () => Navigator.pushNamed(context, Routes.result)),
    ]);
  }
}

/// S04 TDEE 결과
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = demo.tdee;
    final hasMuscle = !demo.muscleUnknown && (double.tryParse(demo.muscle) ?? 0) > 0;
    return AppPage(title: '내 칼로리', children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('하루 소비 칼로리 (TDEE)', bottom: 2),
          BigNumber('${formatNumber(r.tdee)} kcal'),
          Muted(
            '기초대사량 ${formatNumber(r.bmr)} + 활동량(${demo.currentIntensity}) 반영\n'
            '${r.usedKatchMcArdle ? '체지방량을 반영한 공식(Katch-McArdle)으로 계산했어요' : '표준 공식(Mifflin-St Jeor)으로 계산했어요'}'
            '${hasMuscle ? '\n근육량은 AI가 식단·루틴을 짤 때 참고해요' : ''}',
            bottom: 0,
          ),
        ]),
      ),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Muted('${demo.goal} 목표 칼로리', bottom: 2),
          BigNumber('${formatNumber(r.target)} kcal'),
          if (r.clampedToFloor)
            Text('너무 낮은 칼로리는 위험해서 최소 ${formatNumber(r.floor)}kcal로 맞췄어요.',
                style: const TextStyle(color: AppColors.warning, fontSize: 13)),
        ]),
      ),
      const Muted('의료 조언이 아닙니다. 건강 상태에 따라 전문가와 상의하세요.'),
      AppButton('식단·루틴 만들기', onPressed: () {
        if (demo.loggedIn) {
          Navigator.pushNamed(context, Routes.generate);
        } else {
          demo.continueToGenerate = true;
          Navigator.pushNamed(context, Routes.login);
        }
      }),
      if (!demo.loggedIn)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Muted('만들려면 로그인이 필요해요', align: TextAlign.center),
        ),
    ]);
  }
}

/// S05 로그인
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _login(BuildContext context) {
    demo.update(() => demo.role = 'user');
    if (demo.continueToGenerate) {
      demo.continueToGenerate = false;
      Navigator.pushReplacementNamed(context, Routes.generate);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, Routes.main, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget social(String label, Color bg, Color fg, {bool outlined = false}) =>
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FilledButton(
            onPressed: () => _login(context),
            style: FilledButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              side: outlined ? const BorderSide(color: Color(0xFFD5DCDA)) : null,
            ),
            child: Text(label),
          ),
        );
    return AppPage(title: '로그인', children: [
      const H1('3초 만에 시작해요'),
      const Muted('로그인하면 식단·루틴 생성, 식단 올리기를 쓸 수 있어요.'),
      social('카카오로 시작하기', AppColors.kakao, AppColors.kakaoText),
      social('구글로 시작하기', Colors.white, const Color(0xFF222222), outlined: true),
      social('Apple로 시작하기', Colors.black, Colors.white),
      const Disclaimer(text: '목업이라 실제 로그인은 하지 않아요. 누르면 일반 회원으로 들어가요.'),
    ]);
  }
}

/// S06 기간 선택·생성
class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  bool generating = false;

  Future<void> _generate() async {
    setState(() => generating = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    demo.update(() => demo.tab = 0);
    navigator.pushNamedAndRemoveUntil(Routes.main, (_) => false);
    messenger.showSnackBar(SnackBar(content: Text('${demo.period}치 식단과 루틴을 만들었어요')));
  }

  @override
  Widget build(BuildContext context) {
    if (generating) {
      return const Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('AI가 식단과 루틴을 만들고 있어요', style: TextStyle(fontWeight: FontWeight.w700)),
            Muted('잠시만 기다려 주세요'),
          ]),
        ),
      );
    }
    final r = demo.tdee;
    return AppPage(title: '기간 선택', children: [
      const Muted('식단과 운동 루틴을 얼마 동안 만들까요?'),
      Seg(options: const ['일주일', '한 달'], value: demo.period, onChanged: (v) => demo.update(() => demo.period = v)),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('반영되는 정보', bottom: 2),
          Text('목표 칼로리 ${formatNumber(r.target)} kcal · 현재 강도 ${demo.currentIntensity} · '
              '원하는 강도 ${demo.desiredIntensity} · ${demo.conditionText}'),
        ]),
      ),
      AppButton('식단·루틴 생성하기', onPressed: _generate),
    ]);
  }
}
