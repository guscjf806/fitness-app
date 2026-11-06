import 'package:flutter/material.dart';

import '../../state/demo_state.dart';
import '../../widgets/common.dart';

/// 처음 입력하는 3단계 화면의 틀.
/// 처음에는 단계 표시와 [다음], 내 정보에서 고치러 오면(arguments: 'edit') [저장하기] 후 돌아간다.
/// 저장하지 않고 뒤로 가면 고친 값을 되돌린다.
class SetupPage extends StatefulWidget {
  const SetupPage({
    super.key,
    required this.title,
    required this.step,
    required this.children,
    required this.onNext,
    this.nextLabel = '다음',
    this.canSave,
  });
  final String title;

  /// 1~3
  final int step;
  final List<Widget> children;
  final VoidCallback onNext;
  final String nextLabel;

  /// 저장하거나 다음으로 가기 전 입력 확인
  final bool Function()? canSave;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  static const totalSteps = 3;

  bool get editing => ModalRoute.of(context)?.settings.arguments == 'edit';
  Map<String, Object>? before;
  int targetBefore = 0;
  bool saved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (editing && before == null) {
      before = demo.bodySnapshot();
      targetBefore = demo.tdee.target;
    }
  }

  void _save() {
    if (widget.canSave?.call() == false) return;
    saved = true;
    demo.update(() {});
    final target = demo.tdee.target;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    toastOn(messenger, target == targetBefore ? '저장했어요' : '저장했어요. 목표 칼로리가 ${formatNumber(targetBefore)} → ${formatNumber(target)} kcal로 바뀌었어요');
  }

  void _next() {
    if (widget.canSave?.call() == false) return;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && editing && !saved && before != null) demo.restoreBody(before!);
      },
      child: AppPage(title: widget.title, children: [
        // 얼마나 남았는지 막대와 글자로 (결정 dd1105-steps). 고치러 왔을 때는 필요 없다 (결정 dd1105-edit)
        if (!editing) ...[
          Muted('${widget.step} / $totalSteps단계', bottom: 2),
          ProgressBar(widget.step / totalSteps),
        ],
        ...widget.children,
        if (editing) AppButton('저장하기', onPressed: _save) else AppButton(widget.nextLabel, onPressed: _next),
      ]),
    );
  }
}
