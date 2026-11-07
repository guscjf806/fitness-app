import 'package:fitness_app/main.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'finders.dart';

/// 사용자 리뷰 11/07
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

  testWidgets('#1 연결을 끊은 뒤 로그아웃하면 다음 사람에게 앞사람 일지가 보이지 않는다', (tester) async {
    await start(tester);
    demo.ptEnded = true;
    demo.logout();
    await tester.pumpAndSettle();
    expect(demo.ptEnded, isFalse);
    demo.ptEnded = true; // 데모 바로 비회원이 되어도 앞사람 일지를 보이지 않는다
    addTearDown(() => demo.ptEnded = false);
    demo.switchRole('guest');
    await tester.pumpAndSettle();
    await tester.tap(findText('로그인 없이 둘러보기'));
    await tester.pumpAndSettle();
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    expect(findText('PT 문의하기'), findsOneWidget);
    expect(findTextContaining('연결이 끊겼어요'), findsNothing);
  });
}
