import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../routes.dart';
import '../screens/onboarding/login.dart';
import '../state/demo_state.dart';
import '../widgets/common.dart';

/// 실제 소셜 로그인(Supabase Auth). 회원 정보 표(profiles)는 약관 검토 뒤에 만들고,
/// 지금은 로그인이 되는지만 확인한다. 이름 같은 개인정보는 로그에 남기지 않는다.
class AuthService {
  /// main()에서 init()을 불렀을 때만 켜진다. 테스트는 꺼진 채로 목업 로그인을 쓴다
  static bool enabled = false;

  /// 로그인 화면에서 버튼을 눌러 나갔는지 (돌아왔을 때 로그인 화면을 지우기 위해)
  static bool _fromLoginScreen = false;

  static Future<void> init() async {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabasePublishableKey);
    enabled = true;
  }

  /// 앱 화면이 뜬 뒤에 듣기 시작한다 (돌아왔을 때 화면을 옮겨야 해서)
  static void listen() {
    if (!enabled) return;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final signedIn = data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.initialSession;
      if (signedIn && data.session != null && demo.isGuest) _enter(data.session!.user);
    }, onError: (_) {});
  }

  /// 카카오·구글 로그인 창을 연다. 끝나면 앱으로 돌아와 listen()이 이어받는다
  static Future<void> signIn(OAuthProvider provider) async {
    _fromLoginScreen = true;
    await Supabase.instance.client.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb ? Uri.base.origin : AppConfig.loginRedirect,
      authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  static Future<void> signOut() async {
    if (!enabled) return;
    await Supabase.instance.client.auth.signOut();
  }

  static void _enter(User user) {
    final nav = demoNavigatorKey.currentState;
    if (nav == null) return;
    final wasEntered = demo.entered;
    final fromLogin = _fromLoginScreen;
    _fromLoginScreen = false;
    demo.update(() {
      demo.role = 'user';
      demo.entered = true;
    });
    final name = _nickname(user);
    toast(nav.context, name == null ? '로그인했어요' : '$name님, 로그인했어요');
    if (demo.consented) {
      continueAfterLogin(nav.context);
    } else if (fromLogin) {
      nav.pushReplacementNamed(Routes.consent, arguments: wasEntered);
    } else {
      nav.pushNamed(Routes.consent, arguments: wasEntered);
    }
  }

  static String? _nickname(User user) {
    final m = user.userMetadata ?? const {};
    for (final key in ['name', 'full_name', 'preferred_username', 'user_name', 'nickname']) {
      final v = m[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}
