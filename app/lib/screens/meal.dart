import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../routes.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/failure.dart';

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
        DayChips(labels: dayLabels, selected: day, onSelect: (i) => setState(() => day = i)),
        for (final m in meals) _MealCard(m),
        AppButton('오늘 식단 올리기',
            onPressed: () => requireLogin(context, '식단 사진은 내 계정에만 안전하게 보관하고, AI 답변은 횟수 관리가 필요해서 로그인 후에 쓸 수 있어요.')),
        const Disclaimer(text: '예시 식단은 의료 조언이 아닙니다.'),
      ]);
    }
    return TabBody(children: [
      const H1('식단'),
      DayChips(labels: dayLabels, selected: day, onSelect: (i) => setState(() => day = i)),
      const Muted("g(그램) 수와 칼로리는 AI가 추정한 값이에요. 같은 음식이 없으면 오른쪽 '대체' 음식으로 바꿔 드세요.", bottom: 10),
      for (final m in meals) _MealCard(m),
      LineRow(
        left: const Text('합계', style: TextStyle(fontWeight: FontWeight.w700)),
        right: Text('${formatNumber(total)} kcal', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      const H2('내가 올린 식단'),
      for (var i = 0; i < demo.mealPosts.length; i++)
        AppCard(
          onTap: () => Navigator.pushNamed(context, Routes.mealReply, arguments: i),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(demo.mealPosts[i].date, style: const TextStyle(fontWeight: FontWeight.w700)),
            Muted(demo.mealPosts[i].note, bottom: 4),
            Text(demo.mealPosts[i].reply, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
          ]),
        ),
      AppButton('오늘 식단 올리기', onPressed: () => Navigator.pushNamed(context, Routes.mealPost)),
      const Disclaimer(),
    ]);
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard(this.meal);
  final Meal meal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(meal.title, style: const TextStyle(fontWeight: FontWeight.w700))),
          Muted('${meal.kcal} kcal', bottom: 0),
        ]),
        for (final f in meal.foods)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${f.name} '),
                  TextSpan(text: '${f.grams}g', style: const TextStyle(fontWeight: FontWeight.w700)),
                ])),
              ),
              Flexible(
                child: Text('대체: ${f.altName} ${f.altGrams}g',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
              ),
            ]),
          ),
      ]),
    );
  }
}

/// S09 식단 올리기
class MealPostScreen extends StatefulWidget {
  const MealPostScreen({super.key});

  @override
  State<MealPostScreen> createState() => _MealPostScreenState();
}

class _MealPostScreenState extends State<MealPostScreen> {
  bool photoPicked = false;
  String note = '';

  void _post() {
    if (demo.quotaExhausted) {
      showQuotaExhausted(context);
      return;
    }
    if (!photoPicked) {
      toast(context, '사진을 먼저 선택해 주세요');
      return;
    }
    demo.update(() => demo.mealPosts.insert(
        0, MealPost('오늘 점심', note.isEmpty ? '(설명 없음)' : note, sampleMealReply, isToday: true)));
    Navigator.pushReplacementNamed(context, Routes.mealReply, arguments: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(title: '식단 올리기', children: [
      _PhotoBox(
        label: photoPicked ? '사진이 선택됐어요' : '눌러서 사진 선택',
        onTap: () => setState(() => photoPicked = !photoPicked),
      ),
      TextFormField(
        decoration: const InputDecoration(labelText: '한 줄 설명', hintText: '예: 닭가슴살 150g, 현미밥 1공기'),
        onChanged: (v) => note = v,
      ),
      const SizedBox(height: 10),
      const Muted('올리면 AI가 확인해서 답변해요 · 이번 달 2 / 5회 사용'),
      AppButton('올리기', onPressed: _post),
    ]);
  }
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 150,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.photo_camera_outlined, color: AppColors.primaryDark),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.primaryDark, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

/// S10 AI 답변
class MealReplyScreen extends StatefulWidget {
  const MealReplyScreen({super.key});

  @override
  State<MealReplyScreen> createState() => _MealReplyScreenState();
}

class _MealReplyScreenState extends State<MealReplyScreen> {
  bool waiting = true;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    _wait();
  }

  void _ask() {
    setState(() {
      waiting = true;
      failed = false;
    });
    _wait();
  }

  void _wait() {
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          waiting = false;
          failed = demo.failMode == 'AI 실패';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final index = (ModalRoute.of(context)?.settings.arguments as int?) ?? 0;
    final post = demo.mealPosts[index];
    return AppPage(title: 'AI 답변', children: [
      const _PhotoBox(label: '식단 사진'),
      Text(post.date, style: const TextStyle(fontWeight: FontWeight.w700)),
      Muted(post.note),
      if (waiting)
        const Padding(
          padding: EdgeInsets.only(top: 24),
          child: Column(children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 10),
            Muted('AI가 식단을 확인하는 중이에요'),
          ]),
        )
      else if (failed)
        FailureView(title: 'AI 답변을 받지 못했어요', onRetry: _ask)
      else
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: AppCard(accent: true, child: Text(post.reply)),
        ),
    ]);
  }
}
