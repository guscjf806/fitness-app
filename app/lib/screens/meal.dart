/// 식단 화면 모음. 식단 탭(S08), 식단 올리기(S09, meal_post.dart), AI 답변(S10, meal_reply.dart) (디자인 리뷰 11/17 #5)
library;

import 'package:flutter/material.dart';

import '../config.dart';
import '../data/mock_data.dart';
import '../routes.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'meal_reply.dart';
import 'onboarding/result.dart';

export 'meal_post.dart';
export 'meal_reply.dart';

/// S08 식단
class MealTab extends StatefulWidget {
  const MealTab({super.key});

  @override
  State<MealTab> createState() => _MealTabState();
}

class _MealTabState extends State<MealTab> {
  int day = 0;

  @override
  Widget build(BuildContext context) {
    final meals = mealDays[day % 2];
    final total = meals.fold<int>(0, (sum, m) => sum + m.kcal);
    if (demo.isGuest) {
      return TabBody(children: [
        const H1('예시 식단'),
        const GuestBanner('로그인하면 내 목표 칼로리에 맞춘 식단을 만들고, 먹은 식단을 올려 AI 답변을 받을 수 있어요.'),
        DayChips(labels: dayLabels, selected: day, today: 0, onSelect: (i) => setState(() => day = i)),
        for (final m in meals) _MealCard(m),
        AppButton('오늘 식단 올리기',
            onPressed: () => requireLogin(context, '식단 사진은 내 계정에만 안전하게 보관하고, AI 답변은 횟수 관리가 필요해서 로그인 후에 쓸 수 있어요.')),
        const Disclaimer(text: '예시 식단은 의료 조언이 아닙니다.'),
      ]);
    }
    return TabBody(children: [
      const H1('식단'),
      PlanOutdatedBanner(onRegenerate: () => openPlanMaker(context)),
      DayChips(labels: dayLabels, selected: day, today: 0, onSelect: (i) => setState(() => day = i)),
      const Muted("g(그램) 수와 칼로리는 AI가 추정한 값이에요. 같은 음식이 없으면 '없으면 →' 뒤의 음식으로 바꿔 드세요.", bottom: AppSpace.sPlus),
      for (final m in meals) _MealCard(m, canCheck: day == 0),
      LineRow(
        left: const Text('합계', style: AppText.bodyStrong),
        // 목표와 비교할 수 있게 (리뷰 11/01 #7)
        right: Text('${formatNumber(total)} / 목표 ${formatNumber(demo.tdee.target)} kcal', style: AppText.bodyStrong),
      ),
      const H2('내가 올린 식단'),
      if (demo.mealPosts.isEmpty) const Muted('아직 올린 식단이 없어요. 아래 버튼으로 첫 끼니를 올려 보세요.'),
      for (var i = 0; i < demo.mealPosts.length; i++)
        AppCard(
          showArrow: true,
          onTap: () => Navigator.pushNamed(context, Routes.mealReply, arguments: i),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(demo.mealPosts[i].date, style: AppText.bodyStrong),
            Muted(demo.mealPosts[i].note, bottom: AppSpace.xs),
            // 답변을 못 받은 글에 답변 첫 줄이 보이면 답이 온 줄 안다 (리뷰 11/16 #1)
            if (demo.replyPending.contains(demo.mealPosts[i]))
              const MealPostStatus(MealReplyState.pending)
            else if (demo.mealPosts[i].replied) ...[
              // 나가 있는 동안 온 답변은 열어 볼 때까지 표시한다 (결정 d1116-1)
              if (!demo.mealPosts[i].seen) const MealPostStatus(MealReplyState.newReply),
              Text(demo.mealPosts[i].reply, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
            ] else
              const MealPostStatus(MealReplyState.failed),
          ]),
        ),
      AppButton('오늘 식단 올리기', onPressed: () => Navigator.pushNamed(context, Routes.mealPost)),
      const Disclaimer(),
    ]);
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard(this.meal, {this.canCheck = false});
  final Meal meal;

  /// 오늘 식단이면 끼니마다 '먹었어요'를 누를 수 있다 (결정 d1101-3)
  final bool canCheck;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(meal.title, style: AppText.bodyStrong)),
          Muted('${meal.kcal} kcal', bottom: 0),
        ]),
        for (final f in meal.foods)
          Container(
            margin: const EdgeInsets.only(top: AppSpace.s),
            padding: const EdgeInsets.only(top: AppSpace.s),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
            // 대체 음식은 음식 이름 바로 아래 줄에 (결정 dd1029-alt-food)
            child: SizedBox(
              width: double.infinity,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: '${f.name} '),
                  TextSpan(text: '${f.grams}g', style: AppText.bodyStrong),
                ])),
                // 장 볼 때 보는 정보라 50대 이상도 읽기 쉽게 본문 크기로 (리뷰 11/06 #5, 사용자 선택 14px)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.xxs),
                  child: WordText('없으면 → ${f.altName} ${f.altGrams}g', style: AppText.body.copyWith(color: AppColors.textSub)),
                ),
              ]),
            ),
          ),
        if (canCheck)
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.small),
              // 올린 끼니는 칼로리를 보고 고칠 수 있는 AI 답변 화면을 연다 (리뷰 11/12 #2)
              onTap: () {
                final posted = demo.mealPosts.indexWhere((p) => p.isToday && p.date == '오늘 ${meal.title}');
                if (posted >= 0) {
                  Navigator.pushNamed(context, Routes.mealReply, arguments: MealReplyArgs(posted));
                } else {
                  _pickAmount(context, meal.title, meal.kcal);
                }
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  // 올린 끼니는 먹은 것으로 보이고 AI가 계산한 칼로리를 같이 보여 준다 (리뷰 11/11 #4)
                  // 답변을 받는 중이면 다 된 체크 대신 로딩 원 (디자인 리뷰 11/17 #3)
                  if (demo.postedReplying(meal.title))
                    const SizedBox.square(dimension: 22, child: Center(child: InlineSpinner(size: 16)))
                  else
                    CheckCircle(demo.eatenMeals.contains(meal.title) || demo.postedToday(meal.title)),
                  const SizedBox(width: AppSpace.s),
                  // 큰 글씨에서 넘치지 않게 두 줄까지 허용 (디자인 리뷰 11/12 #2)
                  Flexible(
                    child: WordText(_checkLabel(meal.title), textAlign: TextAlign.end),
                  ),
                  // 누르면 화면이 열리는 줄이라 화살표로 알린다
                  if (demo.postedToday(meal.title)) const Icon(Icons.chevron_right, size: 20, color: AppColors.textSub),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

/// 식단표 끼니 줄 오른쪽 글
String _checkLabel(String slot) {
  // 받는 중인 끼니를 실패로 보이지 않게 (리뷰 11/17 #1)
  if (demo.postedReplying(slot)) return '올림 · 답변 받는 중';
  // 답변을 못 받은 끼니는 칼로리 없이 알린다 (결정 d1113-2)
  if (demo.postedUnreplied(slot)) return '올림 · 답변 못 받음';
  final kcal = demo.postedKcal(slot);
  if (kcal == null) return demo.eatenMeals.contains(slot) ? '먹었어요 · ${demo.eatenAmount(slot)}' : '먹었어요';
  return demo.postedKcalEdited(slot) ? '올림 · $kcal kcal (고친 값)' : '올림 · 약 $kcal kcal';
}

/// '먹었어요'를 누르면 먹은 양을 고른다. 이미 고른 끼니는 양을 바꾸거나 되돌릴 수 있다 (결정 d1112-2)
void _pickAmount(BuildContext context, String slot, int planKcal) {
  final eaten = demo.eatenMeals.contains(slot);
  showAppSheet<void>(
    context,
    builder: (sheet) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      SheetTitle('$slot, 얼마나 먹었어요?'),
      // 쉬운 말로, 고르기 전에 칼로리를 보여 준다 (리뷰 11/17 #6)
      const Muted('고른 양에 맞춰 오늘 먹은 칼로리를 대략 계산해요.', top: AppSpace.xs),
      for (final MapEntry(key: amount, value: factor) in AppConfig.mealAmountFactors.entries)
        AppButton('$amount · 약 ${formatNumber((planKcal * factor).round())} kcal',
            kind: eaten && demo.eatenAmount(slot) == amount ? ButtonKind.primary : ButtonKind.soft,
            selected: eaten && demo.eatenAmount(slot) == amount, onPressed: () {
          demo.update(() {
            demo.eatenMeals.add(slot);
            demo.eatenAmounts[slot] = amount;
          });
          Navigator.pop(sheet);
        }),
      if (eaten)
        AppButton('안 먹은 걸로 되돌리기', kind: ButtonKind.quiet, onPressed: () {
          demo.update(() {
            demo.eatenMeals.remove(slot);
            demo.eatenAmounts.remove(slot);
          });
          Navigator.pop(sheet);
        }),
    ]),
  );
}
