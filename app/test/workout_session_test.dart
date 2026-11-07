import 'package:fitness_app/state/workout_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('무게를 적으면 아래 빈 칸에 복사하고, 직접 적은 칸은 그대로 둔다 (리뷰 10/28 #5)', () {
    final ex = SessionExercise('벤치프레스', '8~12개', 4);
    ex.copyKgDown(2, '50');
    ex.copyKgDown(0, '40');
    expect([for (final s in ex.sets) s.kg], ['40', '40', '50', '50']);
    ex.copyKgDown(0, '45');
    expect([for (final s in ex.sets) s.kg], ['45', '45', '50', '50']);
  });
  test('결정 d1028-weight-prefill 지난번 무게를 채우고, 고치면 추천 표시가 사라진다', () {
    final ex = SessionExercise('벤치프레스', '8~12개', 3)..prefillKg('60');
    expect(ex.sets.map((s) => s.kg), ['60', '60', '60']);
    expect(ex.hasSuggestedKg, isTrue);
    ex.copyKgDown(0, '65');
    expect(ex.sets.map((s) => s.kg), ['65', '65', '65']);
    expect(ex.hasSuggestedKg, isFalse);
  });
  test('리뷰 11/07 #2 대체한 종목도 원래 줄을 기억한다', () {
    final before = SessionExercise('벤치프레스', '8~12개', 3);
    final after = SessionExercise('푸시업', '8~12개', 3)..originName = before.originName;
    expect(after.originName, '벤치프레스');
  });
}
