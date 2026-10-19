import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'common.dart';

String _mmss(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// 세트를 마치면 뜨는 휴식 타이머. [recommendedSeconds]는 강도 규칙의 휴식 시간 (기획서 6번).
Future<void> showRestTimer(BuildContext context, int recommendedSeconds) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.background,
    // 작은 화면에서도 아래 버튼이 잘리지 않게 높이를 내용에 맞추고, 넘치면 스크롤한다
    isScrollControlled: true,
    builder: (_) => SafeArea(child: SingleChildScrollView(child: _RestTimer(recommended: recommendedSeconds))),
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
      HapticFeedback.heavyImpact();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('휴식 끝! 다음 세트를 시작하세요')));
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
    final presets = [widget.recommended, 30, 60, 90, 120];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('휴식 타이머', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var i = 0; i < presets.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(i == 0 ? '추천 ${_mmss(presets[i])}' : _mmss(presets[i])),
                  selected: total == presets[i] && (i == 0 || presets[i] != widget.recommended),
                  showCheckmark: false,
                  selectedColor: AppColors.primarySoft,
                  shape: const StadiumBorder(),
                  onSelected: (_) => _set(presets[i]),
                ),
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
            Center(
              child: Text(_mmss(remaining),
                  style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: AppColors.text)),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: AppButton('- 10초', kind: ButtonKind.soft, top: 0, onPressed: () => _adjust(-10))),
          const SizedBox(width: 10),
          Expanded(child: AppButton('+ 10초', kind: ButtonKind.soft, top: 0, onPressed: () => _adjust(10))),
        ]),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
          onPressed: () => Navigator.pop(context),
          child: const Text('휴식 중단'),
        ),
      ]),
    );
  }
}
