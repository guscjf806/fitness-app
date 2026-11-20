import 'package:flutter/material.dart';

import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// 회원별 남은 PT 횟수와 추가 버튼. 재등록한 회원의 횟수를 선생님이 늘린다 (사용자 요청 2026-11-19)
class PtLeftList extends StatelessWidget {
  const PtLeftList({super.key});

  Future<void> _add(BuildContext context, String member) async {
    final added = await showAppSheet<int>(
      context,
      builder: (sheet) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SheetTitle('$member 님 PT 횟수 추가'),
        Muted('지금 남은 횟수 ${demo.ptLeft[member] ?? 0}회. 재등록한 만큼 골라 주세요.', top: AppSpace.xs),
        for (final pair in const [(1, 10), (20, 30)])
          ButtonPair(
            left: AppButton('+${pair.$1}회', kind: ButtonKind.soft, onPressed: () => Navigator.pop(sheet, pair.$1)),
            right: AppButton('+${pair.$2}회', kind: ButtonKind.soft, onPressed: () => Navigator.pop(sheet, pair.$2)),
          ),
      ]),
    );
    if (added == null || !context.mounted) return;
    final before = demo.ptLeft[member] ?? 0;
    demo.update(() => demo.ptLeft[member] = before + added);
    toast(context, '$member 님 PT $added회를 추가했어요. 남은 횟수 ${before + added}회',
        actionLabel: '되돌리기', onAction: () => demo.update(() => demo.ptLeft[member] = before));
  }

  @override
  Widget build(BuildContext context) {
    if (demo.activeMembers.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const H2('남은 PT 횟수'),
      for (final m in demo.activeMembers)
        LineRow(
          left: WordText('$m · ${demo.ptLeft[m] ?? 0}회 남음',
              style: (demo.ptLeft[m] ?? 0) <= 0 ? AppText.bodyStrongCaution : AppText.bodyStrong),
          // 같은 화면 회원 줄의 '일지 작성'과 같은 연한 버튼 (디자인 리뷰 11/20 #4)
          right: FilledButton.tonal(
            style: AppButtonStyle.soft(minimumSize: const Size(0, 48)),
            onPressed: () => _add(context, m),
            child: const Text('횟수 추가'),
          ),
        ),
      const SizedBox(height: AppSpace.l),
    ]);
  }
}
