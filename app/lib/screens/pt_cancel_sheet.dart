import 'package:flutter/material.dart';

import '../logic/pt_booking.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 선생님이 수업을 취소할 때 고르는 짧은 이유. 자주 쓰는 이유는 눌러서, 아니면 직접 (결정 d1122-1)
class TrainerCancelSheet extends StatefulWidget {
  const TrainerCancelSheet(this.b, {super.key});
  final PtBooking b;

  @override
  State<TrainerCancelSheet> createState() => _TrainerCancelSheetState();
}

class _TrainerCancelSheetState extends State<TrainerCancelSheet> {
  static const _quick = ['몸이 안 좋아요', '급한 일이 생겼어요', '센터 사정이에요'];
  String reason = '';

  /// 칸을 새로 만들지 않고 글만 비워서, 직접 쓰는 동안 키보드가 닫히지 않게 (디자인 리뷰 11/23 #1)
  final typed = TextEditingController();

  @override
  void dispose() {
    typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.b;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SheetTitle('${b.member} 님 ${ptWhen(b.start)} 수업 취소'),
      const Muted('회원에게 바로 알려 드리고, PT 횟수는 줄지 않아요. 짧은 이유를 골라 주세요.', top: AppSpace.xs),
      for (final q in _quick)
        AppButton(q, kind: ButtonKind.soft, top: AppSpace.xs, selected: reason == q, onPressed: () {
          typed.clear();
          setState(() => reason = q);
        }),
      const SizedBox(height: AppSpace.s),
      TextField(
        controller: typed,
        maxLength: 30,
        decoration: const InputDecoration(labelText: '직접 쓰기', hintText: '예: 다음 주에 보강할게요'),
        onChanged: (v) => setState(() => reason = v.trim()),
      ),
      AppButton('취소하고 알리기', onPressed: reason.isEmpty ? null : () => Navigator.pop(context, reason)),
    ]);
  }
}
