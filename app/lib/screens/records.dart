import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// S20 내 기록 (연속 기록 · 통계)
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String view = '연속 기록';

  @override
  Widget build(BuildContext context) {
    return AppPage(title: '내 기록', children: [
      Seg(options: const ['연속 기록', '통계'], value: view, onChanged: (v) => setState(() => view = v)),
      if (view == '연속 기록') ..._streak(context) else ..._stats(),
    ]);
  }

  List<Widget> _streak(BuildContext context) {
    final badges = [
      ('첫 식단', demo.mealPosts.isNotEmpty, ''),
      ('7일 연속', demo.streak >= 7, '연속 7일을 기록하면 받아요'),
      ('첫 PT 일지 확인', demo.role == 'member' || demo.firstLogSeen, 'PT 일지를 처음 열어 보면 받아요'),
      ('한 달 운동 20회', false, '이번 달 ${14 + (demo.workoutDone ? 1 : 0)} / 20회'),
    ];
    return [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('현재 연속 기록', bottom: 2),
          BigNumber('${demo.streak}일'),
          Muted('최장 기록 12일${demo.restMode ? ' · 쉬기 모드 중이라 기록이 유지돼요' : ''}', bottom: 10),
          Row(children: [
            for (var i = 1; i <= 7; i++) ...[
              _Dot(on: i < 7 || demo.recordedToday),
              const SizedBox(width: 6),
            ],
          ]),
          const SizedBox(height: 8),
          const Muted('최근 7일 (마지막이 오늘)', bottom: 0),
        ]),
      ),
      LineRow(
        left: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('쉬기 모드'),
          Muted('아프거나 다칠 때 켜 두세요 (최대 7일)', bottom: 0),
        ]),
        right: Switch(
          value: demo.restMode,
          activeTrackColor: AppColors.primary,
          onChanged: (v) {
            demo.update(() => demo.restMode = v);
            toast(context, v ? '쉬기 모드를 켰어요. 알림이 멈추고 기록이 유지돼요' : '쉬기 모드를 껐어요');
          },
        ),
      ),
      LineRow(
        left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('스트릭 프리즈'),
          Muted('하루 놓쳐도 기록을 지켜 줘요 · 이번 달 ${demo.freezesLeft}회 남음', bottom: 0),
        ]),
        right: OutlinedButton(
          onPressed: () {
            if (demo.freezesLeft < 1) {
              toast(context, '이번 달 프리즈를 모두 썼어요');
              return;
            }
            demo.update(() => demo.freezesLeft--);
            toast(context, '프리즈를 사용했어요. 연속 기록이 지켜졌어요');
          },
          child: const Text('사용하기'),
        ),
      ),
      const H2('배지'),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2,
        children: [
          for (final b in badges)
            Opacity(
              opacity: b.$2 ? 1 : 0.55,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Muted(b.$2 ? '획득했어요' : b.$3, bottom: 0),
                ]),
              ),
            ),
        ],
      ),
    ];
  }

  List<Widget> _stats() {
    final done = demo.workoutDone ? 1 : 0;
    // 2026년 10월 1일은 목요일 → 앞에 빈칸 3개
    final cells = <int?>[null, null, null, for (var d = 1; d <= 31; d++) d];
    return [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('이번 달 운동 달력 (10월)'),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            children: [
              for (final d in dayLabels)
                Center(child: Text(d, style: const TextStyle(fontSize: 12, color: AppColors.textSub))),
              for (final d in cells) d == null ? const SizedBox() : _CalendarDay(d),
            ],
          ),
          const Muted('불꽃 = 운동한 날 · 연한 색 = 쉬는 날(기록으로 인정)', bottom: 0),
        ]),
      ),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('이번 주 운동 완료율', bottom: 2),
          Text.rich(TextSpan(children: [
            TextSpan(text: '$done', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            TextSpan(text: ' / ${demo.workoutDaysThisWeek}일 완료'),
          ])),
          ProgressBar(done / demo.workoutDaysThisWeek),
          Muted('이번 주 루틴 ${demo.workoutDaysThisWeek}일 기준이에요. 휴식일과 쉬기 모드 기간은 빼고 계산해요.', bottom: 0),
        ]),
      ),
      const Muted('통계는 나에게만 보여요. 기록이 쌓이면 체중 그래프, 종목별 기록 추이도 보여드릴게요.'),
    ];
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(shape: BoxShape.circle, color: on ? AppColors.primary : AppColors.track),
        child: on ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
      );
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay(this.day);
  final int day;

  @override
  Widget build(BuildContext context) {
    final done = monthDoneDays.contains(day) || (day == demoToday && demo.workoutDone);
    final rest = monthRestDays.contains(day);
    final future = day > demoToday;
    return Center(
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? AppColors.primaryDark : (rest ? AppColors.primarySoft : null),
          border: day == demoToday ? Border.all(color: AppColors.text, width: 2) : null,
        ),
        // 운동한 날은 불꽃 위에 날짜를 얹는다
        child: Stack(alignment: Alignment.center, children: [
          if (done) const Icon(Icons.local_fire_department, color: AppColors.streakFire, size: 30),
          Text('$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: done ? FontWeight.w700 : FontWeight.w400,
              color: done
                  ? Colors.white
                  : rest
                      ? AppColors.primaryDark
                      : future
                          ? AppColors.textSub
                          : AppColors.text,
            )),
        ]),
      ),
    );
  }
}
