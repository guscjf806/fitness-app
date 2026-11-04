/// 공용 부품: 알림(toast)·확인 창·뒤로 가기 확인
library;

import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../common.dart';

/// 데모 상태가 바뀌면 다시 그린다.
Widget watch(Widget Function() build) =>
    ListenableBuilder(listenable: demo, builder: (_, _) => build());

/// 아래에 잠깐 뜨는 알림. [actionLabel]을 주면 '되돌리기' 같은 버튼이 붙는다 (디자인 리뷰 10/31 #3)
void toast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) =>
    toastOn(ScaffoldMessenger.of(context), message, actionLabel: actionLabel, onAction: onAction);

/// 화면을 닫은 뒤에 띄우는 알림. 닫기 전에 잡아 둔 [messenger]로 띄운다.
/// 알림 띠는 이 함수 한 곳에서만 만든다 (디자인 리뷰 11/01 #6)
void toastOn(ScaffoldMessengerState messenger, String message, {String? actionLabel, VoidCallback? onAction}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ));
}

/// 게스트가 로그인이 필요한 기능을 누르면 이유를 알려 주고 로그인으로 안내한다.
/// [thenGenerate]가 true면 로그인 후 바로 기간 선택(S06)으로 이어진다.
void requireLogin(BuildContext context, String reason, {bool thenGenerate = false}) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SheetTitle('로그인이 필요해요'),
        const SizedBox(height: AppSpace.s),
        Muted(reason),
        const Muted('둘러보며 입력한 몸 정보는 로그인 후에도 그대로 이어져요.'),
        AppButton('3초 만에 로그인하기', onPressed: () {
          Navigator.pop(sheetContext);
          demo.continueToGenerate = thenGenerate;
          Navigator.pushNamed(context, Routes.login);
        }),
        AppButton('계속 둘러보기', kind: ButtonKind.soft, onPressed: () => Navigator.pop(sheetContext)),
      ]),
    ),
  );
}

/// 확인 창. 고르면 true. [danger]면 확인 버튼을 빨간 글씨로 (기록이 사라지는 버튼) (디자인 리뷰 11/02 #1)
Future<bool> confirmDialog(BuildContext context,
    {required String title, String? body, required String keepLabel, required String okLabel, bool danger = false}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(keepLabel)),
        TextButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: Text(okLabel, style: danger ? const TextStyle(color: AppColors.warningText) : null),
        ),
      ],
    ),
  );
  return ok == true;
}

/// 쓰던 내용이 있을 때([dirty]) 뒤로 가면 버릴지 먼저 묻는다. 버리면 화면을 닫는다
class DiscardGuard extends StatelessWidget {
  const DiscardGuard(
      {super.key, required this.dirty, required this.title, required this.body, required this.keepLabel, required this.okLabel, required this.child});
  final bool dirty;
  final String title;
  final String body;
  final String keepLabel;
  final String okLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !dirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final discard = await confirmDialog(context, title: title, body: body, keepLabel: keepLabel, okLabel: okLabel, danger: true);
          if (discard && context.mounted) Navigator.pop(context);
        },
        child: child,
      );
}
