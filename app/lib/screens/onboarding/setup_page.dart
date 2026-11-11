import 'package:flutter/material.dart';

import '../../config.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
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

  static const _safetyKeys = ['allergies', 'allergyNote', 'painAreas'];

  /// '나중에'를 고르면 다시 만들 곳을 알려 준다 (리뷰 11/11 #2)
  static const _later = ' 나중에 내 정보 > 식단·루틴 새로 만들기에서 만들 수 있어요.';

  Future<void> _save() async {
    if (widget.canSave?.call() == false) return;
    saved = true;
    demo.update(() {});
    final target = demo.tdee.target;
    // 고친 조건을 이미 만든 식단·루틴에 반영할지 묻는다. 못 먹는 음식·아픈 부위는 안전 문제라 횟수를 세지 않는다 (결정 d1107-1)
    final now = demo.bodySnapshot();
    bool changed(String k) => '${before?[k]}' != '${now[k]}';
    final safety = _safetyKeys.any(changed);
    final other = now.keys.any((k) => !_safetyKeys.contains(k) && changed(k));
    String regen = '';
    if (editing && !demo.isGuest && (safety || other)) {
      if (safety) {
        final ok = await confirmDialog(context,
            title: '식단·루틴을 새로 만들까요?',
            body: '못 먹는 음식이나 아픈 부위가 바뀌었어요. 안전을 위한 수정이라 무료 횟수를 쓰지 않아요.',
            keepLabel: '나중에',
            okLabel: '새로 만들기');
        regen = ok ? ' 식단·루틴도 새로 만들었어요(데모, 무료 횟수 그대로).' : _later;
      } else if (demo.quotaExhausted) {
        regen = ' 이번 달 무료 횟수를 다 써서 다음 달 1일부터 내 정보 > 식단·루틴 새로 만들기에서 만들 수 있어요.';
      } else {
        final ok = await confirmDialog(context,
            title: '바뀐 조건으로 새로 만들까요?',
            body: '무료 횟수 1회를 써요. 이번 달 ${demo.aiUsedShown} / ${AppConfig.freeMonthlyAiLimit}회 썼어요.',
            keepLabel: '나중에',
            okLabel: '새로 만들기');
        if (ok) {
          demo.update(() => demo.aiUsed++);
          regen = ' 식단·루틴도 새로 만들었어요(데모).';
        } else {
          regen = _later;
        }
      }
      if (!mounted) return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    toastOn(messenger, (target == targetBefore ? '저장했어요.' : '저장했어요. 목표 칼로리가 ${formatNumber(targetBefore)} → ${formatNumber(target)} kcal로 바뀌었어요.') + regen);
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
          Muted('${widget.step} / $totalSteps단계', bottom: AppSpace.xxs),
          ProgressBar(widget.step / totalSteps),
        ],
        ...widget.children,
        if (editing) AppButton('저장하기', onPressed: _save) else AppButton(widget.nextLabel, onPressed: _next),
      ]),
    );
  }
}
