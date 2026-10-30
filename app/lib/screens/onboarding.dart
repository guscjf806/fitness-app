import 'package:flutter/material.dart';

import '../logic/tdee.dart';
import '../routes.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/failure.dart';

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

/// S02 몸 정보 입력
class BodyInfoScreen extends StatefulWidget {
  const BodyInfoScreen({super.key});

  @override
  State<BodyInfoScreen> createState() => _BodyInfoScreenState();
}

class _BodyInfoScreenState extends State<BodyInfoScreen> {
  /// [다음]을 한 번 누른 뒤부터 칸 아래에 안내를 보여 준다
  bool tried = false;

  Map<String, String> _check() => validateBody(
      height: demo.height,
      age: demo.age,
      weight: demo.weight,
      muscle: demo.muscleUnknown ? '' : demo.muscle,
      bodyFat: demo.bodyFatUnknown ? '' : demo.bodyFat);

  void _next() {
    final errors = _check();
    if (errors.isNotEmpty) {
      setState(() => tried = true);
      toast(context, errors['age'] == underAgeError ? '$underAgeError.' : '입력한 값을 확인해 주세요.');
      return;
    }
    demo.update(() {}); // 입력한 숫자를 기기에 저장
    Navigator.pushNamed(context, Routes.condition);
  }

  @override
  Widget build(BuildContext context) {
    final errors = tried ? _check() : const <String, String>{};
    final teen = (int.tryParse(demo.age) ?? 99) >= minAge && (int.tryParse(demo.age) ?? 99) <= teenMaxAge;
    return AppPage(title: '몸 정보', children: [
      const Muted('성별', bottom: 0),
      Seg(options: const ['남', '여'], value: demo.sex, onChanged: (v) => demo.update(() => demo.sex = v)),
      // 폰에서 라벨이 잘리지 않게 한 줄에 한 칸씩 (리뷰 10/29 #2)
      NumField(label: '키 (cm)', value: demo.height, error: errors['height'], onChanged: (v) => demo.update(() => demo.height = v)),
      const SizedBox(height: 12),
      NumField(label: '나이 (만)', value: demo.age, error: errors['age'], onChanged: (v) => demo.update(() => demo.age = v)),
      const SizedBox(height: 12),
      NumField(label: '몸무게 (kg)', value: demo.weight, error: errors['weight'], onChanged: (v) => demo.update(() => demo.weight = v)),
      // 놓치면 안 되는 안내는 큰 경고 상자로 (리뷰 10/29 #6)
      if (errors['age'] == underAgeError)
        const WarningBox('만 14세 미만은 보호자 동의 절차가 필요해서 지금은 이용할 수 없어요.'),
      const SizedBox(height: 12),
      _OptionalField(
        label: '근육량 (kg, 선택)',
        value: demo.muscle,
        unknown: demo.muscleUnknown,
        error: errors['muscle'],
        onChanged: (v) => demo.update(() => demo.muscle = v),
        onUnknown: () => demo.update(() => demo.muscleUnknown = !demo.muscleUnknown),
      ),
      _OptionalField(
        label: '체지방량 (kg, 선택)',
        value: demo.bodyFat,
        unknown: demo.bodyFatUnknown,
        error: errors['bodyFat'],
        onChanged: (v) => demo.update(() => demo.bodyFat = v),
        onUnknown: () => demo.update(() => demo.bodyFatUnknown = !demo.bodyFatUnknown),
      ),
      const Muted("체지방량을 알면 더 정확한 공식으로 계산해요. 모르면 '잘 모르겠음'을 눌러 주세요."),
      const Muted('목표', bottom: 0),
      Seg(options: const ['감량', '유지', '증량'], value: demo.goal, onChanged: (v) => demo.update(() => demo.goal = v)),
      if (teen && demo.goal == '감량')
        const AppCard(
          accent: true,
          child: Text('성장기에는 키가 크는 데도 에너지가 필요해요. 그래서 감량 폭을 줄여서 계산해요. '
              '보호자나 전문가와 상의하며 천천히 관리하는 걸 권해요.'),
        ),
      AppButton('다음', onPressed: _next),
    ]);
  }
}

class _OptionalField extends StatelessWidget {
  const _OptionalField({required this.label, required this.value, required this.unknown, required this.onChanged, required this.onUnknown, this.error});
  final String label;
  final String? error;
  final String value;
  final bool unknown;
  final ValueChanged<String> onChanged;
  final VoidCallback onUnknown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: NumField(
              key: ValueKey('$label$unknown'),
              label: label,
              value: unknown ? '' : value,
              enabled: !unknown,
              error: unknown ? null : error,
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
      // 고르기 전에 기준을 먼저 보게 맨 위에, 본문 글씨로 (리뷰 10/29 #5)
      const AppCard(
        child: Text('하: 주 1~3회 가볍게 · 중: 주 3~5회 · 상: 주 6회 이상 또는 고강도',
            style: TextStyle(fontSize: 14, color: AppColors.text)),
      ),
      title('지금 하고 있는 강도', '칼로리 계산에 쓰여요'),
      Seg(options: const ['하', '중', '상'], value: demo.currentIntensity, onChanged: (v) => demo.update(() => demo.currentIntensity = v)),
      title('앞으로 원하는 강도', '운동 루틴의 세기에 쓰여요'),
      Seg(options: const ['하', '중', '상'], value: demo.desiredIntensity, onChanged: (v) => demo.update(() => demo.desiredIntensity = v)),
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
      AppButton('다음', onPressed: () => Navigator.pushNamed(context, Routes.condition2)),
    ]);
  }
}

/// S03-2 식단·몸 상태 (기획서 B1: 못 먹는 음식, 아픈 부위, 주당 운동 일수)
class FoodBodyScreen extends StatelessWidget {
  const FoodBodyScreen({super.key});

  /// 식품 알레르기 표시 대상 중 자주 있는 것
  static const allergyOptions = ['우유', '달걀', '땅콩', '견과류', '대두', '밀가루', '메밀', '갑각류(새우·게)', '조개류', '생선', '복숭아', '토마토'];
  static const painOptions = ['목', '어깨', '허리', '손목', '무릎', '발목'];

  @override
  Widget build(BuildContext context) {
    void toggle(List<String> list, String v) => demo.update(() => list.contains(v) ? list.remove(v) : list.add(v));
    Widget chips(List<String> options, List<String> selected, {String? noneLabel}) => Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            if (noneLabel != null)
              FilterChip(
                label: Text(noneLabel),
                selected: selected.isEmpty,
                selectedColor: AppColors.primarySoft,
                onSelected: (_) => demo.update(selected.clear),
              ),
            for (final o in options)
              FilterChip(
                label: Text(o),
                selected: selected.contains(o),
                selectedColor: AppColors.primarySoft,
                onSelected: (_) => toggle(selected, o),
              ),
          ]),
        );
    return AppPage(title: '식단·몸 상태', children: [
      const Text('못 먹는 음식', style: TextStyle(fontWeight: FontWeight.w700)),
      const Muted('알레르기가 있거나 못 먹는 음식은 식단에서 빼요. 여러 개 고를 수 있어요.', bottom: 0),
      chips(allergyOptions, demo.allergies, noneLabel: '없음'),
      TextFormField(
        initialValue: demo.allergyNote,
        decoration: const InputDecoration(labelText: '그 밖에 못 먹는 음식 (선택)', hintText: '예: 오이, 고수'),
        onChanged: (v) => demo.allergyNote = v,
      ),
      const SizedBox(height: 16),
      const Text('아픈 부위', style: TextStyle(fontWeight: FontWeight.w700)),
      const Muted('고른 부위에 무리가 가는 운동은 루틴에서 빼요.', bottom: 0),
      chips(painOptions, demo.painAreas, noneLabel: '없음'),
      if (demo.painAreas.isNotEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: WarningBox('통증이 심하거나 질환이 있다면 운동 전에 의사와 먼저 상담하세요.', top: 0),
        ),
      const Text('일주일에 운동할 수 있는 날', style: TextStyle(fontWeight: FontWeight.w700)),
      Seg(options: const ['2일', '3일', '4일', '5일', '6일'], value: demo.daysPerWeek, onChanged: (v) => demo.update(() => demo.daysPerWeek = v)),
      AppButton('결과 보기', onPressed: () {
        demo.update(() {}); // 직접 입력한 음식을 기기에 저장
        Navigator.pushNamed(context, Routes.result);
      }),
    ]);
  }
}

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
          const Muted('하루에 쓰는 칼로리', bottom: 2),
          BigNumber('${formatNumber(r.tdee)} kcal'),
          if (hasMuscle) const Muted('근육량은 AI가 식단·운동 루틴을 짤 때 참고해요', bottom: 0),
          // 영어 공식 이름은 궁금한 사람만 펼쳐 보게 접어 둔다 (리뷰 10/29 #4)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('어떻게 계산했나요?', style: TextStyle(fontSize: 14, color: AppColors.primaryDark)),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Muted(
                  '가만히 있어도 쓰는 칼로리(기초대사량) ${formatNumber(r.bmr)}kcal에 '
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
          Muted('${demo.goal} 목표 칼로리', bottom: 2),
          BigNumber('${formatNumber(r.target)} kcal'),
          if (r.teen && demo.goal == '감량')
            const Muted('성장기라 감량 폭을 줄여서(−10%) 계산했어요.', bottom: 0),
          if (r.clampedToFloor) WarningBox('너무 낮은 칼로리는 위험해서 최소 ${formatNumber(r.floor)}kcal로 맞췄어요.', top: 8),
        ]),
      ),
      const Muted('의료 조언이 아닙니다. 건강 상태에 따라 전문가와 상의하세요.'),
      AppButton('식단·운동 루틴 만들기', onPressed: () => openPlanMaker(context)),
      if (!demo.loggedIn)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('만들려면 로그인이 필요해요.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.text)),
        ),
    ]);
  }
}

/// '식단·운동 루틴 만들기': 로그인했으면 기간 선택(S06)으로, 아니면 로그인 안내 후 S06으로 이어진다.
void openPlanMaker(BuildContext context) {
  // 로그인만 하고 동의를 안 했으면 동의 화면부터 (리뷰 10/29 #1)
  if (demo.loggedIn && !demo.consented) {
    demo.continueToGenerate = true;
    Navigator.pushNamed(context, Routes.consent);
  } else if (demo.loggedIn && demo.quotaExhausted) {
    showQuotaExhausted(context);
  } else if (demo.loggedIn) {
    Navigator.pushNamed(context, Routes.generate);
  } else {
    requireLogin(context, 'AI가 내 몸에 맞춘 식단·운동 루틴을 만들려면 로그인이 필요해요. 로그인하면 바로 이어서 만들 수 있어요.',
        thenGenerate: true);
  }
}

/// S05 로그인
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _login(BuildContext context) {
    demo.update(() {
      demo.role = 'user';
      demo.entered = true;
    });
    if (!demo.consented) {
      Navigator.pushReplacementNamed(context, Routes.consent);
    } else {
      continueAfterLogin(context);
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
              side: outlined ? const BorderSide(color: AppColors.socialBorder) : null,
            ),
            child: Text(label),
          ),
        );
    return AppPage(title: '로그인', children: [
      const H1('3초 만에 시작해요'),
      const Muted('로그인하면 식단·운동 루틴 생성, 식단 올리기를 쓸 수 있어요.'),
      social('카카오로 시작하기', AppColors.kakao, AppColors.kakaoText),
      social('구글로 시작하기', Colors.white, AppColors.googleText, outlined: true),
      social('Apple로 시작하기', Colors.black, Colors.white),
      const Disclaimer(text: '목업이라 실제 로그인은 하지 않아요. 누르면 일반 회원으로 들어가요.'),
    ]);
  }
}

/// 로그인(과 동의)을 마친 뒤: 식단·운동 루틴을 만들던 중이면 기간 선택으로, 아니면 홈으로
void continueAfterLogin(BuildContext context) {
  if (demo.continueToGenerate) {
    demo.continueToGenerate = false;
    Navigator.pushReplacementNamed(context, Routes.generate);
  } else {
    Navigator.pushNamedAndRemoveUntil(context, Routes.main, (_) => false);
  }
}

/// S05-1 동의 (로그인 직후 한 번). 문구는 전문가 검토 후 넣는다 (기획서 13번 L1·L2·L4·L5·L8).
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  static const items = [
    ('만 14세 이상이에요', true),
    ('이용약관 동의', true),
    ('개인정보 수집·이용 동의', true),
    ('건강정보(몸 정보, 식단 사진) 수집·이용 동의', true),
    ('AI 기반 서비스 안내 및 개인정보 국외 처리 위탁 동의', true),
    ('이벤트·혜택 알림 받기', false),
  ];
  final Set<int> agreed = {};

  bool get requiredDone => [for (var i = 0; i < items.length; i++) if (items[i].$2) i].every(agreed.contains);

  void _showDraft(String title) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          SheetTitle(title), // 다른 시트 제목과 같게 (디자인 리뷰 10/30 #6)
          const SizedBox(height: 10),
          const Muted('이 자리에는 전문가 검토를 마친 약관·동의서 원문이 들어가요. 목업에서는 비워 두었어요.'),
        ]),
      ),
    );
  }

  /// 동의하지 않고 뒤로 가면 로그인을 취소한다. 건강정보 동의를 건너뛰지 못하게 (리뷰 10/29 #1)
  Future<void> _leave() async {
    final cancel = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('동의하지 않으면 로그인이 취소돼요'),
        content: const Text('나가면 로그인 없이 둘러보기로 돌아가요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('계속 동의하기')),
          TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('로그인 취소')),
        ],
      ),
    );
    if (cancel != true || !mounted) return;
    demo.update(() {
      demo.role = 'guest';
      demo.continueToGenerate = false;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: AppPage(title: '시작하기 전에', children: [
      const Muted('서비스를 쓰려면 아래 내용에 동의해 주세요. 몸 정보와 식단 사진은 민감한 건강정보라 따로 동의를 받아요.'),
      AppCard(
        onTap: () => setState(() => agreed.length == items.length
            ? agreed.clear()
            : agreed.addAll([for (var i = 0; i < items.length; i++) i])),
        child: Row(children: [
          CheckCircle(agreed.length == items.length),
          const SizedBox(width: 10),
          const Expanded(child: Text('전체 동의', style: TextStyle(fontWeight: FontWeight.w700))),
        ]),
      ),
      for (var i = 0; i < items.length; i++)
        LineRow(
          onTap: () => setState(() => agreed.contains(i) ? agreed.remove(i) : agreed.add(i)),
          left: Row(children: [
            CheckCircle(agreed.contains(i)),
            const SizedBox(width: 10),
            Expanded(child: Text('[${items[i].$2 ? '필수' : '선택'}] ${items[i].$1}')),
          ]),
          right: i == 0 ? null : TextButton(onPressed: () => _showDraft(items[i].$1), child: const Text('보기')),
        ),
      const Disclaimer(text: '이 앱은 AI로 식단·운동 루틴과 답변을 만들어요. AI가 만든 내용은 의료 조언이 아닙니다.'),
      AppButton('동의하고 시작하기', onPressed: requiredDone
          ? () {
              demo.update(() => demo.consented = true);
              continueAfterLogin(context);
            }
          : null),
      if (!requiredDone)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('필수 항목에 모두 동의해야 시작할 수 있어요.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.text)),
        ),
    ]),
    );
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
  bool failed = false;

  Future<void> _generate() async {
    setState(() {
      generating = true;
      failed = false;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (demo.failMode == 'AI 실패') {
      if (mounted) {
        setState(() {
          generating = false;
          failed = true;
        });
      }
      return;
    }
    demo.update(() => demo.tab = 0);
    navigator.pushNamedAndRemoveUntil(Routes.main, (_) => false);
    messenger.showSnackBar(SnackBar(content: Text('${demo.period}치 식단과 운동 루틴을 만들었어요')));
  }

  @override
  Widget build(BuildContext context) {
    if (generating) {
      return const Scaffold(
        body: Center(child: LoadingView('AI가 식단과 운동 루틴을 만들고 있어요', sub: '잠시만 기다려 주세요')),
      );
    }
    if (failed) {
      return AppPage(title: '기간 선택', children: [
        FailureView(
          title: '식단·운동 루틴을 만들지 못했어요',
          onRetry: _generate,
          onLater: () => Navigator.pushNamedAndRemoveUntil(context, Routes.main, (_) => false),
        ),
      ]);
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
          if (demo.allergies.isNotEmpty || demo.allergyNote.isNotEmpty)
            Text('빼는 음식: ${[...demo.allergies, if (demo.allergyNote.isNotEmpty) demo.allergyNote].join(', ')}'),
          if (demo.painAreas.isNotEmpty) Text('조심할 부위: ${demo.painAreas.join(', ')}'),
        ]),
      ),
      AppButton('식단·운동 루틴 생성하기', onPressed: _generate),
    ]);
  }
}
