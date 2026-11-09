import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' hide User;
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
    if (!kIsWeb) KakaoSdk.init(nativeAppKey: AppConfig.kakaoNativeAppKey);
    enabled = true;
  }

  /// 앱 화면이 뜬 뒤에 듣기 시작한다 (돌아왔을 때 화면을 옮겨야 해서)
  static void listen() {
    if (!enabled) return;
    Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) => onAuthChange(data.event, data.session),
      onError: onAuthError,
    );
  }

  /// 지금 로그인한 실제 계정. 없으면 목업(Apple·데모 바) 또는 비로그인
  static User? _user;
  static bool get signedIn => _user != null;

  /// 실제 계정의 닉네임. 화면에만 쓰고 로그에는 남기지 않는다
  static String? get nickname => _user == null ? null : _nickname(_user!);

  @visibleForTesting
  static void resetForTest() {
    _user = null;
    _fromLoginScreen = false;
  }

  @visibleForTesting
  static void onAuthChange(AuthChangeEvent event, Session? session) {
    if (event == AuthChangeEvent.signedOut) {
      _onSignedOut();
      return;
    }
    if (session != null) {
      _user = session.user;
      final entering = event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession;
      if (entering && demo.isGuest) {
        _enter(session.user);
      } else {
        demo.update(() {}); // 홈 인사가 내 닉네임으로 바뀌게
      }
    }
  }

  /// 카카오·구글에서 돌아오다 실패하면 알려 준다. 본인이 취소한 경우는 조용히 둔다 (리뷰 11/05 #2)
  @visibleForTesting
  static void onAuthError(Object error) {
    final context = demoNavigatorKey.currentContext;
    if (context == null) return;
    final text = error.toString().toLowerCase();
    if (text.contains('access_denied') || text.contains('cancel')) return;
    toast(context, '로그인하지 못했어요. 다시 시도해 주세요');
  }

  /// 카카오·구글 로그인 창을 연다. 끝나면 앱으로 돌아와 listen()이 이어받는다
  /// 창을 열었으면 true
  static Future<bool> signIn(OAuthProvider provider) async {
    _fromLoginScreen = true;
    // 아이폰은 인터넷 창 대신 카카오톡·카카오 계정 창으로 바로 로그인한다 (결정 d1105-1).
    // 안드로이드는 카카오 콘솔에 키 해시를 등록한 뒤에 바꾼다
    if (provider == OAuthProvider.kakao && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _kakaoNative();
      return true;
    }
    return Supabase.instance.client.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb ? Uri.base.origin : AppConfig.loginRedirect,
      authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  /// 카카오 SDK로 받은 ID 토큰을 Supabase에 넘긴다. 토큰은 로그에 남기지 않는다
  static Future<void> _kakaoNative() async {
    final token = await isKakaoTalkInstalled()
        ? await UserApi.instance.loginWithKakaoTalk()
        : await UserApi.instance.loginWithKakaoAccount();
    final idToken = token.idToken;
    if (idToken == null) throw StateError('kakao id token missing');
    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.kakao,
      idToken: idToken,
      accessToken: token.accessToken,
    );
  }

  /// 본인이 로그인 창을 닫은 경우인지 (그때는 알리지 않는다)
  static bool isCancel(Object error) => error.toString().toLowerCase().contains('cancel');

  /// 직접 로그아웃하면 signOut()이 먼저 _user를 비우므로 여기서는 아무것도 안 한다.
  /// 다른 곳에서 끊겼을 때만 안내하고 로그인 화면으로 보낸다 (리뷰 11/05 #7). 목업 로그인은 _user가 없어 영향 없음
  static void _onSignedOut() {
    if (_user == null) return;
    _user = null;
    final nav = demoNavigatorKey.currentState;
    demo.update(() {
      demo.role = 'guest';
      demo.consented = false;
    });
    if (nav == null) return;
    nav.pushNamedAndRemoveUntil(Routes.main, (_) => false);
    nav.pushNamed(Routes.login);
    toast(nav.context, '로그인이 끊겼어요. 다시 로그인해 주세요');
  }

  static Future<void> signOut() async {
    if (!enabled) return;
    _user = null;
    await Supabase.instance.client.auth.signOut();
    // 카카오 SDK 쪽 로그인도 끊는다. 실패해도 앱 로그아웃은 이미 끝났다
    if (!kIsWeb) await UserApi.instance.logout().then((_) {}, onError: (_) {});
  }

  static void _enter(User user) {
    final nav = demoNavigatorKey.currentState;
    if (nav == null) return;
    final wasEntered = demo.entered;
    final fromLogin = _fromLoginScreen;
    _fromLoginScreen = false;
    final provider = {'kakao': '카카오', 'google': '구글', 'apple': 'Apple'}[user.appMetadata['provider']];
    demo.update(() {
      demo.role = 'user';
      demo.entered = true;
      demo.lastLoginProvider = provider ?? demo.lastLoginProvider;
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
