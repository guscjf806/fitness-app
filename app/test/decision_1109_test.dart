import 'package:fitness_app/data/mock_data.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'finders.dart';

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
    demo.mealPosts.insert(0, MealPost('오늘 ${breakfast.title}', '바나나', '', isToday: true, kcal: 100));
    expect(demo.todayEatenKcal, 1099, reason: '같은 끼니를 두 번 올리면 더한다 (리뷰 11/11 #4)');
  });
  Future<void> openEdit(WidgetTester tester, String route) async {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const FitnessApp());
    await tester.pumpAndSettle();
    demoNavigatorKey.currentState!.pushNamed(route, arguments: 'edit');
    await tester.pumpAndSettle();
  }

  testWidgets('결정 d1107-1 못 먹는 음식을 고치면 횟수 없이 새로 만들지 묻는다', (tester) async {
    demo.allergies.clear();
    final used = demo.aiUsed;
    await openEdit(tester, Routes.condition2);
    demo.update(() => demo.allergies.add('땅콩'));
    await tester.scrollUntilVisible(findText('저장하기'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(findText('저장하기'));
    await tester.pumpAndSettle();
    expect(findText('식단·루틴을 새로 만들까요?'), findsOneWidget);
    await tester.tap(findText('새로 만들기'));
    await tester.pumpAndSettle();
    expect(demo.aiUsed, used, reason: '안전 수정은 횟수를 세지 않는다');
    expect(findTextContaining('무료 횟수 그대로'), findsOneWidget);
  });

  testWidgets('결정 d1107-1 아무것도 안 고치면 묻지 않는다', (tester) async {
    await openEdit(tester, Routes.condition2);
    await tester.scrollUntilVisible(findText('저장하기'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(findText('저장하기'));
    await tester.pumpAndSettle();
    expect(findText('식단·루틴을 새로 만들까요?'), findsNothing);
    expect(findText('바뀐 조건으로 새로 만들까요?'), findsNothing);
  });
  testWidgets('결정 d1111-1 못 먹는 음식을 고치고 나중에를 누르면 식단 탭 맨 위에 새로 만들기 띠', (tester) async {
    demo.allergies.clear();
    await openEdit(tester, Routes.condition2);
    demo.update(() => demo.allergies.add('땅콩'));
    await tester.scrollUntilVisible(findText('저장하기'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(findText('저장하기'));
    await tester.pumpAndSettle();
    await tester.tap(findText('나중에'));
    await tester.pumpAndSettle();
    expect(demo.planOutdated, isTrue);
    demo.update(() => demo.tab = 1);
    await tester.pumpAndSettle();
    expect(findText('조건이 바뀌었어요. 새로 만들어 주세요'), findsOneWidget);
    await tester.tap(findText('새로 만들기'));
    await tester.pumpAndSettle();
    expect(demo.planOutdated, isFalse);
  });
}
