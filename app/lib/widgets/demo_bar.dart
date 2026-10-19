import 'package:flutter/material.dart';

import '../state/demo_state.dart';
import '../theme/app_theme.dart';

const failModes = ['정상', 'AI 실패', '횟수 소진', '오프라인'];

/// 목업 전용: 사용자 역할을 바꿔 가며 화면을 확인한다. 실제 앱에는 없다.
class DemoBar extends StatelessWidget {
  const DemoBar({super.key});

  static const roles = {
    'guest': '비회원',
    'user': '일반 회원',
    'member': 'PT 회원',
    'trainer': '선생님',
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListenableBuilder(
        listenable: demo,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('데모 보기 모드',
                  style: TextStyle(fontSize: 12, color: AppColors.textSub)),
              for (final e in roles.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: demo.role == e.key,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                      fontSize: 12,
                      color: demo.role == e.key ? Colors.white : AppColors.text),
                  shape: const StadiumBorder(),
                  onSelected: (_) => demo.switchRole(e.key),
                ),
              // 누를 때마다 실패 상황이 바뀐다 (기획서 B6, 무료 횟수 소진, 오프라인 확인용)
              ActionChip(
                avatar: const Icon(Icons.bug_report_outlined, size: 16),
                label: Text('상황: ${demo.failMode}'),
                visualDensity: VisualDensity.compact,
                labelStyle: TextStyle(
                    fontSize: 12,
                    color: demo.failMode == '정상' ? AppColors.text : AppColors.warning),
                shape: const StadiumBorder(),
                onPressed: () {
                  const modes = failModes;
                  demo.update(() => demo.failMode = modes[(modes.indexOf(demo.failMode) + 1) % modes.length]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
