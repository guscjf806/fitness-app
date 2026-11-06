import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'finders.dart';

/// 사용자 리뷰 11/06
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    demo.switchRole('user');
  });

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const FitnessApp());
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, String route) async {
    demoNavigatorKey.currentState!.pushNamed(route);
    await tester.pumpAndSettle();
  }

  testWidgets('#3 쉬는 날이 아니면 오늘 운동 완료가 목표에 있다', (tester) async {
    await start(tester);
    expect(findText('오늘 운동 완료'), demo.week[0].isRest ? findsNothing : findsOneWidget);
  });
  testWidgets('#6 로그인 화면을 뒤로 나가면 이어 가기가 지워지고, 로그인 쪽으로 가면 남는다', (tester) async {
    demo.switchRole('guest');
    demo.consented = false;
    await start(tester);
    demo.continueToGenerate = true;
    await open(tester, Routes.login);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(demo.continueToGenerate, isFalse);

    demo.continueToGenerate = true;
    await open(tester, Routes.login);
    await tester.tap(findText('카카오로 시작하기'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '시작하기 전에'), findsOneWidget);
    expect(demo.continueToGenerate, isTrue);
    demo.continueToGenerate = false;
  });
}
