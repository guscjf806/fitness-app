import 'package:fitness_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('시작 화면에서 몸 정보 → 조건 → 결과까지 이동한다', (tester) async {
    await tester.pumpWidget(const FitnessApp());
    expect(find.text('내 칼로리 계산하기'), findsOneWidget);

    await tester.tap(find.text('내 칼로리 계산하기'));
    await tester.pumpAndSettle();
    expect(find.text('몸 정보'), findsOneWidget);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('결과 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('결과 보기'));
    await tester.pumpAndSettle();
    expect(find.text('하루 소비 칼로리 (TDEE)'), findsOneWidget);
  });
}
