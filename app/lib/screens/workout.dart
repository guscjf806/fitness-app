import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../routes.dart';
import '../state/demo_state.dart';
import '../widgets/common.dart';

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
          LineRow(
            onTap: isToday && !demo.workoutDone
                ? () => demo.update(() => demo.checked.contains(i) ? demo.checked.remove(i) : demo.checked.add(i))
                : null,
            left: Row(children: [
              CheckCircle(isToday && (demo.workoutDone || demo.checked.contains(i))),
              const SizedBox(width: 10),
              ExerciseThumb(day.items[i].name),
              const SizedBox(width: 10),
              Expanded(child: Text(day.items[i].name)),
            ]),
            right: Muted('${day.items[i].amount} × ${day.items[i].sets}세트', bottom: 0),
          ),
      AppButton('+ 운동 추가',
          kind: ButtonKind.soft,
          onPressed: () => toast(context, '운동 추가 화면은 다음 단계에서 만들어요')),
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
