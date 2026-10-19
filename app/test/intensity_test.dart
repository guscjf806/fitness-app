import 'package:fitness_app/data/mock_data.dart';
import 'package:fitness_app/logic/intensity.dart';
import 'package:fitness_app/logic/routine.dart';
import 'package:flutter_test/flutter_test.dart';

List<WorkoutDay> week(String desired, {String current = '중', String minutes = '45분', String place = '헬스장'}) => demoWeek(
    place: place, equipment: '맨몸', noise: '예', minutes: minutes, painAreas: [], daysPerWeek: '5일',
    desiredIntensity: desired, currentIntensity: current);

Exercise find(List<WorkoutDay> w, String name) =>
    w.expand((d) => d.items).firstWhere((x) => x.name == name);

void main() {
  test('하·중·상에 따라 큰 운동의 세트와 개수가 달라진다', () {
    expect(find(week('하'), '벤치프레스').sets, 3);
    expect(find(week('하'), '벤치프레스').amount, '12~15개');
    expect(find(week('중'), '벤치프레스').sets, 4);
    expect(find(week('중'), '벤치프레스').amount, '8~12개');
    expect(find(week('상'), '벤치프레스').sets, 5);
    expect(find(week('상'), '벤치프레스').amount, '6~8개');
  });

  test('작은 운동은 세트가 하나 적고, 버티기 운동은 초로 나온다', () {
    expect(find(week('중'), '트라이셉스 푸시다운').sets, 3);
    expect(find(week('중'), '플랭크').amount, '30~40초');
  });

  test('지금 강도 하 → 원하는 강도 상이면 첫 2주는 중으로 시작한다', () {
    expect(effectiveIntensity(desired: '상', current: '하'), '중');
    expect(effectiveIntensity(desired: '상', current: '하', weeksDone: 2), '상');
    expect(find(week('상', current: '하'), '벤치프레스').sets, 4);
  });

  test('맨몸 운동은 하면 쉬운 동작, 상이면 어려운 동작으로 바뀐다', () {
    List<String> names(List<WorkoutDay> w) => w.expand((d) => d.items).map((x) => x.name).toList();
    expect(names(week('하', place: '집')), contains('벽 푸시업'));
    expect(names(week('상', place: '집')), contains('푸시업'));
    // 조용히: 상이어도 점프 스쿼트로 바꾸지 않는다
    expect(names(week('상', place: '집')), isNot(contains('점프 스쿼트')));
  });

  test('세트가 많아도 고른 운동 시간 안에 끝나게 종목 수를 줄인다', () {
    for (final minutes in ['15분', '30분', '45분']) {
      for (final level in ['하', '중', '상']) {
        final rule = intensityRules[level]!;
        final budget = int.parse(minutes.replaceAll('분', '')) * 60;
        for (final d in week(level, minutes: minutes)) {
          if (d.isRest) continue;
          final used = d.items.fold<int>(0, (t, x) => t + x.sets * (40 + rule.restSeconds));
          expect(d.items.length, greaterThanOrEqualTo(2), reason: '$minutes $level ${d.title}');
          if (d.items.length > 2) expect(used, lessThanOrEqualTo(budget), reason: '$minutes $level ${d.title}');
        }
      }
    }
  });
}
