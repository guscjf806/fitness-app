import 'package:flutter/material.dart';

import '../config.dart';
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
        DayChips(labels: dayLabels, selected: day, today: 0, onSelect: (i) => setState(() => day = i)),
        for (final m in meals) _MealCard(m),
        AppButton('오늘 식단 올리기',
            onPressed: () => requireLogin(context, '식단 사진은 내 계정에만 안전하게 보관하고, AI 답변은 횟수 관리가 필요해서 로그인 후에 쓸 수 있어요.')),
        const Disclaimer(text: '예시 식단은 의료 조언이 아닙니다.'),
      ]);
    }
    return TabBody(children: [
      const H1('식단'),
      DayChips(labels: dayLabels, selected: day, today: 0, onSelect: (i) => setState(() => day = i)),
      const Muted("g(그램) 수와 칼로리는 AI가 추정한 값이에요. 같은 음식이 없으면 '없으면 →' 뒤의 음식으로 바꿔 드세요.", bottom: 10),
      for (final m in meals) _MealCard(m),
      LineRow(
        left: const Text('합계', style: AppText.bodyStrong),
        // 목표와 비교할 수 있게 (리뷰 11/01 #7)
        right: Text('${formatNumber(total)} / 목표 ${formatNumber(demo.tdee.target)} kcal', style: AppText.bodyStrong),
      ),
      const H2('내가 올린 식단'),
      if (demo.mealPosts.isEmpty) const Muted('아직 올린 식단이 없어요. 아래 버튼으로 첫 끼니를 올려 보세요.'),
      for (var i = 0; i < demo.mealPosts.length; i++)
        AppCard(
          onTap: () => Navigator.pushNamed(context, Routes.mealReply, arguments: i),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(demo.mealPosts[i].date, style: AppText.bodyStrong),
            Muted(demo.mealPosts[i].note, bottom: AppSpace.xs),
            Text(demo.mealPosts[i].reply, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
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
          Expanded(child: Text(meal.title, style: AppText.bodyStrong)),
          Muted('${meal.kcal} kcal', bottom: 0),
        ]),
        for (final f in meal.foods)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
            // 대체 음식은 음식 이름 바로 아래 줄에 (결정 dd1029-alt-food)
            child: SizedBox(
              width: double.infinity,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: '${f.name} '),
                  TextSpan(text: '${f.grams}g', style: AppText.bodyStrong),
                ])),
                Muted('없으면 → ${f.altName} ${f.altGrams}g', top: 2, bottom: 0),
              ]),
            ),
          ),
      ]),
    );
  }
}

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
    if (!photoPicked) {
      toast(context, '사진을 먼저 선택해 주세요');
      return;
    }
    demo.update(() => demo.mealPosts.insert(
        0, MealPost('오늘 $slot', note.isEmpty ? '(설명 없음)' : note, sampleMealReply, isToday: true)));
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
      const FieldLabel('어느 끼니인가요?'),
      Seg(options: const ['아침', '점심', '저녁', '간식'], value: slot, onChanged: (v) => setState(() => slot = v)),
      // 다시 눌러도 사진이 말없이 빠지지 않게: 누르면 바꾸기, 빼기는 따로 (리뷰 11/01 #2)
      _PhotoBox(
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
      const SizedBox(height: 10),
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

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.label, this.onTap, this.picked = false});
  final String label;
  final VoidCallback? onTap;

  /// 사진을 고른 뒤에는 체크 표시를 남긴다
  final bool picked;

  @override
  Widget build(BuildContext context) {
    // 누를 수 없는 사진 자리(AI 답변 화면)는 버튼처럼 보이지 않게 (디자인 리뷰 10/29 #7)
    final tappable = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

/// AI 답변 화면에 넘기는 값. [fresh]는 방금 올린 글이라 AI 답변을 새로 받는다는 뜻
class MealReplyArgs {
  const MealReplyArgs(this.index, {this.fresh = false});
  final int index;
  final bool fresh;
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

  /// 이번 답변을 횟수에 이미 셌는지 (다시 시도해도 한 번만 센다)
  bool counted = false;

  MealReplyArgs get args => switch (ModalRoute.of(context)?.settings.arguments) {
        final MealReplyArgs a => a,
        final int i => MealReplyArgs(i),
        _ => const MealReplyArgs(0),
      };

  bool started = false;

  /// 방금 올린 글만 AI 답변을 기다린다. 이미 받은 지난 답변은 바로 보여 준다 (리뷰 11/01 #5)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    if (args.fresh) {
      _wait();
    } else {
      waiting = false;
    }
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
        // 답변을 받았을 때만 이번 달 횟수를 1회 올린다. 실패하면 세지 않는다 (리뷰 11/01 #1)
        if (!failed && args.fresh && !counted) {
          counted = true;
          demo.update(() => demo.aiUsed++);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final index = args.index;
    final post = demo.mealPosts[index];
    return AppPage(title: 'AI 답변', children: [
      const _PhotoBox(label: '식단 사진'),
      Text(post.date, style: AppText.bodyStrong),
      Muted(post.note),
      if (waiting)
        const Padding(
          padding: EdgeInsets.only(top: 24),
          child: LoadingView('AI가 식단을 확인하는 중이에요'),
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
