import 'package:fitness_app/data/mock_data.dart';
import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/screens/logbook.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:fitness_app/widgets/common.dart';
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
    demo.removedMembers.clear();
    demo.ptEnded = false;
    clearLogDrafts();
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
    await tester.enterText(field('세트').last, '3');
    await tester.pumpAndSettle();
  }

  testWidgets('#2 횟수가 비어 있으면 저장하지 않고 알린다, 적으면 저장된다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    await tap(tester, findTextContaining('회원님께 보내기'));
    expect(findText('종목을 골라 주세요'), findsWidgets, reason: '종목을 안 고르면 저장되지 않는다');
    expect(find.widgetWithText(AppBar, '일지 작성'), findsOneWidget);
    await pick(tester);
    await tap(tester, findTextContaining('회원님께 보내기'));
    expect(findText('횟수를 적어 주세요'), findsOneWidget);
    expect(find.widgetWithText(AppBar, '일지 작성'), findsOneWidget, reason: '화면이 닫히지 않는다');
    await tester.enterText(field('횟수'), '8');
    await tester.pumpAndSettle();
    await tap(tester, findTextContaining('회원님께 보내기'));
    expect(find.widgetWithText(AppBar, '일지 작성'), findsNothing);
  });

  testWidgets('11/04 #1 저장한 일지가 마지막 일지 날짜와 회원의 일지 목록에 바로 보인다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '박서연');
    expect(demo.lastLogOf('박서연'), isNull);
    await pick(tester);
    await tester.enterText(field('횟수'), '8');
    await tester.pumpAndSettle();
    await tap(tester, findTextContaining('회원님께 보내기'));
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
    await tap(tester, findTextContaining('회원님께 보내기'));
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
    await tap(tester, findTextContaining('회원님께 보내기'));
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
    await tap(tester, findTextContaining('회원님께 보내기'));
    expect(findText('2번째 줄의 횟수를 적어 주세요'), findsOneWidget);
    await tester.enterText(field('횟수').last, '10');
    await tester.pumpAndSettle();
    await tap(tester, findTextContaining('회원님께 보내기'));
    expect(demo.sentLogs['이도현']!.single.items.length, 2);
    expect(demo.sentLogs['이도현']!.single.items.last.reps, '10개');
  });

  testWidgets('11/06 #2 세트가 비었거나 0이면 저장하지 않고, 횟수·세트에는 정수만 들어간다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '박서연');
    await pick(tester);
    await tester.enterText(field('세트'), '');
    await tester.enterText(field('횟수'), '0');
    await tester.pumpAndSettle();
    await tap(tester, findTextContaining('회원님께 보내기'));
    expect(findText('횟수는 1 이상으로 적어 주세요'), findsOneWidget);
    await tester.enterText(field('횟수'), '8회');
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(find.descendant(of: field('횟수'), matching: find.byType(EditableText))).controller.text, '8',
        reason: '글자는 들어가지 않는다');
    await tap(tester, findTextContaining('회원님께 보내기'));
    expect(findText('세트를 적어 주세요'), findsOneWidget);
    expect(demo.sentLogs['박서연'], isNull);
  });

  testWidgets('결정 d1102-2 임시 저장은 회원에게 가지 않고, 다시 열면 이어서 쓴다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '박서연');
    await pick(tester);
    await tester.enterText(field('횟수'), '9');
    await tester.pumpAndSettle();
    await tap(tester, findText('임시 저장'));
    expect(demo.sentLogs['박서연'], isNull);
    expect(hasLogDraft('박서연'), isTrue);
    demoNavigatorKey.currentState!.pushNamed(Routes.logWrite, arguments: '박서연');
    await tester.pumpAndSettle();
    await tap(tester, findTextContaining('회원님께 보내기'));
    expect(demo.sentLogs['박서연']!.single.items.single.reps, '9개');
    expect(hasLogDraft('박서연'), isFalse);
  });

  testWidgets('결정 d1104-2 선생님이 회원과 연결을 끊으면 목록에서 빠진다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '박서연');
    demoNavigatorKey.currentState!.pop();
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('박서연 회원 더 보기'));
    await tap(tester, findText('연결 끊기'));
    expect(findText('박서연 회원과 연결을 끊을까요?'), findsOneWidget);
    await tap(tester, findText('연결 끊기').last);
    expect(demo.activeMembers, isNot(contains('박서연')));
    expect(findTextContaining('연결을 끊고 알렸어요'), findsOneWidget);
  });

  testWidgets('결정 d1104-1 회원이 연결을 끊어도 받은 일지를 계속 본다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    demoNavigatorKey.currentState!.pop();
    demo.switchRole('member');
    await tester.pumpAndSettle();
    demo.update(() => demo.tab = 4);
    await tester.pumpAndSettle();
    await tap(tester, findText('선생님과 연결 끊기'));
    await tap(tester, findText('연결 끊기').last);
    expect(demo.role, 'user');
    expect(demo.ptEnded, isTrue);
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    expect(findTextContaining('10월 6일 · '), findsOneWidget);
    expect(findTextContaining('계속 볼 수 있어요'), findsOneWidget);
  });

  testWidgets('결정 d1106-1 영상은 종목 줄마다 올리고 그 종목 이름이 붙는다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '박서연');
    await pick(tester);
    await tester.enterText(field('횟수'), '8');
    await tester.pumpAndSettle();
    await tap(tester, findText('영상 추가'));
    await tap(tester, findText('촬영하기'));
    expect(findTextContaining('TRX 로우 영상'), findsOneWidget);
    await tap(tester, findTextContaining('회원님께 보내기'));
    expect(demo.sentLogs['박서연']!.single.videos.single.name, startsWith('TRX 로우 영상'));
  });

  testWidgets('결정 d1106-2 시간 운동을 고르면 칸 이름이 시간(초)로 바뀐다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '박서연');
    await tap(tester, findText('종목을 골라 주세요'));
    await tester.enterText(find.byType(TextField).first, '플랭크');
    await tester.pumpAndSettle();
    await tester.tap(findText('코어 · 맨몸').first);
    await tester.pumpAndSettle();
    await tester.tap(findTextContaining('추가 완료 ('));
    await tester.pumpAndSettle();
    expect(findText('시간(초)'), findsOneWidget);
    expect(field('횟수'), findsNothing);
  });

  testWidgets('결정 d1106-3 지난 수업 불러오기로 종목과 숫자가 채워진다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    await tap(tester, findText('지난 수업 불러오기'));
    await tap(tester, findTextContaining('회원님께 보내기'));
    expect(demo.sentLogs['김지아']!.single.items.length, workoutLogs.first.items.length);
    expect(demo.sentLogs['김지아']!.single.items.first.name, workoutLogs.first.items.first.name);
    expect(demo.sentLogs['김지아']!.single.items.first.dose, workoutLogs.first.items.first.dose);
  });

  testWidgets('결정 d1104-3 보낸 일지를 고치면 수정됨이 붙고, 지울 수 있다', (tester) async {
    demo.sentLogs['박서연'] = [const WorkoutLog('10월 11일', '수업', [LogItem('TRX 로우', '체중', '8개', 3)], [], '좋아요', '꾸준해요')];
    await openRoute(tester, Routes.logWrite, args: LogEditArgs('박서연', demo.sentLogs['박서연']!.single));
    await tester.enterText(field('횟수'), '12');
    await tester.pumpAndSettle();
    await tap(tester, findText('박서연 회원님 일지 고쳐서 보내기'));
    expect(findText('박서연 회원님 일지를 고쳤어요'), findsOneWidget);
    final edited = demo.sentLogs['박서연']!.single;
    expect(edited.edited, isTrue);
    expect(edited.items.single.reps, '12개');
    expect(edited.date, '10월 11일');
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('박서연 회원 더 보기'));
    expect(findText('수정됨'), findsOneWidget);
    await tap(tester, findText('지우기'));
    await tap(tester, findText('지우기').last);
    expect(demo.sentLogs['박서연'], isEmpty);
  });

  testWidgets('11/07 #4 임시 저장을 그냥 나가면 묻지 않고, 고쳤다 버리면 초안은 그대로, 지울 수 있다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '박서연');
    await pick(tester);
    await tester.enterText(field('횟수'), '9');
    await tester.pumpAndSettle();
    await tap(tester, findText('임시 저장'));
    demoNavigatorKey.currentState!.pushNamed(Routes.logWrite, arguments: '박서연');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '일지 작성'), findsNothing, reason: '안 고쳤으면 묻지 않는다');
    demoNavigatorKey.currentState!.pushNamed(Routes.logWrite, arguments: '박서연');
    await tester.pumpAndSettle();
    await tester.enterText(field('횟수'), '20');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(findText('고친 내용만 사라지고 임시 저장은 남아요.'), findsOneWidget);
    await tap(tester, findText('버리고 나가기'));
    demoNavigatorKey.currentState!.pushNamed(Routes.logWrite, arguments: '박서연');
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(find.descendant(of: field('횟수'), matching: find.byType(EditableText))).controller.text, '9');
    await tap(tester, findText('임시 저장 지우기'));
    await tap(tester, findText('지우기'));
    expect(hasLogDraft('박서연'), isFalse);
    expect(find.widgetWithText(AppBar, '일지 작성'), findsOneWidget, reason: '지운 뒤 빈 일지로 남는다 (리뷰 11/08 #6)');
    expect(field('종목 이름'), findsNothing);
  });

  testWidgets('#2·#7 직접 입력 종목은 이름이 있어야 하고, 칩을 껐다 켜도 이름이 남는다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    await tap(tester, findText('직접 입력'));
    await tester.enterText(field('횟수'), '8');
    await tester.pumpAndSettle();
    await tap(tester, findTextContaining('회원님께 보내기'));
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

  testWidgets('결정 d1102-3 회원 메모를 적어야 코드가 만들어지고, 목록에 남은 기간과 복사가 있다', (tester) async {
    demo.inviteCodes.clear();
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
    expect(findText('회원 이름이나 메모를 적어 주세요'), findsOneWidget);
    expect(demo.inviteCodes, isEmpty);
    await tester.enterText(find.widgetWithText(TextField, '예: 김지아 회원님'), '최민수');
    await tester.pumpAndSettle();
    await tap(tester, findText('초대 코드 만들기'));
    await tester.scrollUntilVisible(findText('1회용 · 7일 남음'), 200,
        scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
    expect(findText('최민수'), findsOneWidget);
    expect(findText('1회용 · 7일 남음'), findsOneWidget);
    await tap(tester, findText('복사'));
    expect(copied, demo.inviteCodes.first.code);
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
  testWidgets('리뷰 11/08 #1 보낸 일지를 고칠 때는 임시 저장을 불러오지도 지우지도 않는다', (tester) async {
    demo.sentLogs['박서연'] = [const WorkoutLog('10월 11일', '수업', [LogItem('TRX 로우', '체중', '8개', 3)], [], '좋아요', '꾸준해요')];
    await openRoute(tester, Routes.logWrite, args: '박서연');
    await pick(tester);
    await tester.enterText(field('횟수'), '9');
    await tester.pumpAndSettle();
    await tap(tester, findText('임시 저장'));
    expect(hasLogDraft('박서연'), isTrue);
    demoNavigatorKey.currentState!.pushNamed(Routes.logWrite, arguments: LogEditArgs('박서연', demo.sentLogs['박서연']!.single));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(find.descendant(of: field('횟수'), matching: find.byType(EditableText))).controller.text, '8');
    await tester.enterText(field('횟수'), '12');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(findText('고친 내용은 사라지고 보낸 일지는 그대로예요.'), findsOneWidget);
    await tap(tester, findText('계속 쓰기'));
    await tap(tester, findTextContaining('고쳐서 보내기'));
    expect(demo.sentLogs['박서연']!.single.items.single.reps, '12개');
    expect(hasLogDraft('박서연'), isTrue);
  });
  testWidgets('리뷰 11/08 #2 임시 저장을 연 채 회원을 바꾸면 빈 일지로 시작한다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '박서연');
    await pick(tester);
    await tester.enterText(find.widgetWithText(TextFormField, '코멘트'), '스쿼트 좋아요');
    await tester.pumpAndSettle();
    await tap(tester, findText('임시 저장'));
    demoNavigatorKey.currentState!.pushNamed(Routes.logWrite, arguments: '박서연');
    await tester.pumpAndSettle();
    expect(findText('스쿼트 좋아요'), findsOneWidget);
    await tap(tester, find.byType(DropdownButtonFormField<String>));
    await tap(tester, findText('김지아').last);
    expect(findText('스쿼트 좋아요'), findsNothing);
    expect(field('종목 이름'), findsNothing);
    await tester.scrollUntilVisible(findText('김지아 회원님께 보내기'), 200,
        scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
    expect(findText('김지아 회원님께 보내기'), findsOneWidget);
    expect(hasLogDraft('박서연'), isTrue);
  });
  testWidgets('리뷰 11/08 #3 초대 코드를 만들면 알리고, 지울 수 있다', (tester) async {
    demo.inviteCodes.clear();
    await openRoute(tester, Routes.logWrite, args: '김지아');
    demoNavigatorKey.currentState!.pop();
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '예: 김지아 회원님'), '최민수');
    await tester.pumpAndSettle();
    await tap(tester, findText('초대 코드 만들기'));
    expect(findText("'최민수' 초대 코드를 만들었어요. 바로 아래에 있어요"), findsOneWidget);
    await tap(tester, findText('지우기'));
    await tap(tester, findText('지우기').last);
    expect(demo.inviteCodes, isEmpty);
  });
  testWidgets('리뷰 11/08 #4 연결을 끊으면 그 회원의 임시 저장도 지운다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '박서연');
    await pick(tester);
    await tap(tester, findText('임시 저장'));
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('박서연 회원 더 보기'));
    await tap(tester, findText('연결 끊기'));
    expect(findTextContaining('임시 저장한 일지도 함께 지워져요'), findsOneWidget);
    await tap(tester, findText('연결 끊기').last);
    expect(hasLogDraft('박서연'), isFalse);
  });
  testWidgets('디자인 리뷰 11/08 #1 보내기와 임시 저장은 전체 폭으로 위아래에 있다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    final page = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;
    await tester.scrollUntilVisible(findText('임시 저장'), 200, scrollable: page);
    await tester.pumpAndSettle();
    final send = tester.getRect(find.ancestor(of: findText('김지아 회원님께 보내기'), matching: find.byType(FilledButton)));
    final draft = tester.getRect(find.ancestor(of: findText('임시 저장'), matching: find.byType(FilledButton)));
    expect(send.width, draft.width);
    expect(send.bottom, lessThan(draft.top));
  });
  testWidgets('디자인 리뷰 11/08 #3·#4 카드 제목이 같은 모양이고, 만든 초대 코드에 제목이 붙는다', (tester) async {
    demo.inviteCodes.clear();
    await openRoute(tester, Routes.logWrite, args: '김지아');
    demoNavigatorKey.currentState!.pop();
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    expect(find.ancestor(of: findText('이번 주 미션'), matching: find.byType(FieldLabel)), findsOneWidget);
    expect(findText('만든 초대 코드 1개'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, '예: 김지아 회원님'), '최민수');
    await tester.pumpAndSettle();
    await tap(tester, findText('초대 코드 만들기'));
    await tester.scrollUntilVisible(findText('1회용 · 7일 남음'), 200,
        scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
    expect(findText('만든 초대 코드 1개'), findsOneWidget);
  });
  testWidgets('결정 d1107-3 연결을 끊기 전에 다시 잇는 방법을 알린다', (tester) async {
    await openRoute(tester, Routes.logWrite, args: '김지아');
    demoNavigatorKey.currentState!.pop();
    demo.update(() => demo.tab = 3);
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('박서연 회원 더 보기'));
    await tap(tester, findText('연결 끊기'));
    expect(findTextContaining('새 PT 코드를 만들어 회원님께 드려야 해요'), findsOneWidget);
  });
}
