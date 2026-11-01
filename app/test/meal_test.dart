import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 식단 올리기(S09)·AI 답변(S10) 흐름 (리뷰 11/01)
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    demo.switchRole('user');
    demo
      ..failMode = '정상'
      ..aiUsed = 2
      ..mealPosts.removeWhere((p) => p.isToday);
  });

  Future<void> openPost(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const FitnessApp());
    await tester.pumpAndSettle();
    demoNavigatorKey.currentState!.pushNamed(Routes.mealPost);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  testWidgets('#1 답변을 받으면 이번 달 횟수가 1회 늘고, 실패하면 늘지 않는다', (tester) async {
    await openPost(tester);
    expect(find.textContaining('이번 달 2 / 5회'), findsOneWidget);
    await tap(tester, find.text('눌러서 사진 선택'));
    await tap(tester, find.text('올리기'));
    expect(demo.aiUsed, 3);

    demo.failMode = 'AI 실패';
    demoNavigatorKey.currentState!.pushNamed(Routes.mealPost);
    await tester.pumpAndSettle();
    expect(find.textContaining('이번 달 3 / 5회'), findsOneWidget);
    await tap(tester, find.text('눌러서 사진 선택'));
    await tap(tester, find.text('올리기'));
    expect(find.text('AI 답변을 받지 못했어요'), findsOneWidget);
    expect(demo.aiUsed, 3);
  });

  testWidgets('#2 사진을 다시 눌러도 빠지지 않고, 사진 빼기로만 뺀다', (tester) async {
    await openPost(tester);
    await tap(tester, find.text('눌러서 사진 선택'));
    await tap(tester, find.text('사진이 선택됐어요 · 눌러서 바꾸기'));
    expect(find.text('사진이 선택됐어요 · 눌러서 바꾸기'), findsOneWidget, reason: '다시 눌러도 그대로 선택됨');
    await tap(tester, find.text('사진 빼기'));
    expect(find.text('눌러서 사진 선택'), findsOneWidget);
  });

  testWidgets('#1 다 썼으면 올리기 전에 알린다', (tester) async {
    demo.aiUsed = 5;
    await openPost(tester);
    expect(find.text('이번 달 무료 횟수를 다 썼어요'), findsOneWidget);
  });
}
