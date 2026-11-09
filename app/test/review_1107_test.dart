import 'package:fitness_app/data/mock_data.dart';
import 'package:fitness_app/main.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:fitness_app/widgets/common.dart';
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
    expect(findText('카카오톡으로 PT 문의하기'), findsOneWidget);
    expect(findTextContaining('연결이 끊겼어요'), findsNothing);
  });
  testWidgets('#2 일부만 끝내면 운동 탭에 한 운동만 체크로 보인다', (tester) async {
    await start(tester);
    final items = demo.week[0].items;
    demo.update(() {
      demo.workoutDone = true;
      demo.checked
        ..clear()
        ..add(0);
      demo.tab = 2;
    });
    addTearDown(() {
      demo.workoutDone = false;
      demo.checked.clear();
    });
    await tester.pumpAndSettle();
    final on = tester.widgetList<CheckCircle>(find.byType(CheckCircle)).where((c) => c.on).length;
    expect(on, 1);
    expect(items.length, greaterThan(1));
  });
  testWidgets('#3 로그아웃하면 앞사람 기록이 남지 않고, 로그인 방법 안내만 남는다', (tester) async {
    await start(tester);
    demo.lastWeights['벤치프레스'] = '60';
    demo.favorites.add('deadlift');
    demo.eatenMeals.add('아침');
    demo.homeGear = ['덤벨'];
    demo.restMode = true;
    demo.lastLoginProvider = '카카오';
    addTearDown(() => demo.lastLoginProvider = null);
    demo.logout();
    await tester.pumpAndSettle();
    expect(demo.lastWeights, isEmpty);
    expect(demo.favorites, isEmpty);
    expect(demo.eatenMeals, isEmpty);
    expect(demo.homeGear, isEmpty);
    expect(demo.restMode, isFalse);
    expect(demo.lastLoginProvider, '카카오');
  });
  testWidgets('#6 선생님 홈에서 고른 회원이 미션 칸에 미리 골라지고, 회원이 없으면 안내만', (tester) async {
    await start(tester);
    demo.switchRole('trainer');
    addTearDown(() {
      demo.removedMembers.clear();
      demo.missionMember = null;
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(findText('이도현').last, 100, scrollable: find.byType(Scrollable).first);
    await tester.tap(findText('이도현').last);
    await tester.pumpAndSettle();
    expect(demo.tab, 3);
    expect(findText('이도현 회원님께 보내기'), findsOneWidget);
    demo.update(() {
      demo.removedMembers.addAll(members);
      demo.tab = 0;
    });
    await tester.pumpAndSettle();
    expect(findTextContaining('연결된 회원이 없어요'), findsOneWidget);
    expect(findText('이번 주 미션'), findsNothing);
  });
}
