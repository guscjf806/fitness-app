import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:fitness_app/state/workout_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'finders.dart';


/// 디자인 리뷰 11/04
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    demo.switchRole('user');
  });

  Future<void> open(WidgetTester tester, String route) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const FitnessApp());
    await tester.pumpAndSettle();
    demoNavigatorKey.currentState!.pushNamed(route);
    await tester.pumpAndSettle();
  }

  testWidgets('#1 빈 곳을 누르면 키보드(입력 칸 포커스)가 닫힌다', (tester) async {
    await open(tester, Routes.ptCode);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextField>(), isNotNull);
    await tester.tapAt(const Offset(200, 700));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextField>(), isNull);
  });
  testWidgets('#2 세트를 지운 뒤 되돌리면 체크·무게가 그대로 돌아온다', (tester) async {
    demo.session = WorkoutSession([SessionExercise('벤치프레스', '8~12개', 3)], atHome: false);
    addTearDown(() => demo.session = null);
    final sets = demo.session!.items.first.sets;
    sets.last
      ..kg = '60'
      ..done = true;
    final last = sets.last;
    await open(tester, Routes.session);
    await tester.scrollUntilVisible(findText('세트 삭제'), 200,
        scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
    await tester.pumpAndSettle();
    await tester.tap(findText('세트 삭제'));
    await tester.pumpAndSettle();
    expect(sets.length, 2);
    expect(findText('3세트를 지웠어요'), findsOneWidget);
    await tester.tap(findText('되돌리기'));
    await tester.pumpAndSettle();
    expect(sets.length, 3);
    expect(sets.last, same(last));
  });
}
