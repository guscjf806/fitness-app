import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../routes.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/failure.dart';
import 'meal_post.dart';

/// 목업 AI 칼로리 추정: 그 끼니 식단표보다 조금 많게. 실제로는 AI 답변에서 받는다 (결정 d1107-2)
int _estimateKcal(String slot) {
  final planned = mealDays[0].where((m) => m.title == slot).firstOrNull?.kcal;
  return planned == null ? 300 : (planned * 1.1).round();
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

/// 지금 답변 화면에 열려 있는 글. 이 글의 답변이 오면 알림 대신 화면에 바로 보여 준다
MealPost? _viewingPost;
ModalRoute<Object?>? _viewingRoute;

/// AI 답변을 받는다. 화면을 나가도 뒤에서 계속 받고, 나가 있으면 다 된 뒤 알린다 (결정 d1116-1)
/// 실제로는 서버가 답변을 저장하고 푸시 알림을 보낸다. 지금은 앱 안 알림 띠로 대신한다
void requestMealReply(MealPost post, ScaffoldMessengerState messenger) {
  // 화면을 그리는 중에 불릴 수 있어 바로 넣고, 다른 화면에는 그린 뒤 알린다
  demo.replyPending.add(post);
  Future.microtask(() => demo.update(() {}));
  Future<void>.delayed(const Duration(milliseconds: 1200), () {
    // 뒤로 나가는 중인 화면은 보고 있지 않은 것으로 본다
    final viewing = identical(_viewingPost, post) && (_viewingRoute?.isCurrent ?? false);
    final failed = demo.failMode == 'AI 실패';
    var target = post;
    demo.update(() {
      demo.replyPending.remove(post);
      final i = demo.mealPosts.indexWhere((p) => identical(p, post));
      // 답변을 받았을 때만 이번 달 횟수를 1회 올리고 칼로리를 채운다. 실패하면 둘 다 하지 않는다 (리뷰 11/01 #1, 11/13 #1)
      if (i < 0 || failed || post.replied) return;
      final updated = post.withReply(_estimateKcal(post.date.replaceFirst('오늘 ', '')), seen: viewing);
      demo.mealPosts[i] = target = updated;
      demo.aiUsed++;
      if (viewing) _viewingPost = updated;
    });
    if (viewing) return;
    // 띠가 떠 있는 동안 새 글을 올리면 순서가 밀리니, 누르는 순간 그 글을 다시 찾는다 (리뷰 11/17 #5)
    toastOn(messenger, failed ? '${post.date} 식단의 AI 답변을 받지 못했어요' : '${post.date} 식단에 AI 답변이 왔어요',
        actionLabel: '보기', onAction: () {
      var i = demo.mealPosts.indexWhere((p) => identical(p, target));
      if (i < 0) i = demo.mealPosts.indexWhere((p) => p.date == post.date && p.note == post.note);
      if (i >= 0) demoNavigatorKey.currentState?.pushNamed(Routes.mealReply, arguments: MealReplyArgs(i));
    });
  });
}

class _MealReplyScreenState extends State<MealReplyScreen> {

  MealReplyArgs get args => switch (ModalRoute.of(context)?.settings.arguments) {
        final MealReplyArgs a => a,
        final int i => MealReplyArgs(i),
        _ => const MealReplyArgs(0),
      };

  bool started = false;
  ModalRoute<Object?>? _route;

  /// 방금 올린 글만 AI 답변을 받는다. 이미 받은 지난 답변은 바로 보여 준다 (리뷰 11/01 #5)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    _viewingPost = demo.mealPosts[args.index];
    _route = _viewingRoute = ModalRoute.of(context);
    if (args.fresh) requestMealReply(demo.mealPosts[args.index], ScaffoldMessenger.of(context));
  }

  @override
  void dispose() {
    if (identical(_viewingRoute, _route)) {
      _viewingPost = null;
      _viewingRoute = null;
    }
    super.dispose();
  }

  void _ask() {
    // 올리기 버튼처럼 다시 시도도 무료 횟수를 다 썼으면 막는다 (리뷰 11/16 #2)
    if (demo.quotaExhausted) {
      showQuotaExhausted(context);
      return;
    }
    requestMealReply(demo.mealPosts[args.index], ScaffoldMessenger.of(context));
  }

  Future<void> _editKcal(int index) async {
    var text = '${demo.mealPosts[index].kcal}';
    int? valid() {
      final v = int.tryParse(text.trim());
      return v != null && v >= 1 && v <= 5000 ? v : null;
    }

    // 잘못 적으면 창 안에서 알려 주고, 맞는 숫자일 때만 저장을 누를 수 있다 (리뷰 11/12 #6)
    final value = await showDialog<int>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        // 큰 글씨에 키보드가 올라와도 창 안에서 스크롤되게 (디자인 리뷰 11/13 #1)
        builder: (dialog, setInner) => AlertDialog(
          scrollable: true,
          title: const Text('칼로리 고치기'),
          content: NumField(
            label: '칼로리',
            suffix: 'kcal',
            value: text,
            decimal: false,
            error: valid() == null ? '1에서 5,000 사이의 숫자로 적어 주세요' : null,
            onChanged: (v) => setInner(() => text = v),
            // 창을 열면 바로 키보드가 뜨고, 키보드 완료로도 저장된다 (디자인 리뷰 11/12 #5)
            autofocus: true,
            onSubmitted: (_) {
              final v = valid();
              if (v != null) Navigator.pop(dialog, v);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('그만두기')),
            TextButton(onPressed: valid() == null ? null : () => Navigator.pop(dialog, valid()), child: const Text('저장')),
          ],
        ),
      ),
    );
    if (value == null || !mounted) return;
    demo.update(() => demo.mealPosts[index] = demo.mealPosts[index].withKcal(value));
    toast(context, '$value kcal로 고쳤어요. 홈 칼로리에도 반영돼요');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: demo, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final index = args.index;
    final post = demo.mealPosts[index];
    // 받는 중이면 기다림, 답변을 못 받았으면 실패. 화면을 나갔다 와도 그대로 이어진다 (결정 d1116-1)
    final waiting = demo.replyPending.contains(post);
    final failed = !waiting && !post.replied;
    // 열어 봤으니 '답변 왔어요' 표시를 지운다
    if (post.replied && !post.seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(demo.mealPosts[index], post)) demo.update(() => demo.mealPosts[index] = post.withSeen());
      });
    }
    return AppPage(title: 'AI 답변', children: [
      if (post.hasPhoto) const MealPhotoBox(label: '식단 사진'),
      Text(post.date, style: AppText.bodyStrong),
      Muted(post.note),
      if (waiting)
        const Padding(
          padding: EdgeInsets.only(top: AppSpace.xl),
          child: LoadingView('AI가 식단을 확인하는 중이에요'),
        )
      else if (failed)
        FailureView(title: 'AI 답변을 받지 못했어요', onRetry: _ask)
      else
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.sPlus),
          child: AppCard(accent: true, child: WordText(post.reply)),
        ),
      // 홈 칼로리에 더해진 숫자를 회원이 볼 수 있게 (리뷰 11/11 #4)
      // AI 추정은 틀릴 수 있어 눌러서 고치게 한다 (결정 d1111-2)
      if (!waiting && !failed && post.kcal != null) ...[
        LineRow(
          onTap: () => _editKcal(index),
          // 고친 뒤에는 AI 값처럼 보이지 않게 (리뷰 11/12 #1)
          left: WordText(post.kcalEdited ? '${post.kcal} kcal (내가 고친 값)' : '약 ${post.kcal} kcal로 계산했어요(AI 추정)'),
          right: Text('고치기', style: AppText.bodyStrong.copyWith(color: AppColors.primaryDark)),
        ),
        const Muted('홈의 오늘 먹은 칼로리에 더해져요.', top: AppSpace.xs),
      ],
    ]);
  }
}
