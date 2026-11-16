import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/data/mock_data.dart';
import 'package:fitness_app/state/demo_state.dart';

void main() {
  test('결정 d1113-2 답변 못 받은 끼니는 체크하고 칼로리는 안 더한다', () {
    final slot = mealDays[0].first.title;
    final before = demo.todayEatenKcal;
    demo.mealPosts.insert(0, MealPost('오늘 $slot', '시험', '', isToday: true, replied: false));
    addTearDown(() => demo.mealPosts.removeAt(0));
    expect(demo.postedUnreplied(slot), isTrue);
    expect(demo.todayEatenKcal, before);
  });
}
