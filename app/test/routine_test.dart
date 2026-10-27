import 'package:fitness_app/data/exercise_lookup.dart';
import 'package:fitness_app/data/exercises.dart';
import 'package:fitness_app/data/mock_data.dart';
import 'package:fitness_app/logic/routine.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> names(List<WorkoutDay> week) => [for (final d in week) for (final x in d.items) x.name];

void main() {
  test('루틴에 나오는 모든 종목이 종목 목록에 있다', () {
    for (final week in [gymSessions, homeBodyweightSessions, homeDumbbellSessions]) {
      for (final d in week) {
        for (final x in d.items) {
          expect(exerciseByName(x.name), isNotNull, reason: x.name);
          if (x.loudAlt != null) expect(exerciseByName(x.loudAlt!), isNotNull, reason: x.loudAlt);
        }
      }
    }
  });

  test('집 · 맨몸 · 조용히: 헬스장 종목, 기구 종목, 점프 종목이 하나도 없다', () {
    final week = demoWeek(place: '집', equipment: '맨몸', noise: '예', minutes: '30분', painAreas: [], daysPerWeek: '5일');
    expect(names(week), isNot(contains('벤치프레스')));
    expect(names(week), isNot(contains('케이블 크로스오버')));
    for (final n in names(week)) {
      final e = exerciseByName(n)!;
      expect(e.place, isNot('gym'), reason: n);
      expect(e.equipment, '맨몸', reason: n);
      expect(e.impact == 'high' || e.noise == 'loud', isFalse, reason: n);
    }
  });

  test('집 · 맨몸 · 소음 괜찮음: 점프 동작이 들어간다', () {
    final week = demoWeek(place: '집', equipment: '맨몸', noise: '아니오', minutes: '30분', painAreas: [], daysPerWeek: '5일');
    expect(names(week), contains('점프 스쿼트'));
  });

  test('집 · 밴드·덤벨: 바벨·머신·케이블 종목이 없다', () {
    final week = demoWeek(place: '집', equipment: '밴드·덤벨', noise: '예', minutes: '30분', painAreas: [], daysPerWeek: '5일');
    for (final n in names(week)) {
      expect(['맨몸', '덤벨', '밴드'], contains(exerciseByName(n)!.equipment), reason: n);
    }
  });

  test('둘 다: 헬스장 날과 집 날이 섞이고, 집 날에는 집 규칙이 적용된다', () {
    final week = demoWeek(place: '둘 다', equipment: '맨몸', noise: '예', minutes: '30분', painAreas: [], daysPerWeek: '5일');
    expect(week.where((d) => d.atHome && !d.isRest), isNotEmpty);
    expect(week.where((d) => !d.atHome && !d.isRest), isNotEmpty);
    for (final d in week.where((d) => d.atHome)) {
      for (final x in d.items) {
        expect(exerciseByName(x.name)!.place, isNot('gym'), reason: x.name);
      }
    }
  });

  test('무릎 통증: 무릎에 무리가 가는 종목을 빼고 몇 개 뺐는지 알려 준다', () {
    final week = demoWeek(place: '헬스장', equipment: '맨몸', noise: '예', minutes: '45분', painAreas: ['무릎'], daysPerWeek: '5일');
    for (final n in names(week)) {
      expect(exerciseByName(n)!.avoidFor, isNot(contains('무릎')), reason: n);
    }
    expect(week.firstWhere((d) => d.title == '하체').removed, greaterThan(0));
  });

  test('15분이면 하루 3종목까지만', () {
    final week = demoWeek(place: '헬스장', equipment: '맨몸', noise: '예', minutes: '15분', painAreas: [], daysPerWeek: '5일');
    for (final d in week) {
      expect(d.items.length, lessThanOrEqualTo(3));
    }
  });

  test('목록에 없는 종목(AI 실수)은 안전망에서 빠진다', () {
    final day = enforceConditions(
      const WorkoutDay('테스트', [Exercise('벤치프레스', '8개', 4), Exercise('없는 운동', '8개', 4)], atHome: true),
      equipment: '맨몸', quiet: true, painAreas: [], minutes: '30분');
    expect(day.items, isEmpty);
    expect(day.removed, 2);
  });

  test('모든 종목에 설명 3단계와 주의할 점, 그림이 있다', () {
    for (final e in exercises) {
      expect(e.howTo.length, 3, reason: e.name);
      expect(e.caution, isNotEmpty, reason: e.name);
      expect(exerciseFigures[e.figureId], isNotNull, reason: e.name);
    }
  });

  for (final n in [2, 3, 4, 5, 6]) {
    test('주 $n일을 고르면 7일 중 $n일 운동하고 나머지는 쉰다', () {
      for (final place in ['헬스장', '집', '둘 다']) {
        final week = demoWeek(place: place, equipment: '맨몸', noise: '예', minutes: '30분', painAreas: [], daysPerWeek: '$n일');
        expect(week.length, 7, reason: place);
        expect(week.where((d) => !d.isRest).length, n, reason: place);
        expect(week[0].isRest, isFalse, reason: '월요일은 늘 운동하는 날');
      }
    });
  }

  test('주 6일이면 토요일까지 운동하고 일요일은 쉰다', () {
    final week = demoWeek(place: '헬스장', equipment: '맨몸', noise: '예', minutes: '30분', painAreas: [], daysPerWeek: '6일');
    expect(week[5].isRest, isFalse); // 토
    expect(week[6].isRest, isTrue); // 일
  });

  test('이어지는 운동일에 같은 세션이 연달아 나오지 않는다', () {
    for (final n in [4, 5, 6]) {
      for (final place in ['헬스장', '집']) {
        final week = demoWeek(place: place, equipment: '맨몸', noise: '예', minutes: '30분', painAreas: [], daysPerWeek: '$n일');
        for (var i = 1; i < 7; i++) {
          if (!week[i].isRest && !week[i - 1].isRest) expect(week[i].title, isNot(week[i - 1].title), reason: '$place $n일 $i');
        }
      }
    }
  });

  test('장소는 헬스장 전용과 집에서도 가능 두 가지이고, 기구와 맞는다', () {
    const homeGear = {'덤벨', '저항 밴드', '밴드 고정 고리(문·기둥)', '운동 매트', '튼튼한 의자·계단', '벽'};
    for (final e in exercises) {
      expect(['gym', 'home'], contains(e.place), reason: e.name);
      if (e.place == 'home') {
        expect(homeGear.containsAll(e.gear), isTrue, reason: '${e.name}: ${e.gear}');
        expect(['맨몸', '덤벨', '밴드'], contains(e.equipment), reason: e.name);
      } else {
        expect(e.gear.any((g) => !homeGear.contains(g)), isTrue, reason: '${e.name}는 헬스장 기구가 필요해야 함');
      }
      expect(['compound', 'isolation', 'hold'], contains(e.kind), reason: e.name);
      expect([1, 2, 3], contains(e.level), reason: e.name);
    }
    expect(exercises.where((e) => e.place == 'home').length, greaterThanOrEqualTo(30), reason: '홈트 종목 30개 이상 (기획서)');
    expect(exercises.length, inInclusiveRange(50, 100), reason: '종목 50~100개 (기획서)');
  });
}
