import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../routes.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final day = demo.week[weekday];
    final isToday = weekday == 0;
    return TabBody(children: [
      H1(demo.isGuest ? '예시 운동' : '운동'),
      if (demo.isGuest)
        const GuestBanner('로그인하면 내 운동 장소·장비·시간에 맞춘 루틴을 AI가 만들어요. 체크는 해 볼 수 있지만 저장되지 않아요.'),
      Muted('원하는 강도: ${demo.desiredIntensity} · ${demo.conditionText}'),
      DayChips(labels: weekdayLabels, selected: weekday, onSelect: (i) => setState(() => weekday = i)),
      H2(day.title, top: 0),
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
          _ExerciseRow(name: name, amount: '10개 × 3세트', checked: demo.workoutDone, onCheck: null),
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
            : AppButton('오늘 운동 완료', onPressed: _finish),
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
    final caution = info != null && info.avoidFor.any(demo.painAreas.contains);
    return LineRow(
      onTap: () => Navigator.pushNamed(context, Routes.exerciseDetail, arguments: name),
      left: Row(children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onCheck,
          child: Padding(padding: const EdgeInsets.all(6), child: CheckCircle(checked)),
        ),
        const SizedBox(width: 4),
        ExerciseThumb(name),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name),
            if (caution)
              const Text('통증 부위 주의', style: TextStyle(color: AppColors.warning, fontSize: 12)),
          ]),
        ),
      ]),
      right: Muted(amount, bottom: 0),
    );
  }
}
