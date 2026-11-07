import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:fitness_app/state/workout_session.dart';
import 'package:fitness_app/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'finders.dart';

/// 디자인 리뷰 11/07: 폭 360px, 큰 글씨
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

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('#2 글씨 $scale배에서 세트 줄 숫자가 잘리지 않고 완료 버튼은 48px', (tester) async {
      demo.session = WorkoutSession([SessionExercise('벤치프레스', '8~12개', 10)], atHome: false);
      addTearDown(() => demo.session = null);
      await open(tester, scale, Routes.session);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.byTooltip('1세트 완료'), 200,
          scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
      await tester.pumpAndSettle();
      // '60kg' 가 들어갈 폭 (시험 글꼴은 실제 글꼴보다 넓다)
      final cell = find.byType(TextField).first;
      expect(tester.getSize(cell).width, greaterThan(14 * scale * 3.5));
      final check = tester.getSize(find.byTooltip('1세트 완료'));
      expect(check.width, greaterThanOrEqualTo(48));
      expect(check.height, greaterThanOrEqualTo(48));
    });
  }

  testWidgets('#3 제목과 버튼 글자는 단어 중간에서 끊기지 않는다', (tester) async {
    await open(tester, 2.0, Routes.main);
    final h1 = tester.widget<Text>(find.descendant(of: find.byType(H1), matching: find.byType(Text)).first);
    expect(h1.data, keepWords(demo.greeting));
    expect(h1.semanticsLabel, demo.greeting);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AppButton('임시 저장', onPressed: () {}))));
    expect(tester.widget<Text>(find.byType(Text)).data, keepWords('임시 저장'));
  });

  testWidgets('#5 빈 무게 칸에도 kg이 보이고, 촬영 동의 안내가 첫 종목 위에 있다', (tester) async {
    await open(tester, 1.0, Routes.logWrite, arguments: '김지아');
    expect(findText('kg'), findsOneWidget);
    expect(findText('영상 0/5'), findsOneWidget);
    expect(findText('운동 영상 0/5'), findsNothing);
    final consent = tester.getTopLeft(findText('회원님 촬영 동의 후 올려 주세요')).dy;
    expect(consent, lessThan(tester.getTopLeft(findText('영상 추가')).dy));
  });

  testWidgets('#2 1세트와 10세트의 숫자 칸 시작 위치가 같다', (tester) async {
    demo.session = WorkoutSession([SessionExercise('벤치프레스', '8~12개', 10)], atHome: false);
    addTearDown(() => demo.session = null);
    await open(tester, 1.0, Routes.session);
    final x1 = tester.getTopLeft(find.byType(TextField).first).dx;
    await tester.scrollUntilVisible(find.byTooltip('10세트 완료'), 200,
        scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
    await tester.pumpAndSettle();
    final row = find.ancestor(of: find.byTooltip('10세트 완료'), matching: find.byType(Row)).first;
    final x10 = tester.getTopLeft(find.descendant(of: row, matching: find.byType(TextField)).first).dx;
    expect(x10, x1);
  });
}
