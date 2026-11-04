import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'routes.dart';
import 'services/auth_service.dart';
import 'state/demo_state.dart';
import 'theme/app_theme.dart';
import 'widgets/demo_bar.dart';
import 'widgets/failure.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await demo.load();
  await AuthService.init();
  runApp(const FitnessApp());
  WidgetsBinding.instance.addPostFrameCallback((_) => AuthService.listen());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '운동 앱 (목업)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // 달력·시간 고르기 같은 기본 창이 한국어로 나오게 (리뷰 11/04 #4)
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      navigatorKey: demoNavigatorKey,
      // 전에 앱 안에 들어온 적이 있으면 시작 화면을 건너뛴다
      initialRoute: demo.entered ? Routes.main : Routes.start,
      routes: Routes.table,
      // 웹 미리보기: 위에 역할 전환 바, 가운데 폰 크기 화면
      builder: (context, child) => ColoredBox(
        color: AppColors.pageBackground,
        child: SafeArea(
          child: Column(
            children: [
              const DemoBar(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 420, maxHeight: 860),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(children: [
                        const OfflineBanner(),
                        Expanded(child: child ?? const SizedBox()),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.s),
            ],
          ),
        ),
      ),
    );
  }
}
