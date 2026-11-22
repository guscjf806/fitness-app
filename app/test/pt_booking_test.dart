import 'package:fitness_app/logic/pt_booking.dart';
import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:fitness_app/widgets/pt_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'finders.dart';

/// PT 예약 연습용 화면 (docs/PT예약_설계.md, 결정 d1117-pt1~5)
void main() {
  final now = DateTime(2026, 11, 17, 10);

  group('예약 규칙', () {
    test('5시간 안에 답이 없으면 자동 거절', () {
      final b = PtBooking(member: '김지아', start: DateTime(2026, 11, 19, 19), requestedAt: now);
      expect(ptStatusAt(b, now.add(const Duration(hours: 4, minutes: 59))), PtStatus.requested);
      expect(ptStatusAt(b, now.add(const Duration(hours: 5))), PtStatus.autoRejected);
      expect(ptCharged(b..status = ptStatusAt(b, now.add(const Duration(hours: 5)))), isFalse);
    });

    test('급한 신청은 받고, 답 없이 수업 시간이 지나면 지난 신청 (차감 없음)', () {
      final b = PtBooking(member: '김지아', start: DateTime(2026, 11, 17, 13), requestedAt: now);
      expect(b.urgent, isTrue);
      expect(ptStatusAt(b, DateTime(2026, 11, 17, 12, 59)), PtStatus.requested);
      expect(ptStatusAt(b, DateTime(2026, 11, 17, 13)), PtStatus.expired);
    });

    test('24시간 전까지는 무료 취소, 그 뒤는 차감', () {
      final b = PtBooking(member: '김지아', start: DateTime(2026, 11, 18, 10), requestedAt: now, status: PtStatus.approved);
      expect(ptFreeCancel(b, now), isTrue);
      expect(ptFreeCancel(b, now.add(const Duration(minutes: 1))), isFalse);
      b.status = PtStatus.lateCancelled;
      expect(ptCharged(b), isTrue);
      b.waived = true;
      expect(ptCharged(b), isFalse, reason: '이번만 빼 주기');
    });
  });

  test('디자인 리뷰 11/18 #4 남은 시간에 0이 보이지 않는다', () {
    expect(ptLeftText(const Duration(hours: 1)), '1시간');
    expect(ptLeftText(const Duration(minutes: 40)), '40분');
    expect(ptLeftText(const Duration(hours: 2, minutes: 15)), '2시간 15분');
    expect(ptLeftText(const Duration(seconds: 20)), '1분');
  });

  test('리뷰 11/19 #1 시간이 지난 확정 수업은 선생님 확인 기다리는 중', () {
    final b = PtBooking(member: '김지아', start: DateTime(2026, 11, 17, 9), requestedAt: now.subtract(const Duration(days: 1)), status: PtStatus.approved);
    expect(ptMemberLabel(b, now), '선생님 확인 기다리는 중');
    expect(ptMemberLabel(b, DateTime(2026, 11, 17, 8)), '예약 확정');
  });

  group('리뷰 11/22', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      demo.resetPt();
    });

    test('#1 잡힌 수업 수를 센다 (앞으로의 신청·확정 + 지났지만 처리 안 한 확정)', () {
      final now = DateTime.now();
      // 박서연: 앞으로의 신청 1 + 어제 처리 안 한 확정 1
      expect(demo.ptBookedOf('박서연', now), 2);
      expect(demo.ptBookedOf('김지아', now), 1);
    });

    test('#2 남은 PT 횟수는 앱을 다시 켜도 남는다', () async {
      demo.ptLeft['김지아'] = 16;
      await demo.save();
      demo.ptLeft['김지아'] = 6;
      await demo.load();
      expect(demo.ptLeft['김지아'], 16);
    });
  });

  group('화면', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      demo.resetPt();
    });

    Future<void> open(WidgetTester tester, String role, String route) async {
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(tester.view.reset);
      demo.switchRole(role);
      await tester.pumpWidget(const FitnessApp());
      await tester.pumpAndSettle();
      demoNavigatorKey.currentState!.pushNamed(route);
      await tester.pumpAndSettle();
    }

    testWidgets('회원은 빈 시간을 신청하고, 승인 기다리는 중으로 보인다', (tester) async {
      await open(tester, 'member', Routes.ptBooking);
      expect(findText('수업 예약'), findsWidgets);
      expect(findText('6회'), findsOneWidget);
      // 내일로 가서 신청 가능한 첫 칸을 누른다
      await tester.tap(findText('${DateTime.now().add(const Duration(days: 1)).day}일').first);
      await tester.pumpAndSettle();
      final before = demo.ptBookings.length;
      // 아래 범례에도 '신청 가능' 글이 있어서 시간 칸 안에서만 찾는다 (일요일엔 칸이 없다)
      final slot = find.descendant(of: find.byType(TimeSlotButton), matching: findText('신청 가능'));
      if (slot.evaluate().isEmpty) return; // 내일이 일요일이면 열린 시간이 없다
      await tester.ensureVisible(slot.first);
      await tester.tap(slot.first);
      await tester.pumpAndSettle();
      await tester.tap(findText('신청하기'));
      await tester.pumpAndSettle();
      expect(demo.ptBookings.length, before + 1);
      expect(ptStatusAt(demo.ptBookings.last, DateTime.now()), PtStatus.requested);
      expect(findText('승인 기다리는 중'), findsOneWidget);
    });

    testWidgets('선생님은 급한 신청을 맨 위에서 보고 승인한다', (tester) async {
      await open(tester, 'trainer', Routes.ptSchedule);
      expect(findTextContaining('급한 신청'), findsOneWidget);
      await tester.tap(findText('승인').first);
      await tester.pumpAndSettle();
      final urgent = demo.ptBookings.firstWhere((b) => b.urgent);
      expect(urgent.status, PtStatus.approved);
    });

    testWidgets('선생님이 안 왔어요를 누르면 차감, 이번만 빼 주기로 되돌린다', (tester) async {
      await open(tester, 'trainer', Routes.ptSchedule);
      final left = demo.ptLeft['박서연']!;
      await tester.ensureVisible(findText('안 왔어요'));
      await tester.tap(findText('안 왔어요'));
      await tester.pumpAndSettle();
      expect(demo.ptLeft['박서연'], left - 1);
      await tester.ensureVisible(findText('이번만 빼 주기'));
      await tester.tap(findText('이번만 빼 주기'));
      await tester.pumpAndSettle();
      expect(demo.ptLeft['박서연'], left);
    });

    testWidgets('디자인 리뷰 11/18 #2 안 왔어요를 잘못 눌러도 되돌리기로 횟수가 돌아온다', (tester) async {
      await open(tester, 'trainer', Routes.ptSchedule);
      final left = demo.ptLeft['박서연']!;
      await tester.ensureVisible(findText('안 왔어요'));
      await tester.tap(findText('안 왔어요'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(demo.ptLeft['박서연'], left - 1);
      await tester.tap(find.widgetWithText(SnackBarAction, '되돌리기'));
      await tester.pumpAndSettle();
      expect(demo.ptLeft['박서연'], left);
      expect(demo.ptBookings.any((b) => b.member == '박서연' && b.status == PtStatus.approved && !b.start.isAfter(DateTime.now())), isTrue);
    });

    testWidgets('결정 d1119-1 남은 PT가 잡아 둔 수업만큼 다 찼으면 신청을 막는다', (tester) async {
      demo.ptLeft['김지아'] = 1; // 처음 데이터에 확정 예약 1건이 있다
      await open(tester, 'member', Routes.ptBooking);
      final before = demo.ptBookings.length;
      // 아래 범례에도 '신청 가능' 글이 있어서 시간 칸 안에서만 찾는다 (일요일엔 칸이 없다)
      final slot = find.descendant(of: find.byType(TimeSlotButton), matching: findText('신청 가능'));
      if (slot.evaluate().isEmpty) return;
      await tester.ensureVisible(slot.first);
      await tester.tap(slot.first);
      await tester.pump();
      expect(findTextContaining('재등록'), findsOneWidget);
      expect(demo.ptBookings.length, before);
    });

    testWidgets('PT 탭 나누기(A): 선생님 회원 관리에서 수업 일정을 고르고, 재등록 회원 횟수를 늘린다', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(tester.view.reset);
      demo.switchRole('trainer');
      demo.update(() {
        demo.tab = 3;
        demo.trainerView = '회원·일지';
      });
      await tester.pumpWidget(const FitnessApp());
      await tester.pumpAndSettle();
      final left = demo.ptLeft['김지아']!;
      await tester.scrollUntilVisible(findText('남은 PT 횟수'), 200, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(findText('횟수 추가').first);
      await tester.pumpAndSettle();
      await tester.tap(findText('횟수 추가').first);
      await tester.pumpAndSettle();
      await tester.tap(findText('+10회'));
      await tester.pumpAndSettle();
      expect(demo.ptLeft['김지아'], left + 10);
      // 리뷰 11/21 #5 잘못 넣었으면 −1회, 패키지는 직접 입력
      await tester.tap(findText('횟수 추가').first);
      await tester.pumpAndSettle();
      await tester.tap(findText('−1회'));
      await tester.pumpAndSettle();
      expect(demo.ptLeft['김지아'], left + 9);
      await tester.tap(findText('횟수 추가').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '8');
      await tester.pump();
      await tester.tap(findText('+8회 넣기'));
      await tester.pumpAndSettle();
      expect(demo.ptLeft['김지아'], left + 17);
      await tester.scrollUntilVisible(findText('수업 일정'), -300, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(findText('수업 일정'));
      await tester.pumpAndSettle();
      expect(findText('답을 기다리는 신청'), findsWidgets);
    });
  });
}
