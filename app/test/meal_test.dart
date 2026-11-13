import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/screens/meal.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'finders.dart';
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
    expect(findTextContaining('이번 달 2 / 5회'), findsOneWidget);
    await tap(tester, findText('눌러서 사진 선택'));
    await tap(tester, findText('올리기'));
    expect(demo.aiUsed, 3);

    demo.failMode = 'AI 실패';
    demoNavigatorKey.currentState!.pushNamed(Routes.mealPost);
    await tester.pumpAndSettle();
    expect(findTextContaining('이번 달 3 / 5회'), findsOneWidget);
    await tap(tester, findText('눌러서 사진 선택'));
    await tap(tester, findText('올리기'));
    expect(findText('AI 답변을 받지 못했어요'), findsOneWidget);
    expect(demo.aiUsed, 3);
    expect(demo.mealPosts.first.kcal, isNull, reason: '리뷰 11/13 #1 실패하면 칼로리를 더하지 않는다');
    expect(demo.mealPosts.first.replied, isFalse);
  });

  testWidgets('#2 사진을 다시 눌러도 빠지지 않고, 사진 빼기로만 뺀다', (tester) async {
    await openPost(tester);
    await tap(tester, findText('눌러서 사진 선택'));
    await tap(tester, findText('사진이 선택됐어요 · 눌러서 바꾸기'));
    expect(findText('사진이 선택됐어요 · 눌러서 바꾸기'), findsOneWidget, reason: '다시 눌러도 그대로 선택됨');
    await tap(tester, findText('사진 빼기'));
    expect(findText('눌러서 사진 선택'), findsOneWidget);
  });

  testWidgets('#3 쓰던 내용이 있으면 뒤로 갈 때 지울지 묻는다', (tester) async {
    await openPost(tester);
    await tap(tester, findText('눌러서 사진 선택'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(findText('쓰던 내용을 지울까요?'), findsOneWidget);
    await tap(tester, findText('계속 쓰기'));
    expect(findText('식단 올리기'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tap(tester, findText('지우고 나가기'));
    expect(findText('식단 올리기'), findsNothing);
  });

  test('#4 지금 시각으로 끼니 처음 값을 정한다', () {
    expect(mealSlotFor(DateTime(2026, 11, 1, 8)), '아침');
    expect(mealSlotFor(DateTime(2026, 11, 1, 12, 30)), '점심');
    expect(mealSlotFor(DateTime(2026, 11, 1, 16)), '간식');
    expect(mealSlotFor(DateTime(2026, 11, 1, 19)), '저녁');
    expect(mealSlotFor(DateTime(2026, 11, 1, 23)), '간식');
  });

  testWidgets('#4 고른 끼니로 저장된다', (tester) async {
    await openPost(tester);
    await tap(tester, findText('저녁'));
    await tap(tester, findText('눌러서 사진 선택'));
    await tap(tester, findText('올리기'));
    expect(demo.mealPosts.first.date, '오늘 저녁');
  });

  testWidgets('#5 지난 식단은 기다림·실패 없이 받은 답변을 바로 보여 준다', (tester) async {
    demo.failMode = 'AI 실패';
    await openPost(tester);
    demoNavigatorKey.currentState!.pushReplacementNamed(Routes.mealReply, arguments: 0);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(findText('AI가 식단을 확인하는 중이에요'), findsNothing);
    expect(findText('AI 답변을 받지 못했어요'), findsNothing);
    expect(findText(demo.mealPosts.first.reply), findsOneWidget);
  });

  testWidgets('#6 식단 탭 요일 칩에도 운동 탭처럼 오늘 표시', (tester) async {
    await openPost(tester);
    demoNavigatorKey.currentState!.pop();
    demo.update(() => demo.tab = 1);
    await tester.pumpAndSettle();
    expect(findText('오늘'), findsOneWidget);
    demo.update(() => demo.tab = 2);
    await tester.pumpAndSettle();
    expect(findText('오늘'), findsOneWidget);
  });

  testWidgets('#7 합계는 목표와 함께, 올린 식단이 없으면 안내', (tester) async {
    final saved = [...demo.mealPosts];
    addTearDown(() => demo.mealPosts..clear()..addAll(saved));
    demo.mealPosts.clear();
    await openPost(tester);
    demoNavigatorKey.currentState!.pop();
    demo.update(() => demo.tab = 1);
    await tester.pumpAndSettle();
    final page = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;
    await tester.scrollUntilVisible(findTextContaining('/ 목표 '), 200, scrollable: page);
    expect(findTextContaining('/ 목표 '), findsOneWidget);
    await tester.scrollUntilVisible(findTextContaining('아직 올린 식단이 없어요'), 200, scrollable: page);
    expect(findTextContaining('아직 올린 식단이 없어요'), findsOneWidget);
  });

  testWidgets('#1 다 썼으면 올리기 전에 알린다', (tester) async {
    demo.aiUsed = 5;
    await openPost(tester);
    expect(findText('이번 달 무료 횟수를 다 썼어요'), findsOneWidget);
  });
  testWidgets('결정 d1101-2 사진이나 글 하나만 있어도 올리고, 글만이면 사진 안내', (tester) async {
    await openPost(tester);
    await tap(tester, findText('올리기'));
    expect(findText('사진이나 설명을 넣어 주세요'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '닭가슴살 150g');
    await tester.pumpAndSettle();
    expect(findText('사진이 있으면 더 정확해요'), findsOneWidget);
    final before = demo.mealPosts.length;
    await tap(tester, findText('올리기'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(demo.mealPosts.length, before + 1);
    expect(demo.mealPosts.first.hasPhoto, isFalse);
    expect(findText('식단 사진'), findsNothing);
    demo.mealPosts.removeAt(0);
  });
  testWidgets('결정 d1101-3 먹었어요를 누르면 홈 작은 목표에도 반영된다', (tester) async {
    await openPost(tester);
    demo.eatenMeals.clear();
    addTearDown(demo.eatenMeals.clear);
    demoNavigatorKey.currentState!.pop();
    demo.update(() => demo.tab = 1);
    await tester.pumpAndSettle();
    expect(demo.mealPostedToday, isFalse);
    await tap(tester, findText('먹었어요').first);
    expect(demo.eatenMeals, isNotEmpty);
    expect(demo.mealPostedToday, isTrue);
  });
}
