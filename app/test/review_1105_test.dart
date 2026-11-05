import 'package:fitness_app/main.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:fitness_app/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'finders.dart';

/// 사용자 리뷰 11/05: 실제 로그인 후의 흐름. Supabase 없이 로그인 이벤트만 흉내 낸다
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    demo.switchRole('guest');
    demo.consented = false;
  });

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const FitnessApp());
    await tester.pumpAndSettle();
  }

  testWidgets('#1 되돌리기가 있는 알림 띠도 6초 뒤 저절로 사라진다', (tester) async {
    await start(tester);
    toast(demoNavigatorKey.currentContext!, '지웠어요', actionLabel: '되돌리기', onAction: () {});
    await tester.pumpAndSettle();
    expect(findText('지웠어요'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(findText('지웠어요'), findsNothing);
  });
}
