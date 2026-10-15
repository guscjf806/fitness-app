import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 역할마다 모든 탭과 하위 화면(S01~S20)이 오류 없이 열리는지 확인한다.
void main() {
  setUp(() => demo.switchRole('guest'));

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
}
