import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../logic/intensity.dart';
import '../routes.dart';
import '../state/workout_session.dart';
import '../state/demo_state.dart';
import '../widgets/common.dart';
import '../widgets/exercise_figure.dart';

/// S11 운동
class WorkoutTab extends StatefulWidget {
  const WorkoutTab({super.key});

  @override
  State<WorkoutTab> createState() => _WorkoutTabState();
}

class _WorkoutTabState extends State<WorkoutTab> {
  int weekday = 0; // 0 = 오늘(월)

  void _finish() {
    if (demo.isGuest) {
      requireLogin(context, '운동 완료와 연속 기록은 계정에 저장돼요. 로그인하면 오늘부터 기록이 쌓여요.');
      return;
    }
    if (demo.checked.isEmpty) {
      toast(context, '체크한 종목이 없어요. 종목을 체크해 주세요');
      return;
    }
    demo.update(() => demo.workoutDone = true);
    toast(context, '오늘 운동 완료! 연속 ${demo.streak}일째예요 · 7일 연속 배지를 얻었어요');
  }

  /// 운동 진행(S23)을 시작한다. 진행 중이던 운동이 있으면 이어서 한다.
  void _start(WorkoutDay day) {
    final rule = intensityRules[effectiveIntensity(desired: demo.desiredIntensity, current: demo.currentIntensity)]!;
    demo.session ??= WorkoutSession([
      for (final x in [...day.items, ..._addedAsExercises(rule)]) SessionExercise(x.name, x.amount, x.sets),
    ], atHome: day.atHome);
    Navigator.pushNamed(context, Routes.session);
  }

  @override
  Widget build(BuildContext context) {
    final day = demo.week[weekday];
    final isToday = weekday == 0;
    return TabBody(children: [
      H1(demo.isGuest ? '예시 운동' : '운동'),
      if (demo.isGuest)
        const GuestBanner('로그인하면 내 운동 장소·장비·시간에 맞춘 루틴을 AI가 만들어요. 체크는 해 볼 수 있지만 저장되지 않아요.'),
      Muted(demo.conditionText),
      _IntensityGuide(),
      // 7일을 모두 보여 주고, 쉬는 날은 칩에 '휴식'으로 표시한다
      DayChips(
          labels: [for (var i = 0; i < 7; i++) demo.week[i].isRest ? '${dayLabels[i]} 휴식' : dayLabels[i]],
          selected: weekday,
          onSelect: (i) => setState(() => weekday = i)),
      H2(demo.place == '둘 다' && !day.isRest ? '${day.title} (${day.atHome ? '집' : '헬스장'})' : day.title, top: 0),
      if (!day.isRest)
        Builder(builder: (_) {
          final rule = intensityRules[effectiveIntensity(desired: demo.desiredIntensity, current: demo.currentIntensity)]!;
          final items = [...day.items, if (isToday) ..._addedAsExercises(rule)];
          return Muted('총 ${items.length}개 · 약 ${estimateMinutes(items, rule)}분');
        }),
      if (day.removed > 0)
        Muted('내 조건(${demo.place == '헬스장' ? '아픈 부위' : '장소·장비·소음·아픈 부위'})에 맞지 않는 운동 ${day.removed}개를 뺐어요.'),
      if (day.isRest)
        const AppCard(child: Text('쉬는 날이에요. 쉬는 날도 기록으로 인정돼요. 가벼운 걷기 30분을 추천해요.'))
      else
        for (var i = 0; i < day.items.length; i++)
          _ExerciseRow(
            name: day.items[i].name,
            amount: '${day.items[i].amount} × ${day.items[i].sets}세트',
            checked: isToday && (demo.workoutDone || demo.checked.contains(i)),
            onCheck: isToday && !demo.workoutDone
                ? () => demo.update(() => demo.checked.contains(i) ? demo.checked.remove(i) : demo.checked.add(i))
                : null,
          ),
      if (isToday)
        for (final name in demo.addedExercises)
          _ExerciseRow(name: name, amount: _addedAmount(name), checked: demo.workoutDone, onCheck: null),
      if (demo.painAreas.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Muted('${demo.painAreas.join(', ')} 통증을 고르셨어요. 무리가 가는 운동은 AI가 루틴에서 빼고, 주의 표시를 해 둬요.'),
        ),
      AppButton('+ 운동 추가', kind: ButtonKind.soft, onPressed: () async {
        final picked = await Navigator.pushNamed(context, Routes.exercisePick);
        if (picked is List<String> && picked.isNotEmpty) {
          demo.update(() => demo.addedExercises.addAll(picked.where((n) => !demo.addedExercises.contains(n))));
          if (context.mounted) toast(context, '${picked.length}개 운동을 오늘 루틴에 추가했어요');
          setState(() => weekday = 0);
        }
      }),
      if (isToday && !day.isRest)
        demo.workoutDone
            ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: AppCard(
                  onTap: () => Navigator.pushNamed(context, Routes.records),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('오늘 운동 완료', style: TextStyle(fontWeight: FontWeight.w700)),
                    Muted('연속 ${demo.streak}일째예요 · 연속 기록 보기 ›', bottom: 0),
                  ]),
                ),
              )
            : Column(children: [
                AppButton(demo.session == null ? '운동 시작' : '이어서 하기', onPressed: () => _start(day)),
                AppButton('기록 없이 완료 체크만 하기', kind: ButtonKind.soft, onPressed: _finish),
              ]),
      if (!isToday && !day.isRest)
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Muted('운동 완료는 오늘(월) 루틴에서만 누를 수 있어요.'),
        ),
      const Disclaimer(),
    ]);
  }
}

/// 루틴 한 줄: 동그라미를 누르면 체크, 나머지를 누르면 운동 방법(S22)
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.name, required this.amount, required this.checked, required this.onCheck});
  final String name;
  final String amount;
  final bool checked;
  final VoidCallback? onCheck;

  @override
  Widget build(BuildContext context) {
    final info = exerciseByName(name);
    final painHit = info == null ? const <String>[] : info.avoidFor.where(demo.painAreas.contains).toList();
    return LineRow(
      onTap: () => Navigator.pushNamed(context, Routes.exerciseDetail, arguments: name),
      left: Row(children: [
        // 손가락으로 누르기 쉽게 누르는 자리를 48px로 (디자인 리뷰 10/28 #1)
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onCheck,
          child: SizedBox(width: 48, height: 48, child: Center(child: CheckCircle(checked))),
        ),
        const SizedBox(width: 4),
        ExerciseThumb(name),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name),
            if (painHit.isNotEmpty) PainTag(painHit),
          ]),
        ),
      ]),
      right: Muted(amount, bottom: 0),
    );
  }
}

/// 강도 안내: 무게 고르는 법과 휴식 시간 (기획서 6번 강도 규칙)
class _IntensityGuide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final applied = effectiveIntensity(desired: demo.desiredIntensity, current: demo.currentIntensity);
    final rule = intensityRules[applied]!;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('강도 $applied', style: const TextStyle(fontWeight: FontWeight.w700)),
        if (applied != demo.desiredIntensity)
          Muted('지금 강도가 낮아서 첫 $rampUpWeeks주는 \'중\'으로 시작해요. 그다음 \'${demo.desiredIntensity}\'로 올려요.', bottom: 4),
        Muted('무게: 마지막 세트 뒤에 ${rule.repsInReserve} 더 할 수 있을 만큼\n세트 사이 휴식: ${rule.restText}', bottom: 0),
      ]),
    );
  }
}

/// 직접 추가한 운동도 강도 규칙으로 개수·세트를 정한다
List<Exercise> _addedAsExercises(IntensityRule rule) => [
      for (final n in demo.addedExercises)
        if (exerciseByName(n) case final info?) Exercise(n, targetFor(info, rule).$1, targetFor(info, rule).$2),
    ];

String _addedAmount(String name) {
  final rule = intensityRules[effectiveIntensity(desired: demo.desiredIntensity, current: demo.currentIntensity)]!;
  final info = exerciseByName(name);
  if (info == null) return '';
  final (amount, sets) = targetFor(info, rule);
  return '$amount × $sets세트';
}
