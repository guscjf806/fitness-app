import 'package:fitness_app/data/mock_data.dart';
import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'finders.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 운동일지(S12~S14)·회원 관리(S18)·일지 작성(S19) (리뷰 11/02)
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    demo.switchRole('trainer');
    demo.sentLogs.clear();
    demo.unseenLogs
      ..clear()
      ..add(workoutLogs.first);
  });

  Future<void> openRoute(WidgetTester tester, String route, {Object? args}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const FitnessApp());
    await tester.pumpAndSettle();
    demoNavigatorKey.currentState!.pushNamed(route, arguments: args);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    // 앞에서 뜬 알림이 버튼을 가리지 않게 닫는다
    ScaffoldMessenger.maybeOf(tester.element(find.byType(Scaffold).last))?.removeCurrentSnackBar();
    await tester.pumpAndSettle();
    // 긴 화면에서 아직 그려지지 않은 버튼은 스크롤해서 찾는다
    if (f.evaluate().isEmpty) {
      await tester.scrollUntilVisible(f, 200,
          scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  /// 마지막 줄에 종목을 넣는다 (직접 입력)
  Future<void> pick(WidgetTester tester) async {
    await tap(tester, findText('직접 입력').last);
    await tester.enterText(field('종목 이름').last, 'TRX 로우');
    await tester.pumpAndSettle();
  }

  testWidgets('#2 횟수가 비어 있으면 저장하지 않고 알린다, 적으면 저장된다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    await tap(tester, findText('저장하고 알림 보내기'));
    expect(findText('종목을 골라 주세요'), findsWidgets, reason: '종목을 안 고르면 저장되지 않는다');
    expect(find.widgetWithText(AppBar, '일지 작성'), findsOneWidget);
    await pick(tester);
    await tap(tester, findText('저장하고 알림 보내기'));
    expect(findText('횟수를 적어 주세요'), findsOneWidget);
    expect(find.widgetWithText(AppBar, '일지 작성'), findsOneWidget, reason: '화면이 닫히지 않는다');
    await tester.enterText(field('횟수'), '8');
    await tester.pumpAndSettle();
    await tap(tester, findText('저장하고 알림 보내기'));
    expect(find.widgetWithText(AppBar, '일지 작성'), findsNothing);
  });

  testWidgets('11/04 #1 저장한 일지가 마지막 일지 날짜와 회원의 일지 목록에 바로 보인다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '박서연');
    expect(demo.lastLogOf('박서연'), isNull);
    await pick(tester);
    await tester.enterText(field('횟수'), '8');
    await tester.pumpAndSettle();
    await tap(tester, findText('저장하고 알림 보내기'));
    expect(demo.lastLogOf('박서연'), '10월 12일');
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    expect(findText('마지막 일지 10월 12일'), findsOneWidget);
    // 김지아에게 쓰면 PT 회원 화면의 목록 맨 위에 보인다
    demoNavigatorKey.currentState!.pushNamed(Routes.logWrite, arguments: '김지아');
    await tester.pumpAndSettle();
    await pick(tester);
    await tester.enterText(field('횟수'), '10');
    await tester.pumpAndSettle();
    await tap(tester, findText('저장하고 알림 보내기'));
    demo.switchRole('member');
    await tester.pumpAndSettle();
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    expect(findTextContaining('10월 12일 · '), findsOneWidget);
    expect(demo.logsOf('김지아').first.date, '10월 12일');
  });

  testWidgets('11/04 #4 수업 날짜를 고르면 그 날짜로 저장되고, 옛날 날짜여도 마지막 일지는 최신을 유지', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    expect(findText('10월 12일 (월) · 오늘'), findsOneWidget);
    expect(findText('이 날짜에 출석 도장이 찍혀요'), findsOneWidget);
    await tap(tester, findText('10월 12일 (월) · 오늘'));
    await tap(tester, findText('5'));
    await tap(tester, findText('확인'));
    expect(findText('10월 5일 (월)'), findsOneWidget);
    await pick(tester);
    await tester.enterText(field('횟수'), '8');
    await tester.pumpAndSettle();
    await tap(tester, findText('저장하고 알림 보내기'));
    expect(demo.sentLogs['김지아']!.single.date, '10월 5일');
    expect(demo.lastLogOf('김지아'), '10월 6일');
    expect(demo.logsOf('김지아').map((l) => l.date).take(2), ['10월 6일', '10월 5일']);
  });

  testWidgets('11/04 #6 틀린 코드는 이유를 알려 주고 코드를 지우지 않으며 연결하지 않는다', (tester) async {
    demo.switchRole('user');
    addTearDown(() => demo.failMode = '정상');
    await openRoute(tester, Routes.ptCode);
    demo.failMode = '코드 만료';
    await tester.enterText(find.byType(TextField), '482915');
    await tester.pumpAndSettle();
    await tap(tester, findText('연결하기'));
    expect(findText('기간이 지난 코드예요. 선생님께 새 코드를 받아 주세요'), findsOneWidget);
    expect(demo.role, 'user');
    expect(findText('482915'), findsOneWidget);
    // 고쳐 쓰기 시작하면 안내가 사라지고, 정상이면 연결된다
    await tester.enterText(find.byType(TextField), '482916');
    await tester.pumpAndSettle();
    expect(findText('기간이 지난 코드예요. 선생님께 새 코드를 받아 주세요'), findsNothing);
    demo.failMode = '정상';
    await tap(tester, findText('연결하기'));
    expect(demo.role, 'member');
  });

  testWidgets('11/04 #7 안 본 일지에만 새 일지 표시, 열어 보면 사라진다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    demo.switchRole('member');
    await tester.pumpAndSettle();
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    expect(findText('새 일지'), findsOneWidget);
    await tap(tester, findTextContaining('10월 6일 · '));
    demoNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(findText('새 일지'), findsNothing);
  });

  testWidgets('11/04 #7 로그인하지 않은 일반 안내: 예시 표시, 홈 인사에 게스트님 없음', (tester) async {
    demo.switchRole('user');
    await tester.pumpWidget(const FitnessApp());
    await tester.pumpAndSettle();
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    expect(findText('예시: PT를 시작하면 이렇게 받아요'), findsOneWidget);
    demo.switchRole('guest');
    expect(demo.greeting, '안녕하세요');
  });

  testWidgets('결정 dd1101-logwrite 종목 줄을 늘려 저장하고, 빈 줄은 몇 번째인지 알린다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '이도현');
    await pick(tester);
    await tester.enterText(field('횟수'), '8');
    await tester.pumpAndSettle();
    await tap(tester, findText('+ 종목 추가'));
    expect(findText('종목 2'), findsOneWidget);
    await pick(tester);
    await tap(tester, findText('저장하고 알림 보내기'));
    expect(findText('2번째 줄의 횟수를 적어 주세요'), findsOneWidget);
    await tester.enterText(field('횟수').last, '10');
    await tester.pumpAndSettle();
    await tap(tester, findText('저장하고 알림 보내기'));
    expect(demo.sentLogs['이도현']!.single.items.length, 2);
    expect(demo.sentLogs['이도현']!.single.items.last.reps, '10개');
  });

  testWidgets('#2·#7 직접 입력 종목은 이름이 있어야 하고, 칩을 껐다 켜도 이름이 남는다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    await tap(tester, findText('직접 입력'));
    await tester.enterText(field('횟수'), '8');
    await tester.pumpAndSettle();
    await tap(tester, findText('저장하고 알림 보내기'));
    expect(findText('종목 이름을 적어 주세요'), findsOneWidget);
    await tester.enterText(field('종목 이름'), 'TRX 로우');
    await tester.pumpAndSettle();
    await tap(tester, findText('직접 입력'));
    await tap(tester, findText('직접 입력'));
    expect(findText('TRX 로우'), findsOneWidget);
  });

  testWidgets('#3 적은 게 있으면 뒤로 갈 때 버릴지 묻는다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    await tester.enterText(field('횟수'), '8');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(findText('작성 중인 일지를 버릴까요?'), findsOneWidget);
    await tap(tester, findText('버리고 나가기'));
    expect(find.widgetWithText(AppBar, '일지 작성'), findsNothing);
  });

  testWidgets('#4 빈 미션은 보내지 않고, 고른 회원의 지금 미션을 보여 준다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    demoNavigatorKey.currentState!.pop();
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    expect(findTextContaining('지금 미션: '), findsOneWidget);
    final before = Map.of(demo.missions);
    await tap(tester, findText('김지아 회원님 미션 바꾸기'));
    expect(findText('미션 내용을 적어 주세요'), findsOneWidget);
    expect(demo.missions, before);
  });

  testWidgets('11/04 #2 버튼에 받는 사람이 보이고, 있던 미션은 물어본 뒤에 바꾼다', (tester) async {
    demo.missions
      ..clear()
      ..['김지아'] = '처음 미션';
    await openRoute(tester, Routes.logWrite, args: '김지아');
    demoNavigatorKey.currentState!.pop();
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '예: 이번 주 운동 3회 + 단백질 챙기기'), '새 미션');
    await tester.pumpAndSettle();
    await tap(tester, findText('김지아 회원님 미션 바꾸기'));
    expect(findText('김지아 회원님 미션을 바꿀까요?'), findsOneWidget);
    await tap(tester, findText('그대로 두기'));
    expect(demo.missions['김지아'], '처음 미션');
    await tap(tester, findText('김지아 회원님 미션 바꾸기'));
    await tap(tester, findText('바꾸기').last);
    expect(demo.missions['김지아'], '새 미션');
  });

  testWidgets('#5 초대 코드를 복사할 수 있고, 코드가 있으면 버튼 이름이 새 코드 만들기', (tester) async {
    demo.inviteCode = null;
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await openRoute(tester, Routes.logWrite, args: '김지아');
    demoNavigatorKey.currentState!.pop();
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    await tap(tester, findText('초대 코드 만들기'));
    expect(findText('새 코드 만들기'), findsOneWidget);
    await tap(tester, findText('복사'));
    expect(findText('초대 코드를 복사했어요'), findsOneWidget);
    expect(copied, demo.inviteCode);
  });

  test('#6 무게 → 횟수 → 세트 순서로 표기한다', () {
    expect(const LogItem('바벨 스쿼트', '60kg', '8개', 4).dose, '60kg · 8개 × 4세트');
  });

  testWidgets('#7 회원마다 마지막 일지 날짜가 다르고, 없으면 안내', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    demoNavigatorKey.currentState!.pop();
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    final page = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;
    await tester.scrollUntilVisible(findText('아직 쓴 일지가 없어요'), 200, scrollable: page);
    expect(findText('마지막 일지 10월 6일'), findsOneWidget);
    expect(findText('마지막 일지 10월 2일'), findsOneWidget);
  });
}
