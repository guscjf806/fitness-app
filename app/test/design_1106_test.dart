import 'package:fitness_app/data/mock_data.dart';
import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'finders.dart';

/// 디자인 리뷰 11/06: 폭 360px, 큰 글씨
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    demo.switchRole('user');
  });

  Future<void> start(WidgetTester tester, double scale) async {
    tester.view.physicalSize = const Size(360 * 3, 760 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const FitnessApp());
    await tester.pumpAndSettle();
  }

  for (final scale in [1.3, 2.0]) {
    testWidgets('#1 글씨 \${scale}배에서 달력이 넘치지 않는다', (tester) async {
      await start(tester, scale);
      demoNavigatorKey.currentState!.pushNamed(Routes.records);
      await tester.pumpAndSettle();
      await tester.tap(findText('통계'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(workoutLogs, isNotEmpty);
    });
  }
}
