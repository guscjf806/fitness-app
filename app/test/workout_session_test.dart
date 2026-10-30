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
}
