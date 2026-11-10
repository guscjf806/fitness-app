import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:fitness_app/state/workout_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'finders.dart';

/// 디자인 리뷰 11/10: 폭 360px, 큰 글씨
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    demo.switchRole('user');
  });

  Future<void> open(WidgetTester tester, double scale, String route, {Object? arguments}) async {
    tester.view.physicalSize = const Size(360 * 3, 760 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const FitnessApp());
    await tester.pumpAndSettle();
    demoNavigatorKey.currentState!.pushNamed(route, arguments: arguments);
    await tester.pumpAndSettle();
  }

  Finder page() => find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

  for (final scale in [1.0, 2.0]) {
    testWidgets('#1 글씨 $scale배에서 세트 추가·삭제 버튼 높이가 같다', (tester) async {
      demo.session = WorkoutSession([SessionExercise('벤치프레스', '8~12개', 3)], atHome: false);
      addTearDown(() => demo.session = null);
      await open(tester, scale, Routes.session);
      await tester.scrollUntilVisible(findText('세트 삭제'), 200, scrollable: page());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final del = tester.getRect(find.ancestor(of: findText('세트 삭제'), matching: find.byType(FilledButton)));
      final add = tester.getRect(find.ancestor(of: findText('+ 세트 추가'), matching: find.byType(FilledButton)));
      expect(del.height, add.height);
      if (scale >= 1.6) {
        expect(add.bottom, lessThanOrEqualTo(del.top), reason: '큰 글씨에서는 추가가 위, 삭제가 아래');
      } else {
        expect(del.right, lessThan(add.left));
        expect(add.width, greaterThan(del.width));
      }
    });
  }
}
