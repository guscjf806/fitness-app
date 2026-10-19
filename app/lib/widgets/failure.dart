import 'package:flutter/material.dart';

import '../config.dart';
import '../routes.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// 인터넷이 끊겼을 때 화면 위에 띠로 보여 준다.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: demo,
      builder: (context, _) => demo.failMode != '오프라인'
          ? const SizedBox.shrink()
          : const Material(
              color: AppColors.text,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                child: Row(children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('인터넷 연결을 확인해 주세요. 연결되면 자동으로 다시 불러와요.',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ]),
              ),
            ),
    );
  }
}

/// AI 생성·답변이 실패했을 때 (기획서 B6). 횟수는 차감하지 않는다.
class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.title, required this.onRetry, this.onLater});
  final String title;
  final VoidCallback onRetry;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(children: [
        const Icon(Icons.error_outline, size: 44, color: AppColors.warning),
        const SizedBox(height: 10),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Muted('잠시 후 다시 시도해 주세요. 이번 시도는 사용 횟수에서 빠지지 않았어요.', align: TextAlign.center),
        AppButton('다시 시도', onPressed: onRetry),
        if (onLater != null) AppButton('나중에 하기', kind: ButtonKind.soft, onPressed: onLater),
      ]),
    );
  }
}

/// 무료 횟수를 다 썼을 때. 결제를 강요하지 않도록 '기다리기'도 똑같이 누를 수 있게 둔다.
void showQuotaExhausted(BuildContext context) {
  final reset = AppConfig.nextQuotaReset(DateTime.now());
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.background,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('이번 달 무료 횟수를 모두 썼어요', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(children: [
          const Expanded(child: Text('이번 달 AI 사용')),
          Muted('${AppConfig.freeMonthlyAiLimit} / ${AppConfig.freeMonthlyAiLimit}회', bottom: 0),
        ]),
        const ProgressBar(1),
        Muted('${reset.month}월 ${reset.day}일에 다시 ${AppConfig.freeMonthlyAiLimit}회가 생겨요. '
            '그동안 만들어 둔 식단·운동 루틴과 기록은 그대로 쓸 수 있어요.'),
        AppButton('구독하고 계속 쓰기', onPressed: () {
          Navigator.pop(sheetContext);
          Navigator.pushNamed(context, Routes.subscribe);
        }),
        AppButton('다음 달까지 기다리기', kind: ButtonKind.soft, onPressed: () => Navigator.pop(sheetContext)),
      ]),
    ),
  );
}
