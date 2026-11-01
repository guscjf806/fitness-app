import 'package:flutter/material.dart';

import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'login.dart';

/// S05-1 동의 (로그인 직후 한 번). 문구는 전문가 검토 후 넣는다 (기획서 13번 L1·L2·L4·L5·L8).
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  static const items = [
    ('만 14세 이상이에요', true),
    ('이용약관 동의', true),
    ('개인정보 수집·이용 동의', true),
    ('건강정보(몸 정보, 식단 사진) 수집·이용 동의', true),
    ('AI 기반 서비스 안내 및 개인정보 국외 처리 위탁 동의', true),
    ('이벤트·혜택 알림 받기', false),
  ];
  final Set<int> agreed = {};

  bool get requiredDone => [for (var i = 0; i < items.length; i++) if (items[i].$2) i].every(agreed.contains);

  void _showDraft(String title) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          SheetTitle(title), // 다른 시트 제목과 같게 (디자인 리뷰 10/30 #6)
          const SizedBox(height: 10),
          const Muted('이 자리에는 전문가 검토를 마친 약관·동의서 원문이 들어가요. 목업에서는 비워 두었어요.'),
        ]),
      ),
    );
  }

  /// 동의하지 않고 뒤로 가면 로그인을 취소한다. 건강정보 동의를 건너뛰지 못하게 (리뷰 10/29 #1)
  Future<void> _leave() async {
    final cancel = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('동의하지 않으면 로그인이 취소돼요'),
        content: const Text('나가면 로그인 없이 둘러보기로 돌아가요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('계속 동의하기')),
          TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('로그인 취소')),
        ],
      ),
    );
    if (cancel != true || !mounted) return;
    demo.update(() {
      demo.role = 'guest';
      demo.continueToGenerate = false;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: AppPage(title: '시작하기 전에', children: [
      const Muted('서비스를 쓰려면 아래 내용에 동의해 주세요. 몸 정보와 식단 사진은 민감한 건강정보라 따로 동의를 받아요.'),
      AppCard(
        onTap: () => setState(() => agreed.length == items.length
            ? agreed.clear()
            : agreed.addAll([for (var i = 0; i < items.length; i++) i])),
        child: Row(children: [
          CheckCircle(agreed.length == items.length),
          const SizedBox(width: 10),
          const Expanded(child: Text('전체 동의', style: AppText.bodyStrong)),
        ]),
      ),
      for (var i = 0; i < items.length; i++)
        LineRow(
          onTap: () => setState(() => agreed.contains(i) ? agreed.remove(i) : agreed.add(i)),
          left: Row(children: [
            CheckCircle(agreed.contains(i)),
            const SizedBox(width: 10),
            Expanded(child: Text('[${items[i].$2 ? '필수' : '선택'}] ${items[i].$1}')),
          ]),
          right: i == 0 ? null : TextButton(onPressed: () => _showDraft(items[i].$1), child: const Text('보기')),
        ),
      const Disclaimer(text: '이 앱은 AI로 식단·운동 루틴과 답변을 만들어요. AI가 만든 내용은 의료 조언이 아닙니다.'),
      AppButton('동의하고 시작하기', onPressed: requiredDone
          ? () {
              demo.update(() => demo.consented = true);
              continueAfterLogin(context);
            }
          : null),
      if (!requiredDone)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('필수 항목에 모두 동의해야 시작할 수 있어요.', textAlign: TextAlign.center, style: AppText.body),
        ),
    ]),
    );
  }
}
