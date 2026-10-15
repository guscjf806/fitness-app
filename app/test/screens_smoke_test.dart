import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 역할마다 모든 탭과 하위 화면(S01~S20)이 오류 없이 열리는지 확인한다.
void main() {
  setUp(() {
    demo.switchRole('guest');
    demo.calorieCalculated = false;
  });

  Future<void> open(WidgetTester tester, String route, {Object? args}) async {
    demoNavigatorKey.currentState!.pushNamed(route, arguments: args);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tester.takeException(), isNull, reason: route);
    demoNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
  }

  testWidgets('비회원 화면 S01~S06', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const FitnessApp());
    for (final r in [Routes.body, Routes.condition, Routes.result, Routes.login, Routes.generate]) {
      await open(tester, r);
    }
  });

  for (final role in ['user', 'member', 'trainer']) {
    testWidgets('$role: 탭 5개와 하위 화면', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const FitnessApp());
      demo.switchRole(role);
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        demo.update(() => demo.tab = i);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$role tab $i');
      }
      await open(tester, Routes.mealPost);
      await open(tester, Routes.mealReply, args: 0);
      await open(tester, Routes.logDetail, args: 0);
      await open(tester, Routes.ptCode);
      await open(tester, Routes.subscribe);
      await open(tester, Routes.logWrite, args: '김지아');
      await open(tester, Routes.records);
    });
  }

  testWidgets('게스트로 시작하면 탭을 둘러보고, 저장 기능은 로그인 안내가 뜬다', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const FitnessApp());
    await tester.tap(find.text('게스트로 시작하기'));
    await tester.pumpAndSettle();
    expect(demo.isGuest, isTrue);
    expect(find.text('게스트로 둘러보는 중'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      demo.update(() => demo.tab = i);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'guest tab $i');
    }
    demo.update(() => demo.tab = 2);
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(find.text('오늘 운동 완료'), find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('오늘 운동 완료'));
    await tester.pumpAndSettle();
    expect(find.text('로그인이 필요해요'), findsOneWidget);
    expect(demo.workoutDone, isFalse);
  });

  testWidgets('게스트: 칼로리 계산 후 식단·운동 루틴 만들기는 로그인 뒤 기간 선택으로 이어진다', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const FitnessApp());
    await tester.tap(find.text('게스트로 시작하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('내 칼로리 계산하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(find.text('결과 보기'), find.byType(ListView).last, const Offset(0, -300));
    await tester.tap(find.text('결과 보기'));
    await tester.pumpAndSettle();
    expect(find.text('하루 소비 칼로리 (TDEE)'), findsOneWidget);
    expect(find.text('감량 목표 칼로리'), findsOneWidget);

    await tester.tap(find.text('식단·운동 루틴 만들기'));
    await tester.pumpAndSettle();
    expect(find.text('로그인이 필요해요'), findsOneWidget);
    await tester.tap(find.text('3초 만에 로그인하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('카카오로 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('기간 선택'), findsOneWidget);
    expect(demo.loggedIn, isTrue);
  });
}
