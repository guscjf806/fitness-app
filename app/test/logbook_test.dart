import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 운동일지(S12~S14)·회원 관리(S18)·일지 작성(S19) (리뷰 11/02)
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    demo.switchRole('trainer');
  });

  Future<void> openRoute(WidgetTester tester, String route, {Object? args}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const FitnessApp());
    await tester.pumpAndSettle();
    demoNavigatorKey.currentState!.pushNamed(route, arguments: args);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    // 앞에서 뜬 알림이 버튼을 가리지 않게 닫는다
    ScaffoldMessenger.maybeOf(tester.element(find.byType(Scaffold).last))?.removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('#2 횟수가 비어 있으면 저장하지 않고 알린다, 적으면 저장된다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    await tap(tester, find.text('저장하고 알림 보내기'));
    expect(find.text('횟수를 적어 주세요'), findsOneWidget);
    expect(find.widgetWithText(AppBar, '일지 작성'), findsOneWidget, reason: '화면이 닫히지 않는다');
    await tester.enterText(field('횟수'), '8');
    await tester.pumpAndSettle();
    await tap(tester, find.text('저장하고 알림 보내기'));
    expect(find.widgetWithText(AppBar, '일지 작성'), findsNothing);
  });

  testWidgets('#2·#7 직접 입력 종목은 이름이 있어야 하고, 칩을 껐다 켜도 이름이 남는다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    await tap(tester, find.text('직접 입력'));
    await tester.enterText(field('횟수'), '8');
    await tester.pumpAndSettle();
    await tap(tester, find.text('저장하고 알림 보내기'));
    expect(find.text('종목 이름을 적어 주세요'), findsOneWidget);
    await tester.enterText(field('종목 이름'), 'TRX 로우');
    await tester.pumpAndSettle();
    await tap(tester, find.text('직접 입력'));
    await tap(tester, find.text('직접 입력'));
    expect(find.text('TRX 로우'), findsOneWidget);
  });
}
