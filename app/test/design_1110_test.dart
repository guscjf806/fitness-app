import 'package:fitness_app/data/mock_data.dart';
import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/screens/meal.dart';
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
  testWidgets('리뷰 11/11 #6 결과가 없으면 검색·필터를 한 번에 지운다', (tester) async {
    await open(tester, 1.0, Routes.exercisePick, arguments: 3);
    await tester.enterText(find.byType(TextField).first, '없는운동이름');
    await tester.pumpAndSettle();
    expect(find.byTooltip('검색어 지우기'), findsOneWidget);
    await tester.scrollUntilVisible(findText('검색·필터 지우기'), 200, scrollable: page());
    await tester.tap(findText('검색·필터 지우기'));
    await tester.pumpAndSettle();
    expect(findText('검색·필터 지우기'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, '');
  });

  testWidgets('디자인 리뷰 11/13 #1 큰 글씨와 키보드에서 칼로리 칸을 비워도 그리기 오류가 없다', (tester) async {
    demo.mealPosts.insert(0, const MealPost('오늘 점심', '비빔밥', '좋아요', isToday: true, kcal: 620));
    await open(tester, 2.0, Routes.mealReply, arguments: const MealReplyArgs(0));
    await tester.scrollUntilVisible(findText('고치기'), 200, scrollable: page());
    await tester.tap(findText('고치기'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 290 * 3);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('디자인 리뷰 11/13 #3 글씨 $scale배에서 응원 스탬프 버튼 높이가 같다', (tester) async {
      demo.switchRole('trainer');
      await open(tester, scale, Routes.logWrite, arguments: '김지아');
      await tester.scrollUntilVisible(findText('꾸준해요'), 200, scrollable: page());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      double h(String t) => tester.getSize(find.ancestor(of: findText(t), matching: find.byType(Material)).first).height;
      expect(h('참 잘했어요'), h('꾸준해요'));
      expect(h('꾸준해요'), h('자세 좋아요'));
    });
  }
}
