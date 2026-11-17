import 'package:flutter/material.dart';

import '../config.dart';
import '../data/mock_data.dart';
import '../routes.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/failure.dart';
import 'meal_reply.dart';

/// 지금 시각에 맞는 끼니 (식단 올리기의 처음 값)
String mealSlotFor(DateTime t) => switch (t.hour) {
      >= 5 && < 10 => '아침',
      >= 10 && < 15 => '점심',
      >= 17 && < 21 => '저녁',
      _ => '간식',
    };

/// S09 식단 올리기
class MealPostScreen extends StatefulWidget {
  const MealPostScreen({super.key});

  @override
  State<MealPostScreen> createState() => _MealPostScreenState();
}

class _MealPostScreenState extends State<MealPostScreen> {
  bool photoPicked = false;
  String note = '';

  /// 어느 끼니인지. 늘 '점심'으로 저장되지 않게 고른다 (리뷰 11/01 #4)
  String slot = mealSlotFor(DateTime.now());

  void _post() {
    if (demo.quotaExhausted) {
      showQuotaExhausted(context);
      return;
    }
    // 사진이나 글 중 하나만 있어도 올린다 (결정 d1101-2)
    if (!photoPicked && note.trim().isEmpty) {
      toast(context, '사진이나 설명을 넣어 주세요');
      return;
    }
    demo.update(() => demo.mealPosts.insert(
        0, MealPost('오늘 $slot', note.isEmpty ? '(설명 없음)' : note, sampleMealReply, isToday: true, hasPhoto: photoPicked, replied: false)));
    Navigator.pushReplacementNamed(context, Routes.mealReply, arguments: const MealReplyArgs(0, fresh: true));
  }

  /// 쓰던 내용(사진·설명)이 있는지
  bool get dirty => photoPicked || note.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // 쓰던 내용이 있는데 뒤로 가면 지울지 먼저 묻는다 (리뷰 11/01 #3)
    return DiscardGuard(
      dirty: dirty,
      title: '쓰던 내용을 지울까요?',
      body: '나가면 고른 사진과 설명이 사라져요.',
      keepLabel: '계속 쓰기',
      okLabel: '지우고 나가기',
      child: AppPage(title: '식단 올리기', children: [
      // 올린 식단은 선생님에게 보이지 않는다 (결정 d1101-1)
      const Muted('나만 볼 수 있어요. 선생님에게는 보이지 않고, 답변을 위해 AI만 확인해요.'),
      const FieldLabel('어느 끼니인가요?'),
      Seg(options: const ['아침', '점심', '저녁', '간식'], value: slot, onChanged: (v) => setState(() => slot = v)),
      // 다시 눌러도 사진이 말없이 빠지지 않게: 누르면 바꾸기, 빼기는 따로 (리뷰 11/01 #2)
      MealPhotoBox(
        label: photoPicked ? '사진이 선택됐어요 · 눌러서 바꾸기' : '눌러서 사진 선택',
        picked: photoPicked,
        onTap: () {
          if (photoPicked) toast(context, '사진을 바꿨어요');
          setState(() => photoPicked = true);
        },
      ),
      if (photoPicked)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => setState(() => photoPicked = false), child: const Text('사진 빼기')),
        ),
      TextFormField(
        decoration: const InputDecoration(labelText: '한 줄 설명', hintText: '예: 닭가슴살 150g, 현미밥 1공기'),
        onChanged: (v) => setState(() => note = v),
      ),
      if (!photoPicked && note.trim().isNotEmpty) const Muted('사진이 있으면 더 정확해요', top: AppSpace.xs, bottom: 0),
      const SizedBox(height: AppSpace.sPlus),
      // 실제 사용 횟수를 보여 주고, 다 썼으면 누르기 전에 알린다 (리뷰 11/01 #1)
      if (demo.quotaExhausted)
        const WarningBox('이번 달 무료 횟수를 다 썼어요', top: 0)
      else
        Muted('올리면 AI가 확인해서 답변해요 · 이번 달 ${demo.aiUsedShown} / ${AppConfig.freeMonthlyAiLimit}회 사용'),
      AppButton('올리기', onPressed: _post),
    ]),
    );
  }
}

class MealPhotoBox extends StatelessWidget {
  const MealPhotoBox({super.key, required this.label, this.onTap, this.picked = false});
  final String label;
  final VoidCallback? onTap;

  /// 사진을 고른 뒤에는 체크 표시를 남긴다
  final bool picked;

  @override
  Widget build(BuildContext context) {
    // 누를 수 없는 사진 자리(AI 답변 화면)는 버튼처럼 보이지 않게 (디자인 리뷰 10/29 #7)
    final tappable = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.m),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        // Container 대신 Ink로 그려야 누를 때 물결이 색 위로 보인다 (디자인 리뷰 11/01 #1)
        child: Ink(
          height: 150,
          decoration: BoxDecoration(
            color: tappable ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: tappable ? Border.all(color: AppColors.primary) : null,
          ),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
                picked
                    ? Icons.check_circle
                    : tappable
                        ? Icons.photo_camera_outlined
                        : Icons.image_outlined,
                color: tappable ? AppColors.primaryDark : AppColors.textSub),
            const SizedBox(height: AppSpace.xs),
            Text(label, style: AppText.caption.copyWith(color: tappable ? AppColors.primaryDark : AppColors.textSub)),
          ]),
          ),
        ),
      ),
    );
  }
}
