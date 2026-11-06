import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

String _mmss(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// 세트를 마치면 뜨는 휴식 타이머. [recommendedSeconds]는 강도 규칙의 휴식 시간 (기획서 6번).
Future<void> showRestTimer(BuildContext context, int recommendedSeconds) {
  return showAppSheet<void>(
    context,
    // 땀 묻은 손으로 바깥을 잘못 눌러 닫히지 않게, 닫는 건 아래 버튼으로만 (리뷰 10/28 #2)
    isDismissible: false,
    enableDrag: false,
    builder: (_) => _RestTimer(recommended: recommendedSeconds),
  );
}

class _RestTimer extends StatefulWidget {
  const _RestTimer({required this.recommended});
  final int recommended;

  @override
  State<_RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<_RestTimer> {
  late int total = widget.recommended;
  late int remaining = widget.recommended;
  Timer? ticker;

  @override
  void initState() {
    super.initState();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    if (remaining <= 1) {
      ticker?.cancel();
      // 진동 + 짧은 알림음. 소리는 내 정보에서 끌 수 있다 (결정 d1028-rest-alert)
      HapticFeedback.heavyImpact();
      if (demo.restSound) SystemSound.play(SystemSoundType.alert);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      toastOn(messenger, '휴식 끝! 다음 세트를 시작하세요');
      return;
    }
    setState(() => remaining--);
  }

  void _set(int seconds) => setState(() {
        total = seconds;
        remaining = seconds;
      });

  void _adjust(int delta) => setState(() {
        remaining = (remaining + delta).clamp(1, 600);
        if (remaining > total) total = remaining;
      });

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 추천값과 같은 칸은 빼서 '추천 1:00'과 '1:00'이 겹치지 않게 (디자인 리뷰 11/04 #7)
    final presets = [widget.recommended, for (final s in const [30, 60, 90, 120]) if (s != widget.recommended) s];
    return Column(mainAxisSize: MainAxisSize.min, children: [
        const SheetTitle('휴식 타이머'),
        const SizedBox(height: AppSpace.m),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var i = 0; i < presets.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SelectChip(i == 0 ? '추천 ${_mmss(presets[i])}' : _mmss(presets[i]),
                    selected: total == presets[i], onSelected: (_) => _set(presets[i])),
              ),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(fit: StackFit.expand, children: [
            CircularProgressIndicator(
              value: remaining / total,
              strokeWidth: 8,
              color: AppColors.primary,
              backgroundColor: AppColors.primarySoft,
            ),
            // 큰 글씨 설정에서도 숫자가 원 밖으로 나가지 않게
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.l),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_mmss(remaining), style: AppText.timer),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: AppButton('− 10초', kind: ButtonKind.soft, top: 0, onPressed: () => _adjust(-10))),
          const SizedBox(width: AppSpace.sPlus),
          Expanded(child: AppButton('+ 10초', kind: ButtonKind.soft, top: 0, onPressed: () => _adjust(10))),
        ]),
        const SizedBox(height: AppSpace.m),
        // 운동을 그만두는 버튼처럼 보이지 않게 기본 색으로 (리뷰 10/28 #4)
        AppButton('휴식 끝내기', top: 0, onPressed: () => Navigator.pop(context)),
      ]);
  }
}
