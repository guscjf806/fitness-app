import 'dart:math' as math;

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
    // 고정 숫자 대신 데이터에서 계산한다 (리뷰 11/03 #7)
    final monthCount = monthDoneDays.length + (demo.workoutDone ? 1 : 0);
    final longest = math.max(pastLongestStreak, demo.streak);
    final badges = [
      ('첫 식단', demo.mealPosts.isNotEmpty, ''),
      ('7일 연속', demo.streak >= 7, '연속 7일을 기록하면 받아요'),
      ('첫 PT 일지 확인', demo.role == 'member' || demo.firstLogSeen, 'PT 일지를 처음 열어 보면 받아요'),
      ('한 달 운동 20회', false, '이번 달 $monthCount / 20회'),
    ];
    return [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('현재 연속 기록', bottom: 2),
          BigNumber('${demo.streak}일'),
          Muted('최장 기록 $longest일${demo.restMode ? ' · 쉬기 모드 중이라 기록이 유지돼요' : ''}', bottom: 10),
          // 어느 날인지 알 수 있게 동그라미 아래에 요일을 쓴다.
          // 마지막 칸은 '오늘'로 쓰고 색을 달리해, 아직 안 한 날처럼 보이지 않게 (디자인 리뷰 11/03 #2)
          Row(children: [
            for (var i = 1; i <= 7; i++) ...[
              Column(children: [
                _Dot(on: i < 7 || demo.recordedToday, today: i == 7),
                const SizedBox(height: 2),
                Text(i == 7 ? '오늘' : dayLabels[DateTime(2026, 10, demoToday - 7 + i).weekday - 1],
                    style: i == 7
                        ? AppText.small.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)
                        : AppText.small.copyWith(color: AppColors.textSub)),
              ]),
              const SizedBox(width: 6),
            ],
          ]),
          const SizedBox(height: AppSpace.s),
          const Muted('최근 7일', bottom: 0),
        ]),
      ),
      const RestModeSwitch(),
      LineRow(
        left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 영어 '스트릭 프리즈' 대신 쉬운 이름 (리뷰 11/03 #5)
          const Text('기록 지키기권'),
          Muted('하루 빠져도 연속 기록이 끊기지 않게 지켜 줘요 · 이번 달 ${demo.freezesLeft}회 남음', bottom: 0),
        ]),
        right: OutlinedButton(
          onPressed: () async {
            if (demo.freezesLeft < 1) {
              toast(context, '이번 달 기록 지키기권을 모두 썼어요');
              return;
            }
            // 되돌릴 수 없으니 쓰기 전에 한 번 묻는다 (리뷰 11/03 #1)
            final ok = await confirmDialog(context,
                title: '기록 지키기권을 쓸까요?',
                body: '기록 지키기권 1회를 써요. 이번 달 남은 횟수: ${demo.freezesLeft - 1}회',
                keepLabel: '그만두기',
                okLabel: '쓰기');
            if (!ok || !context.mounted) return;
            demo.update(() => demo.freezesLeft--);
            toast(context, '기록 지키기권을 썼어요. 연속 기록이 지켜졌어요');
          },
          child: const Text('사용하기'),
        ),
      ),
      const H2('배지'),
      // 줄마다 왼쪽 동그란 표시 + 이름·설명 (결정 dd1030-badge-look)
      for (final b in badges) _BadgeRow(b),
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
                Center(child: Text(d, style: AppText.small.copyWith(color: AppColors.textSub))),
              for (final d in cells) d == null ? const SizedBox() : _CalendarDay(d),
            ],
          ),
          const Muted('진한 색과 불꽃 = 운동한 날 · 연한 색 = 쉬는 날(기록으로 인정)', bottom: 0),
        ]),
      ),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('이번 주 운동 완료율', bottom: 2),
          Text.rich(TextSpan(children: [
            TextSpan(text: '$done', style: AppText.number),
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
  const _Dot({required this.on, this.today = false});
  final bool on;

  /// 오늘 칸. 아직 안 했으면 회색 대신 주황 테두리 원으로 그린다
  final bool today;

  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? AppColors.primary : (today ? null : AppColors.track),
          border: !on && today ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
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
        // 운동한 날: 청록 동그라미에 흰 숫자, 불꽃은 숫자 아래 작게 (결정 dd1030-calendar-done)
        child: Stack(alignment: Alignment.center, children: [
          Padding(
            padding: EdgeInsets.only(bottom: done ? 8 : 0),
            child: Text('$day',
                style: AppText.caption.copyWith(
                  height: 1,
                  fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                  color: done
                      ? Colors.white
                      : rest
                          ? AppColors.primaryDark
                          : future
                              ? AppColors.textSub
                              : AppColors.text,
                )),
          ),
          if (done)
            const Positioned(
              bottom: 3,
              child: Icon(Icons.local_fire_department, color: AppColors.streakFire, size: 11),
            ),
        ]),
      ),
    );
  }
}

/// 배지 한 줄: 받음은 청록 체크, 아직은 회색 자물쇠
class _BadgeRow extends StatelessWidget {
  const _BadgeRow(this.badge);
  final (String, bool, String) badge;

  @override
  Widget build(BuildContext context) {
    final (name, earned, how) = badge;
    return LineRow(
      left: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: earned ? AppColors.primary : AppColors.track),
          child: Icon(earned ? Icons.check : Icons.lock_outline, size: 20, color: earned ? Colors.white : AppColors.textSub),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppText.bodyStrong),
            Muted(earned ? '획득했어요' : how, bottom: 0),
          ]),
        ),
      ]),
    );
  }
}
