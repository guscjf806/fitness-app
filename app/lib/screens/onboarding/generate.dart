import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/demo_state.dart';
import '../../widgets/common.dart';
import '../../widgets/failure.dart';

/// S06 기간 선택·생성
class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  bool generating = false;
  bool failed = false;

  Future<void> _generate() async {
    setState(() {
      generating = true;
      failed = false;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (demo.failMode == 'AI 실패') {
      if (mounted) {
        setState(() {
          generating = false;
          failed = true;
        });
      }
      return;
    }
    demo.update(() => demo.tab = 0);
    navigator.pushNamedAndRemoveUntil(Routes.main, (_) => false);
    messenger.showSnackBar(SnackBar(content: Text('${demo.period}치 식단과 운동 루틴을 만들었어요')));
  }

  @override
  Widget build(BuildContext context) {
    if (generating) {
      return const Scaffold(
        body: Center(child: LoadingView('AI가 식단과 운동 루틴을 만들고 있어요', sub: '잠시만 기다려 주세요')),
      );
    }
    if (failed) {
      return AppPage(title: '기간 선택', children: [
        FailureView(
          title: '식단·운동 루틴을 만들지 못했어요',
          onRetry: _generate,
          onLater: () => Navigator.pushNamedAndRemoveUntil(context, Routes.main, (_) => false),
        ),
      ]);
    }
    final r = demo.tdee;
    return AppPage(title: '기간 선택', children: [
      const Muted('식단과 운동 루틴을 얼마 동안 만들까요?'),
      Seg(options: const ['일주일', '한 달'], value: demo.period, onChanged: (v) => demo.update(() => demo.period = v)),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('반영되는 정보', bottom: 2),
          Text('목표 칼로리 ${formatNumber(r.target)} kcal · 현재 강도 ${demo.currentIntensity} · '
              '원하는 강도 ${demo.desiredIntensity} · ${demo.conditionText}'),
          if (demo.allergies.isNotEmpty || demo.allergyNote.isNotEmpty)
            Text('빼는 음식: ${[...demo.allergies, if (demo.allergyNote.isNotEmpty) demo.allergyNote].join(', ')}'),
          if (demo.painAreas.isNotEmpty) Text('조심할 부위: ${demo.painAreas.join(', ')}'),
        ]),
      ),
      AppButton('식단·운동 루틴 생성하기', onPressed: _generate),
    ]);
  }
}
