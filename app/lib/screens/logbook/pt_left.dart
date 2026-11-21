import 'package:flutter/material.dart';

import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// 회원별 남은 PT 횟수와 추가 버튼. 재등록한 회원의 횟수를 선생님이 늘린다 (사용자 요청 2026-11-19)
class PtLeftList extends StatelessWidget {
  const PtLeftList({super.key});

  Future<void> _add(BuildContext context, String member) async {
    final added = await showAppSheet<int>(context, builder: (sheet) => _PtLeftSheet(member));
    if (added == null || added == 0 || !context.mounted) return;
    final before = demo.ptLeft[member] ?? 0;
    final after = (before + added).clamp(0, 999);
    demo.update(() => demo.ptLeft[member] = after);
    toast(context, added > 0 ? '$member 님 PT $added회를 추가했어요. 남은 횟수 $after회' : '$member 님 PT ${-added}회를 줄였어요. 남은 횟수 $after회',
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

/// 횟수 추가 시트. 자주 쓰는 묶음 버튼, 잘못 넣었을 때 −1회, 8회·12회 같은 패키지는 직접 입력 (리뷰 11/21 #5)
class _PtLeftSheet extends StatefulWidget {
  const _PtLeftSheet(this.member);
  final String member;

  @override
  State<_PtLeftSheet> createState() => _PtLeftSheetState();
}

class _PtLeftSheetState extends State<_PtLeftSheet> {
  String typed = '';

  @override
  Widget build(BuildContext context) {
    final left = demo.ptLeft[widget.member] ?? 0;
    final n = int.tryParse(typed) ?? 0;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SheetTitle('${widget.member} 님 PT 횟수 추가'),
      Muted('지금 남은 횟수 $left회. 재등록한 만큼 골라 주세요.', top: AppSpace.xs),
      for (final pair in const [(1, 10), (20, 30)])
        ButtonPair(
          left: AppButton('+${pair.$1}회', kind: ButtonKind.soft, onPressed: () => Navigator.pop(context, pair.$1)),
          right: AppButton('+${pair.$2}회', kind: ButtonKind.soft, onPressed: () => Navigator.pop(context, pair.$2)),
        ),
      const SizedBox(height: AppSpace.m),
      NumField(label: '직접 입력', hint: '예: 8', value: typed, decimal: false, suffix: '회', onChanged: (v) => setState(() => typed = v)),
      ButtonPair(
        left: AppButton('−1회', kind: ButtonKind.soft, onPressed: left > 0 ? () => Navigator.pop(context, -1) : null),
        right: AppButton(n > 0 ? '+$n회 넣기' : '넣기', onPressed: n > 0 && n <= 200 ? () => Navigator.pop(context, n) : null),
      ),
    ]);
  }
}
