import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:fitness_app/state/workout_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 좁은 폰(360px)과 큰 글씨(1.3배)에서도 화면이 넘치지 않는지 확인한다 (디자인 리뷰 10/30 #2·#3)
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    demo.switchRole('user');
  });

  Future<void> openNarrow(WidgetTester tester, String route) async {
    tester.view.physicalSize = const Size(360 * 3, 760 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const FitnessApp());
    await tester.pumpAndSettle();
    demoNavigatorKey.currentState!.pushNamed(route);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  testWidgets('내 기록 배지가 넘치지 않는다', (tester) async {
    await openNarrow(tester, Routes.records);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('한 달 운동 20회'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('운동 진행 세트 줄이 10세트여도 넘치지 않는다', (tester) async {
    demo.session = WorkoutSession([SessionExercise('벤치프레스', '8~12개', 10)], atHome: false);
    addTearDown(() => demo.session = null);
    await openNarrow(tester, Routes.session);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('10세트'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // '10세트'가 두 줄로 꺾이지 않는다 (한 줄 높이: 14px × 1.3배 × 줄 간격 1.5 ≈ 27px)
    expect(tester.getSize(find.text('10세트')).height, lessThan(32));
  });
}
