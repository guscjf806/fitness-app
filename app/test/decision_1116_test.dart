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
  test('결정 d1112-2 고른 양만큼 칼로리를 더한다', () {
    final m = mealDays[0].firstWhere((m) => !demo.mealPosts.any((p) => p.isToday && p.date == '오늘 ${m.title}'));
    final before = demo.todayEatenKcal;
    addTearDown(() {
      demo.eatenMeals.remove(m.title);
      demo.eatenAmounts.remove(m.title);
    });
    demo.eatenMeals.add(m.title);
    expect(demo.todayEatenKcal - before, m.kcal);
    demo.eatenAmounts[m.title] = '조금';
    expect(demo.todayEatenKcal - before, (m.kcal * 0.5).round());
  });
  test('리뷰 11/17 #1 답변을 받는 중인 끼니는 실패가 아니라 받는 중으로 본다', () {
    final slot = mealDays[0].first.title;
    final post = MealPost('오늘 $slot', '시험', '', isToday: true, replied: false);
    demo.mealPosts.insert(0, post);
    demo.replyPending.add(post);
    addTearDown(() {
      demo.replyPending.remove(post);
      demo.mealPosts.remove(post);
    });
    expect(demo.postedReplying(slot), isTrue);
    expect(demo.postedUnreplied(slot), isFalse);
  });
}
