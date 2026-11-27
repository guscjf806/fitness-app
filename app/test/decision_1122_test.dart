import 'package:fitness_app/config.dart';
import 'package:fitness_app/logic/pt_booking.dart';
import 'package:fitness_app/main.dart';
import 'package:fitness_app/routes.dart';
import 'package:fitness_app/screens/pt_cancel_sheet.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:fitness_app/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'finders.dart';

/// 결정 d1120-1, d1121-1·2, d1122-1·2 (2026-11-22 저장값)
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    demo.resetPt();
    demo.ptEnded = false;
  });

  test('d1121-1 PT가 끝난 날과 무료 끝나기 하루 전에 알린다', () {
    final end = DateTime(2026, 11, 22, 10);
    final n = ptEndNotices(end);
    expect(n.length, 2);
    expect(n.first.at, end);
    expect(n.last.at, end.add(const Duration(days: AppConfig.ptGraceDays - 1)));
    expect(n.first.body, contains('11월 29일까지 무료'));
  });

  test('d1121-2 남은 PT가 2회 이하면 곧 끝남', () {
    demo.ptLeft['김지아'] = 3;
    expect(demo.ptLowOf('김지아'), isFalse);
    demo.ptLeft['김지아'] = 2;
    expect(demo.ptLowOf('김지아'), isTrue);
    demo.ptLeft['김지아'] = 0;
    expect(demo.ptLowOf('김지아'), isFalse, reason: '0회는 재등록 문의로 따로 안내');
  });

  test('d1122-1 선생님이 취소하면 차감 없이 이유와 함께 보인다', () {
    final now = DateTime.now();
    final b = demo.ptBookings.firstWhere((b) => b.member == '김지아');
    final undo = demo.ptUndo(b);
    b.status = PtStatus.trainerCancelled;
    b.cancelReason = '몸이 안 좋아요';
    expect(ptCharged(b), isFalse);
    expect(ptHoldsSlot(b.status), isFalse);
    expect(ptMemberLabel(b, now), '선생님이 취소함 · 차감 없음 · 몸이 안 좋아요');
    undo();
    expect(b.status, PtStatus.approved);
    expect(b.cancelReason, isNull);
  });

  test('d1122-2 시간 바꾸기는 횟수를 더 쓰지 않고, 승인을 되돌리면 원래 예약도 돌아온다', () {
    final now = DateTime.now();
    final original = demo.ptBookings.firstWhere((b) => b.member == '김지아');
    final before = demo.ptBookedOf('김지아', now);
    final change = PtBooking(member: '김지아', start: original.start.add(const Duration(days: 1)), requestedAt: now, replaces: original);
    demo.ptBookings.add(change);
    expect(demo.ptBookedOf('김지아', now), before);
    expect(ptMemberLabel(change, now), '시간 바꾸기 · 승인 기다리는 중');
    final undo = demo.ptUndo(change);
    change.status = PtStatus.approved;
    original.status = PtStatus.cancelled;
    undo();
    expect(original.status, PtStatus.approved);
    expect(change.status, PtStatus.requested);
  });

  group('리뷰 11/23', () {
    test('결정 d1123-1 보강 신청은 보강으로 보이고, 신청하면 버튼이 사라진다', () {
      final now = DateTime.now();
      final b = demo.ptBookings.firstWhere((b) => b.member == '김지아');
      b.status = PtStatus.trainerCancelled;
      expect(demo.ptMakeupBooked(b, now), isFalse);
      final m = PtBooking(member: '김지아', start: b.start.add(const Duration(days: 1)), requestedAt: now, makeupFor: b);
      demo.ptBookings.add(m);
      expect(demo.ptMakeupBooked(b, now), isTrue);
      expect(ptMemberLabel(m, now), '보강 · 승인 기다리는 중');
      // 디자인 리뷰 11/24 #5 확정 뒤에도 보강으로 보인다
      m.status = PtStatus.approved;
      expect(ptMemberLabel(m, now), '보강 · 예약 확정');
      expect(demo.ptMakeupOf(b, now), m);
    });

    test('#1 선생님이 취소한 앞으로의 수업은 알릴 목록에 남는다', () {
      final now = DateTime.now();
      final b = demo.ptBookings.firstWhere((b) => b.member == '김지아');
      b.status = PtStatus.trainerCancelled;
      b.cancelReason = '몸이 안 좋아요';
      expect(demo.ptTrainerCancelledAhead('김지아', now), [b]);
      expect(ptTrainerCancelText(b), endsWith('몸이 안 좋아요 · 횟수는 그대로예요'));
    });

    test('#3 바꾸기 신청이 거절되면 원래 예약 그대로라고 쓴다', () {
      final now = DateTime.now();
      final original = demo.ptBookings.firstWhere((b) => b.member == '김지아');
      final change = PtBooking(member: '김지아', start: original.start.add(const Duration(days: 1)), requestedAt: now, replaces: original)
        ..status = PtStatus.rejected;
      expect(ptMemberLabel(change, now), '시간 바꾸기 거절 · 원래 예약 그대로');
    });

    test('디자인 결정 d1123-1 PT 끝 알림은 무료 기간 내내 그대로 보인다', () {
      demo.switchRole('member');
      demo.update(() => demo.ptLeft[demo.memberName] = 0);
      expect(demo.ptEndNoticeNow, isNotNull);
    });
  });

  group('리뷰 11/26', () {
    PtBooking cancelled() => demo.ptBookings.firstWhere((b) => b.member == '김지아')..status = PtStatus.trainerCancelled;

    test('#1 보강이 거절되거나 답이 없어 정리되면 이유를 알린다', () {
      final now = DateTime.now();
      final b = cancelled();
      expect(demo.ptMakeupMissText(b, now), isNull);
      final m = PtBooking(member: '김지아', start: b.start.add(const Duration(days: 1)), requestedAt: now, makeupFor: b)
        ..status = PtStatus.rejected;
      demo.ptBookings.add(m);
      expect(demo.ptMakeupMissText(b, now), startsWith('보강 신청이 거절됐어요'));
      m.status = PtStatus.expired;
      expect(demo.ptMakeupMissText(b, now), contains('답이 없어 정리됐어요'));
      m.status = PtStatus.cancelled;
      expect(demo.ptMakeupMissText(b, now), isNull, reason: '회원이 직접 취소한 건 따로 알리지 않는다');
    });

    test('#2 보강 안내는 신청 중과 확정을 나눈다', () {
      final now = DateTime.now();
      final b = cancelled();
      final m = PtBooking(member: '김지아', start: b.start.add(const Duration(days: 1)), requestedAt: now, makeupFor: b);
      expect(ptMakeupNote(m, now), '보강을 신청했어요 · 승인 기다리는 중');
      m.status = PtStatus.approved;
      expect(ptMakeupNote(m, now), '보강이 잡혔어요 · ${ptWhen(m.start)}');
    });

    test('#3 보강 수업까지 선생님이 취소하면 원래 수업 버튼은 숨긴다', () {
      final now = DateTime.now();
      final b = cancelled();
      final m = PtBooking(member: '김지아', start: b.start.add(const Duration(days: 1)), requestedAt: now, makeupFor: b)
        ..status = PtStatus.trainerCancelled;
      demo.ptBookings.add(m);
      expect(demo.ptMakeupRedone(b, now), m);
      expect(demo.ptMakeupRedone(m, now), isNull);
      m.status = PtStatus.cancelled;
      expect(demo.ptMakeupRedone(b, now), isNull, reason: '회원이 직접 취소하면 원래 수업 버튼이 다시 나온다');
    });
  });

  group('화면', () {
    Future<void> open(WidgetTester tester, String role, String route) async {
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(tester.view.reset);
      demo.switchRole(role);
      await tester.pumpWidget(const FitnessApp());
      await tester.pumpAndSettle();
      demoNavigatorKey.currentState!.pushNamed(route);
      await tester.pumpAndSettle();
    }

    testWidgets('d1122-2 회원이 시간 바꾸기를 누르면 옮길 시간을 고르는 안내가 나온다', (tester) async {
      await open(tester, 'member', Routes.ptBooking);
      await tester.ensureVisible(findText('시간 바꾸기'));
      await tester.tap(findText('시간 바꾸기'));
      await tester.pumpAndSettle();
      expect(findTextContaining('옮길 시간을 골라 주세요'), findsOneWidget);
      await tester.tap(findText('그만두기'));
      await tester.pumpAndSettle();
      expect(findTextContaining('옮길 시간을 골라 주세요'), findsNothing);
    });

    testWidgets('d1121-2 남은 PT가 2회면 회원 PT 화면에 미리 알린다', (tester) async {
      demo.ptLeft['김지아'] = 2;
      await open(tester, 'member', Routes.ptBooking);
      expect(findTextContaining('재등록을 이야기해 보세요'), findsOneWidget);
    });

    testWidgets('디자인 리뷰 11/23 #2 360px·2.0배에서 예약 카드 버튼이 넘치지 않는다', (tester) async {
      tester.view.physicalSize = const Size(360, 2400);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      demo.switchRole('member');
      await tester.pumpWidget(const FitnessApp());
      await tester.pumpAndSettle();
      demoNavigatorKey.currentState!.pushNamed(Routes.ptBooking);
      await tester.pumpAndSettle();
      expect(findText('시간 바꾸기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('디자인 리뷰 11/23 #1 빠른 이유를 고른 뒤 직접 써도 칸이 그대로다', (tester) async {
      await open(tester, 'trainer', Routes.ptSchedule);
      final b = demo.ptBookings.firstWhere((b) => b.member == '김지아');
      final scaffold = tester.element(find.byType(Scaffold).last);
      showAppSheet<String>(scaffold, builder: (_) => TrainerCancelSheet(b));
      await tester.pumpAndSettle();
      await tester.tap(findText('몸이 안 좋아요'));
      await tester.pump();
      final field = find.byType(TextField);
      final before = tester.state(field);
      await tester.enterText(field, '보');
      await tester.pump();
      expect(tester.state(field), same(before));
      await tester.enterText(field, '보강할게요');
      await tester.pump();
      expect(find.text('보강할게요'), findsOneWidget);
    });

    testWidgets('디자인 리뷰 11/24 #1 홈의 취소 카드를 누르면 바로 보강 시간 고르기가 열린다', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(tester.view.reset);
      demo.switchRole('member');
      final b = demo.ptBookings.firstWhere((b) => b.member == demo.memberName);
      b.status = PtStatus.trainerCancelled;
      demo.update(() => demo.tab = 0);
      await tester.pumpWidget(const FitnessApp());
      await tester.pumpAndSettle();
      await tester.tap(findText('선생님이 수업을 취소했어요').first);
      await tester.pumpAndSettle();
      expect(findTextContaining('보강 시간을 골라 주세요'), findsOneWidget);
      // 리뷰 11/26 #4 위 취소 알림 자리에도 고르는 중이라고 보인다
      expect(findText('아래에서 보강 시간 고르는 중'), findsOneWidget);
      expect(findText('보강 신청하기'), findsNothing);
    });

    testWidgets('디자인 리뷰 11/27 #1 보강 수업까지 취소되면 수업 예약 화면에도 취소 상자가 하나만', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(tester.view.reset);
      demo.switchRole('member');
      final now = DateTime.now();
      final b = demo.ptBookings.firstWhere((b) => b.member == demo.memberName)..status = PtStatus.trainerCancelled;
      demo.ptBookings.add(PtBooking(member: demo.memberName, start: b.start.add(const Duration(days: 1)), requestedAt: now, makeupFor: b)
        ..status = PtStatus.trainerCancelled);
      demo.openPtTab('수업 예약');
      await tester.pumpWidget(const FitnessApp());
      await tester.pumpAndSettle();
      expect(findText('선생님이 수업을 취소했어요'), findsOneWidget);
      expect(findTextContaining('수업의 보강이었어요'), findsOneWidget);
      expect(findText('보강 신청하기'), findsOneWidget);
    });
  });
}
