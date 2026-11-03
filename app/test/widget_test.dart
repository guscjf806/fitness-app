import 'package:fitness_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'finders.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('시작 화면에서 몸 정보 → 조건 → 식단·몸 상태 → 결과까지 이동한다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FitnessApp());
    expect(findText('내 칼로리 계산하기'), findsOneWidget);

    await tester.tap(findText('내 칼로리 계산하기'));
    await tester.pumpAndSettle();
    expect(findText('몸 정보'), findsOneWidget);

    // 몸 정보 칸이 한 줄에 하나씩이라 '다음'이 아래에 있다
    await tester.dragUntilVisible(findText('다음'), find.byType(Scrollable).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(findText('다음'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(findText('다음'), find.byType(Scrollable).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(findText('다음'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(findText('결과 보기'), find.byType(Scrollable).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(findText('결과 보기'));
    await tester.pumpAndSettle();
    expect(findText('하루에 쓰는 칼로리'), findsOneWidget);
  });
}
