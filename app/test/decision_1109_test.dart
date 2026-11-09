import 'package:fitness_app/data/mock_data.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 11/09에 고른 결정
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    demo.switchRole('user');
    demo.eatenMeals.clear();
    demo.mealPosts.removeWhere((p) => p.isToday);
  });

  test('결정 d1107-2 먹었어요는 식단표 칼로리, 같은 끼니에 올린 식단은 AI 추정값으로 센다', () {
    final breakfast = mealDays[0].first;
    expect(demo.todayEatenKcal, 0);
    demo.eatenMeals.add(breakfast.title);
    expect(demo.todayEatenKcal, breakfast.kcal);
    demo.mealPosts.insert(0, MealPost('오늘 ${breakfast.title}', '오트밀', '', isToday: true, kcal: 999));
    expect(demo.todayEatenKcal, 999, reason: '두 번 세지 않는다');
  });
}
