import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// S05 로그인
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  /// 로그인 창을 여는 중인 곳. 그동안 버튼을 막아 여러 번 불리지 않게 한다 (디자인 리뷰 11/04 #6)
  OAuthProvider? connecting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 로그인 창에서 그냥 돌아와도 다시 누를 수 있게
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && connecting != null) setState(() => connecting = null);
  }

  void _login(BuildContext context) {
    final wasEntered = demo.entered;
    demo.update(() {
      demo.role = 'user';
      demo.entered = true;
    });
    if (!demo.consented) {
      // 동의를 취소하면 로그인 전 상태로 되돌릴 수 있게 알려 준다
      Navigator.pushReplacementNamed(context, Routes.consent, arguments: wasEntered);
    } else {
      continueAfterLogin(context);
    }
  }

  /// 카카오·구글은 실제 로그인, 테스트와 Apple은 목업 로그인
  Future<void> _socialLogin(BuildContext context, OAuthProvider? provider) async {
    if (provider == null || !AuthService.enabled) {
      _login(context);
      return;
    }
    setState(() => connecting = provider);
    try {
      if (!await AuthService.signIn(provider)) throw StateError('login window not opened');
    } catch (_) {
      if (!context.mounted) return;
      setState(() => connecting = null);
      toast(context, '로그인 창을 열지 못했어요. 인터넷 연결을 확인하고 다시 시도해 주세요');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 각 회사 규칙대로 글자 왼쪽에 공식 로고를 20px로 둔다 (디자인 리뷰 11/03 #4)
    Widget social(String label, Color bg, Color fg, {bool outlined = false, String? logo, OAuthProvider? provider}) =>
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FilledButton(
            onPressed: connecting != null ? null : () => _socialLogin(context, provider),
            style: FilledButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              side: outlined ? const BorderSide(color: AppColors.socialBorder) : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (logo != null && (provider == null || connecting != provider)) ...[
                Image.asset(logo, width: 20, height: 20, excludeFromSemantics: true),
                const SizedBox(width: AppSpace.s),
              ],
              Text(provider != null && connecting == provider ? '연결하는 중…' : label),
            ]),
          ),
        );
    // 로그인 화면을 뒤로 나가면 만들던 식단·루틴으로 이어 가지 않는다. 다른 창으로 나갔다 오는 실제 로그인은 pop이 아니라 그대로 (리뷰 11/06 #6)
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && demo.continueToGenerate) demo.update(() => demo.continueToGenerate = false);
      },
      child: AppPage(title: '로그인', children: [
      const H1('간편하게 시작해요'),
      const Muted('로그인하면 식단·운동 루틴 생성, 식단 올리기를 쓸 수 있어요.'),
      // 다른 창으로 나갔다 오니 앱이 꺼진 줄 알지 않게 미리 알린다 (리뷰 11/05 #5)
      const Muted('카카오·구글 창이 열려요. 로그인을 마치면 앱으로 돌아와요.'),
      social('카카오로 시작하기', AppColors.kakao, AppColors.kakaoText, logo: 'assets/logos/kakao.png', provider: OAuthProvider.kakao),
      social('구글로 시작하기', Colors.white, AppColors.googleText, outlined: true, logo: 'assets/logos/google.png', provider: OAuthProvider.google),
      // Apple 로고는 공식 자료를 받으려면 라이선스 동의가 필요해 아직 비워 둔다 (assets/logos/README.md)
      social('Apple로 시작하기', Colors.black, Colors.white),
      Disclaimer(text: AuthService.enabled ? '카카오·구글은 실제 로그인이에요. Apple은 준비 중이라 누르면 일반 회원 데모로 들어가요.' : '목업이라 실제 로그인은 하지 않아요. 누르면 일반 회원으로 들어가요.'),
    ]),
    );
  }
}

/// 로그인(과 동의)을 마친 뒤: 식단·운동 루틴을 만들던 중이면 기간 선택으로, 아니면 홈으로
void continueAfterLogin(BuildContext context) {
  if (demo.continueToGenerate) {
    demo.update(() => demo.continueToGenerate = false);
    Navigator.pushReplacementNamed(context, Routes.generate);
  } else {
    Navigator.pushNamedAndRemoveUntil(context, Routes.main, (_) => false);
  }
}
