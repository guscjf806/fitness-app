import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
}
