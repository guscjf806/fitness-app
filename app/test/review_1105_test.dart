import 'package:fitness_app/main.dart';
import 'package:fitness_app/services/auth_service.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:fitness_app/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent, AuthException, Session, User;

import 'finders.dart';

/// 사용자 리뷰 11/05: 실제 로그인 후의 흐름. Supabase 없이 로그인 이벤트만 흉내 낸다
Session fakeSession({String? name}) => Session(
      accessToken: 'test',
      tokenType: 'bearer',
      user: User(
        id: 'test-user',
        appMetadata: const {},
        userMetadata: name == null ? const {} : {'name': name},
        aud: 'authenticated',
        createdAt: '2026-11-05',
      ),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    demo.switchRole('guest');
    demo.consented = false;
    AuthService.resetForTest();
  });

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const FitnessApp());
    await tester.pumpAndSettle();
  }

  testWidgets('#1 되돌리기가 있는 알림 띠도 6초 뒤 저절로 사라진다', (tester) async {
    await start(tester);
    toast(demoNavigatorKey.currentContext!, '지웠어요', actionLabel: '되돌리기', onAction: () {});
    await tester.pumpAndSettle();
    expect(findText('지웠어요'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(findText('지웠어요'), findsNothing);
  });
  testWidgets('#2 돌아오다 실패하면 안내하고, 본인이 취소하면 조용히 둔다', (tester) async {
    await start(tester);
    AuthService.onAuthError(const AuthException('access_denied'));
    await tester.pump();
    expect(findText('로그인하지 못했어요. 다시 시도해 주세요'), findsNothing);
    AuthService.onAuthError(const AuthException('server error'));
    await tester.pump();
    expect(findText('로그인하지 못했어요. 다시 시도해 주세요'), findsOneWidget);
  });
  testWidgets('#3 실제 로그인하면 내 닉네임으로 인사하고, 닉네임이 없으면 이름 없이', (tester) async {
    await start(tester);
    demo.consented = true;
    AuthService.onAuthChange(AuthChangeEvent.signedIn, fakeSession(name: '현철'));
    await tester.pumpAndSettle();
    expect(demo.greeting, '안녕하세요, 현철님');
    expect(findText('안녕하세요, 현철님'), findsOneWidget);
    AuthService.onAuthChange(AuthChangeEvent.tokenRefreshed, fakeSession());
    expect(demo.greeting, '안녕하세요');
  });
  testWidgets('#4 로그아웃하면 다음 로그인 때 동의 화면이 다시 나온다', (tester) async {
    await start(tester);
    demo.switchRole('user');
    await tester.pumpAndSettle();
    expect(demo.consented, isTrue);
    demo.logout();
    await tester.pumpAndSettle();
    expect(demo.consented, isFalse);
    AuthService.onAuthChange(AuthChangeEvent.signedIn, fakeSession(name: '다른 사람'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '시작하기 전에'), findsOneWidget);
  });
}
