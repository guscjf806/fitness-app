import 'package:flutter/material.dart';

import '../logic/pt_booking.dart';
import '../state/demo_state.dart';
import 'common.dart';

/// 선생님이 답해야 할 신청 카드. 급한 신청이 있으면 위에 따로 알리고, 없으면 숨는다
/// 홈과 회원·일지 화면이 같은 모양으로 쓴다 (디자인 리뷰 11/21 #1)
class PtWaitingCard extends StatelessWidget {
  const PtWaitingCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final waiting = demo.ptWaitingAt(DateTime.now());
    if (waiting.isEmpty) return const SizedBox.shrink();
    final urgent = waiting.where((b) => b.urgent).length;
    return HighlightCard(
      icon: Icons.event_note_outlined,
      tone: HighlightTone.caution,
      eyebrow: urgent > 0 ? '급한 신청 $urgent건' : null,
      title: '답을 기다리는 신청 ${waiting.length}건',
      subtitle: waiting.take(2).map((b) => '${b.member} ${ptWhen(b.start)}').join(' · '),
      onTap: onTap,
    );
  }
}
