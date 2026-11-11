/// 공용 부품: 운동 그림·통증 표시·로딩·경고
library;

import 'package:flutter/material.dart';

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

/// 빨간 큰 경고 상자 (디자인 리뷰 10/28 #3)
class WarningBox extends StatelessWidget {
  const WarningBox(this.text, {super.key, this.top = 12});
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: top),
      padding: const EdgeInsets.all(AppSpace.mPlus),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.box),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 26),
        const SizedBox(width: AppSpace.sPlus),
        Expanded(
          child: Text(text,
              style: AppText.warning.copyWith(color: AppColors.warningText)),
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
