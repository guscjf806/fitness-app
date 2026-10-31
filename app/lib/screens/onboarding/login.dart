import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// S05 로그인
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _login(BuildContext context) {
    demo.update(() {
      demo.role = 'user';
      demo.entered = true;
    });
    if (!demo.consented) {
      Navigator.pushReplacementNamed(context, Routes.consent);
    } else {
      continueAfterLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget social(String label, Color bg, Color fg, {bool outlined = false}) =>
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FilledButton(
            onPressed: () => _login(context),
            style: FilledButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              side: outlined ? const BorderSide(color: AppColors.socialBorder) : null,
            ),
            child: Text(label),
          ),
        );
    return AppPage(title: '로그인', children: [
      const H1('3초 만에 시작해요'),
      const Muted('로그인하면 식단·운동 루틴 생성, 식단 올리기를 쓸 수 있어요.'),
      social('카카오로 시작하기', AppColors.kakao, AppColors.kakaoText),
      social('구글로 시작하기', Colors.white, AppColors.googleText, outlined: true),
      social('Apple로 시작하기', Colors.black, Colors.white),
      const Disclaimer(text: '목업이라 실제 로그인은 하지 않아요. 누르면 일반 회원으로 들어가요.'),
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
