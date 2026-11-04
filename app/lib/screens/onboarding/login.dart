import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// S05 로그인
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
    try {
      await AuthService.signIn(provider);
    } catch (_) {
      if (context.mounted) toast(context, '로그인 창을 열지 못했어요. 인터넷 연결을 확인하고 다시 시도해 주세요');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 각 회사 규칙대로 글자 왼쪽에 공식 로고를 20px로 둔다 (디자인 리뷰 11/03 #4)
    Widget social(String label, Color bg, Color fg, {bool outlined = false, String? logo, OAuthProvider? provider}) =>
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FilledButton(
            onPressed: () => _socialLogin(context, provider),
            style: FilledButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              side: outlined ? const BorderSide(color: AppColors.socialBorder) : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (logo != null) ...[
                Image.asset(logo, width: 20, height: 20, excludeFromSemantics: true),
                const SizedBox(width: AppSpace.s),
              ],
              Text(label),
            ]),
          ),
        );
    return AppPage(title: '로그인', children: [
      const H1('3초 만에 시작해요'),
      const Muted('로그인하면 식단·운동 루틴 생성, 식단 올리기를 쓸 수 있어요.'),
      social('카카오로 시작하기', AppColors.kakao, AppColors.kakaoText, logo: 'assets/logos/kakao.png', provider: OAuthProvider.kakao),
      social('구글로 시작하기', Colors.white, AppColors.googleText, outlined: true, logo: 'assets/logos/google.png', provider: OAuthProvider.google),
      // Apple 로고는 공식 자료를 받으려면 라이선스 동의가 필요해 아직 비워 둔다 (assets/logos/README.md)
      social('Apple로 시작하기', Colors.black, Colors.white),
      Disclaimer(text: AuthService.enabled ? '카카오·구글은 실제 로그인이에요. Apple은 준비 중이라 누르면 일반 회원 데모로 들어가요.' : '목업이라 실제 로그인은 하지 않아요. 누르면 일반 회원으로 들어가요.'),
    ]);
  }
}

/// 로그인(과 동의)을 마친 뒤: 식단·운동 루틴을 만들던 중이면 기간 선택으로, 아니면 홈으로
void continueAfterLogin(BuildContext context) {
  if (demo.continueToGenerate) {
    demo.continueToGenerate = false;
    Navigator.pushReplacementNamed(context, Routes.generate);
  } else {
    Navigator.pushNamedAndRemoveUntil(context, Routes.main, (_) => false);
  }
}
