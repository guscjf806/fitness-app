import 'package:flutter/material.dart';

import 'routes.dart';
import 'state/demo_state.dart';
import 'theme/app_theme.dart';
import 'widgets/demo_bar.dart';

void main() => runApp(const FitnessApp());

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '운동 앱 (목업)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: demoNavigatorKey,
      initialRoute: Routes.start,
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
                      child: child,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
