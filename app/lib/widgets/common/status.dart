/// 공용 부품: 운동 그림·통증 표시·로딩·경고
library;

import 'package:flutter/material.dart';

import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../exercise_figure.dart';
import '../common.dart';

/// 운동 종목 썸네일: 동작 그림이 있으면 그림, 선생님이 직접 입력한 종목이면 첫 글자
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb(this.name, {super.key, this.size = 40});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final info = exerciseByName(name);
    if (info != null) return ExerciseFigureView(info.id, size: size, radius: AppRadius.small);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: AppColors.primaryDark, borderRadius: BorderRadius.circular(AppRadius.small)),
      child: Text(name.characters.first,
          style: AppText.bodyStrong.copyWith(color: Colors.white)),
    );
  }
}

/// 누를 수 없는 작은 정보 표시: 회색 알약, 주의할 내용만 주황 (결정 dd1101-infotag)
class InfoTag extends StatelessWidget {
  const InfoTag(this.text, {super.key, this.caution = false});
  final String text;
  final bool caution;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sPlus, vertical: AppSpace.xs),
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: caution ? AppColors.cautionSoft : AppColors.surface,
        ),
        child: Text(text,
            style: AppText.caption.copyWith(
              color: caution ? AppColors.caution : AppColors.text,
              fontWeight: caution ? FontWeight.w700 : FontWeight.w400,
            )),
      );
}

/// 아픈 부위와 겹치는 운동에 붙이는 표시. 예: '무릎·허리 주의' (디자인 리뷰 10/28 #2)
class PainTag extends StatelessWidget {
  const PainTag(this.areas, {super.key});
  final List<String> areas;

  @override
  Widget build(BuildContext context) => Text('${areas.join('·')} 주의',
      style: AppText.body.copyWith(color: AppColors.warningText, fontWeight: FontWeight.w700));
}

/// 아픈 부위와 겹치는 운동의 경고 문구 (운동 상세와 운동 진행에서 같이 쓴다)
String painPhrase(List<String> areas) => '${areas.join(', ')} 통증이 있으면 이 운동은 피하는 게 좋아요.';

/// '만드는 중' 로딩 표시: 빙글빙글 + 굵은 문구 + 회색 보조 문구 (디자인 리뷰 10/30 #5)
class LoadingView extends StatelessWidget {
  const LoadingView(this.message, {super.key, this.sub});
  final String message;
  final String? sub;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: AppSpace.l),
        Text(message, textAlign: TextAlign.center, style: AppText.bodyStrong),
        if (sub != null) Muted(sub!, align: TextAlign.center),
      ]);
}

/// 빨간 큰 경고 상자 (디자인 리뷰 10/28 #3). [caution]이면 덜 급한 주황 '주의' 상자
class WarningBox extends StatelessWidget {
  const WarningBox(this.text, {super.key, this.top = 12, this.caution = false});
  final String text;
  final double top;
  final bool caution;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: top),
      padding: const EdgeInsets.all(AppSpace.mPlus),
      decoration: BoxDecoration(
        color: caution ? AppColors.cautionSoft : AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.box),
        border: Border.all(color: caution ? AppColors.caution : AppColors.warning),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(caution ? Icons.info_outline_rounded : Icons.warning_amber_rounded,
            color: caution ? AppColors.caution : AppColors.warning, size: 26),
        const SizedBox(width: AppSpace.sPlus),
        Expanded(
          // 큰 글씨에서 낱말 중간에서 끊기지 않게 (디자인 리뷰 11/13 #2)
          child: WordText(text,
              style: AppText.warning.copyWith(color: caution ? AppColors.caution : AppColors.warningText)),
        ),
      ]),
    );
  }
}

/// 일지 상태 표시: 수정됨(회색)·새 일지(청록 굵게). 회원 일지 목록과 선생님 시트가 같이 쓴다 (디자인 리뷰 11/08 #2)
class LogStatusLabels extends StatelessWidget {
  const LogStatusLabels({super.key, required this.edited, this.isNew = false});
  final bool edited;
  final bool isNew;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        if (edited) const Muted('수정됨', bottom: 0),
        if (edited && isNew) const SizedBox(width: AppSpace.s),
        if (isNew) const Text('새 일지', style: AppText.captionAccent),
      ]);
}

/// 못 먹는 음식·아픈 부위를 고치고 '나중에'를 눌렀을 때 식단·운동 탭 맨 위에 둔다 (결정 d1111-1).
/// 안전을 위한 수정이라 새로 만들어도 무료 횟수를 쓰지 않는다 (결정 d1107-1)
class PlanOutdatedBanner extends StatelessWidget {
  const PlanOutdatedBanner({super.key, required this.onRegenerate});

  /// 내 정보의 '식단·루틴 새로 만들기'와 같은 길(기간 선택 → 만드는 중)로 보낸다 (리뷰 11/12 #5)
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    if (!demo.planOutdated || demo.isGuest) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // 아픈 부위 경고보다 덜 무섭게 주황 '주의'로 (사용자 요청 2026-11-11)
      // 무엇이 바뀌었는지와 무료 횟수를 쓰지 않는다는 것까지 알린다 (리뷰 11/12 #4)
      const WarningBox('못 먹는 음식·아픈 부위가 바뀌었어요. 안전을 위해 새로 만들어 주세요. 무료 횟수는 쓰지 않아요.', top: 0, caution: true),
      AppButton('새로 만들기', kind: ButtonKind.soft, top: AppSpace.s, onPressed: onRegenerate),
      const SizedBox(height: AppSpace.m),
    ]);
  }
}
