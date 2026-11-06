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
    testWidgets('#1 글씨 $scale배에서 달력이 넘치지 않는다', (tester) async {
      await start(tester, scale);
      demoNavigatorKey.currentState!.pushNamed(Routes.records);
      await tester.pumpAndSettle();
      await tester.tap(findText('통계'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(workoutLogs, isNotEmpty);
    });
  }
  for (final scale in [1.3, 2.0]) {
    testWidgets('#2 글씨 $scale배에서 운동 탭·일지 상세가 넘치지 않고 이름이 쪼개지지 않는다', (tester) async {
      await start(tester, scale);
      demo.update(() => demo.tab = 2);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      demoNavigatorKey.currentState!.pushNamed(Routes.logDetail, arguments: workoutLogs.first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final name = findText(workoutLogs.first.items.first.name);
      expect(tester.getSize(name).height, lessThan(14 * scale * 1.6), reason: '한 줄로 들어간다');
    });
  }
  testWidgets('결정 dd1103-font 버튼 글자도 Pretendard를 쓴다', (tester) async {
    await start(tester, 1);
    demo.switchRole('trainer');
    await tester.pumpAndSettle();
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    final label = tester.element(findText('일지 작성').first);
    expect(DefaultTextStyle.of(label).style.fontFamily, 'Pretendard');
  });
  testWidgets('결정 dd1103-font 화면 위 제목도 Pretendard를 쓴다', (tester) async {
    await start(tester, 1);
    demoNavigatorKey.currentState!.pushNamed(Routes.condition);
    await tester.pumpAndSettle();
    final title = tester.element(findText('운동 강도와 조건'));
    expect(DefaultTextStyle.of(title).style.fontFamily, 'Pretendard');
  });
  testWidgets('결정 d1030-1 선생님 홈에는 회원 목록이 나오고 개인 목표는 없다', (tester) async {
    await start(tester, 1);
    demo.switchRole('trainer');
    await tester.pumpAndSettle();
    expect(findText('일지 쓸 회원'), findsOneWidget);
    expect(findText('오늘의 작은 목표'), findsNothing);
    expect(findText('김지아'), findsWidgets);
  });
  testWidgets('결정 dd1104-favorite 찜한 운동은 앱을 다시 켜도 남고 모아 볼 수 있다', (tester) async {
    demo.favorites
      ..clear()
      ..add('deadlift');
    addTearDown(demo.favorites.clear);
    await demo.save();
    demo.favorites.clear();
    await demo.load();
    expect(demo.favorites, contains('deadlift'));
    await start(tester, 1);
    demoNavigatorKey.currentState!.pushNamed(Routes.exercisePick);
    await tester.pumpAndSettle();
    await tester.tap(findText('즐겨찾기'));
    await tester.pumpAndSettle();
    expect(findTextContaining('전체 1개'), findsOneWidget);
  });
}
