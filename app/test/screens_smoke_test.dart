import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 역할마다 모든 탭과 하위 화면이 오류 없이 열리고, 주요 흐름이 기획대로 이어지는지 확인한다.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    demo.switchRole('guest');
    demo
      ..calorieCalculated = false
      ..consented = false
      ..failMode = '정상'
      ..age = '30'
      ..goal = '감량'
      ..painAreas = []
      ..weightLogs = [];
  });

  /// 폰 크기 화면 + '동작 줄이기' (동작 그림이 멈춰 있어야 화면이 안정된다)
  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const FitnessApp());
  }

  Future<void> open(WidgetTester tester, String route, {Object? args}) async {
    demoNavigatorKey.currentState!.pushNamed(route, arguments: args);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tester.takeException(), isNull, reason: route);
    demoNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.dragUntilVisible(find.text(text), find.byType(Scrollable).last, const Offset(0, -300));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('비회원 화면 S01~S06', (tester) async {
    await start(tester);
    for (final r in [Routes.body, Routes.condition, Routes.condition2, Routes.result, Routes.login, Routes.consent, Routes.generate]) {
      await open(tester, r);
    }
  });

  for (final role in ['user', 'member', 'trainer']) {
    testWidgets('$role: 탭 5개와 하위 화면', (tester) async {
      await start(tester);
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
      await open(tester, Routes.exercisePick);
      await open(tester, Routes.exerciseDetail, args: 'squat');
      await open(tester, Routes.exerciseDetail, args: 'TRX 로우 (직접 추가)');
    });
  }

  testWidgets('게스트로 시작하면 탭을 둘러보고, 저장 기능은 로그인 안내가 뜬다', (tester) async {
    await start(tester);
    await tester.tap(find.text('게스트로 시작하기'));
    await tester.pumpAndSettle();
    expect(demo.isGuest, isTrue);
    expect(demo.entered, isTrue, reason: '다시 열면 바로 탭으로 들어가야 한다');
    expect(find.text('게스트로 둘러보는 중'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      demo.update(() => demo.tab = i);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'guest tab $i');
    }
    demo.update(() => demo.tab = 2);
    await tester.pumpAndSettle();
    await tapText(tester, '오늘 운동 완료');
    expect(find.text('로그인이 필요해요'), findsOneWidget);
    expect(demo.workoutDone, isFalse);
  });

  testWidgets('게스트: 칼로리 계산 → 식단·운동 루틴 만들기 → 로그인 → 동의 → 기간 선택', (tester) async {
    await start(tester);
    await tester.tap(find.text('게스트로 시작하기'));
    await tester.pumpAndSettle();

    await tapText(tester, '내 칼로리 계산하기');
    await tapText(tester, '다음'); // S02
    await tapText(tester, '다음'); // S03
    await tester.tap(find.text('무릎'));
    await tester.pumpAndSettle();
    expect(find.textContaining('의사와 먼저 상담'), findsOneWidget);
    await tapText(tester, '결과 보기'); // S03-2
    expect(find.text('하루 소비 칼로리 (TDEE)'), findsOneWidget);
    expect(find.text('감량 목표 칼로리'), findsOneWidget);

    await tapText(tester, '식단·운동 루틴 만들기');
    expect(find.text('로그인이 필요해요'), findsOneWidget);
    await tester.tap(find.text('3초 만에 로그인하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('카카오로 시작하기'));
    await tester.pumpAndSettle();

    // S05-1 동의: 필수를 다 체크해야 시작할 수 있다
    expect(find.text('시작하기 전에'), findsOneWidget);
    await tapText(tester, '동의하고 시작하기');
    expect(demo.consented, isFalse);
    await tapText(tester, '전체 동의');
    await tapText(tester, '동의하고 시작하기');
    expect(demo.consented, isTrue);
    expect(find.text('기간 선택'), findsOneWidget);
    expect(find.textContaining('조심할 부위: 무릎'), findsOneWidget);
  });

  testWidgets('1번: 만 14세 미만은 넘어가지 못하고, 청소년 감량은 −10%로 계산한다', (tester) async {
    await start(tester);
    await tapText(tester, '내 칼로리 계산하기');
    await tester.enterText(find.widgetWithText(TextFormField, '나이 (만)'), '13');
    await tester.pumpAndSettle();
    await tapText(tester, '다음');
    expect(find.text('몸 정보'), findsOneWidget, reason: '13세는 다음으로 못 간다');
    expect(find.textContaining('만 14세 미만은'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, '나이 (만)'), '16');
    await tester.pumpAndSettle();
    expect(find.textContaining('성장기에는'), findsOneWidget);
    await tapText(tester, '다음');
    expect(find.text('운동 강도와 조건'), findsOneWidget);
  });

  testWidgets('5번: 몸무게를 기록하면 목표 칼로리 변화와 새 루틴 만들기를 보여 준다', (tester) async {
    await start(tester);
    demo.switchRole('user');
    await tester.pumpAndSettle();
    await tapText(tester, '이번 주 몸무게 기록');
    await tester.enterText(find.byType(TextField).last, '62');
    await tester.tap(find.text('기록하기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('목표 칼로리가'), findsOneWidget);
    expect(find.text('새 식단·운동 루틴 만들기'), findsOneWidget);
    expect(demo.weightLogs.single.kg, 62);
  });

  testWidgets('6번: 운동 추가하기에서 고른 운동이 오늘 루틴에 들어간다', (tester) async {
    await start(tester);
    demo.switchRole('user');
    demo.update(() => demo.tab = 2);
    await tester.pumpAndSettle();
    await tapText(tester, '+ 운동 추가');
    expect(find.text('운동 추가하기'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '버피');
    await tester.pumpAndSettle();
    await tester.tap(find.text('전신 · 맨몸')); // 검색창에도 '버피'가 있어서 목록 줄의 설명을 누른다
    await tester.pumpAndSettle();
    await tester.tap(find.text('추가 완료 (1)'));
    await tester.pumpAndSettle();
    expect(demo.addedExercises, contains('버피'));
  });

  testWidgets('7번: 실패하면 다시 시도, 횟수를 다 쓰면 구독·기다리기 안내', (tester) async {
    await start(tester);
    demo.switchRole('user');
    demo.failMode = 'AI 실패';
    await tester.pumpAndSettle();
    demoNavigatorKey.currentState!.pushNamed(Routes.generate);
    await tester.pumpAndSettle();
    await tester.tap(find.text('식단·운동 루틴 생성하기'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('식단·운동 루틴을 만들지 못했어요'), findsOneWidget);

    demo.update(() => demo.failMode = '횟수 소진');
    demoNavigatorKey.currentState!.pushNamedAndRemoveUntil(Routes.result, (_) => false);
    await tester.pumpAndSettle();
    await tapText(tester, '식단·운동 루틴 만들기');
    expect(find.text('이번 달 무료 횟수를 모두 썼어요'), findsOneWidget);
    expect(find.text('다음 달까지 기다리기'), findsOneWidget);
  });
}
