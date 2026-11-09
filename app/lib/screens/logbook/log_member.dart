import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../routes.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// S12 운동일지 안내 (일반 회원)
class LogIntroTab extends StatelessWidget {
  const LogIntroTab({super.key});

  @override
  Widget build(BuildContext context) {
    return TabBody(children: [
      const H1('운동일지'),
      const Muted('PT 회원님 전용 기능이에요. 선생님이 수업마다 작성한 일지를 여기서 받아볼 수 있어요.'),
      // 흐린 일지가 내 기록처럼 보이지 않게 '예시'라고 쓰고, 글자가 읽히게 덜 흐리게 (리뷰 11/04 #7)
      const Muted('예시: PT를 시작하면 이렇게 받아요', top: AppSpace.s, bottom: AppSpace.xs),
      Opacity(
        opacity: 0.7,
        child: IgnorePointer(
          child: Column(children: [
            for (final log in workoutLogs.take(2))
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${log.date} · ${log.title}', style: AppText.bodyStrong),
                  Text(log.items.take(2).map((i) => '${i.name} ${i.dose}').join('\n')),
                ]),
              ),
          ]),
        ),
      ),
      AppButton('PT 문의하기', onPressed: () => toast(context, '선생님께 PT 문의가 전달돼요 (데모)')),
      AppButton('PT 코드가 있어요',
          kind: ButtonKind.soft,
          onPressed: () => demo.isGuest
              ? requireLogin(context, '운동일지는 본인만 볼 수 있어야 해서, PT 코드는 로그인한 계정에 연결해요.')
              : Navigator.pushNamed(context, Routes.ptCode)),
    ]);
  }
}

/// S13 운동일지 목록 (PT 회원)
class LogListTab extends StatelessWidget {
  const LogListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = demo.logsOf(demo.memberName);
    return TabBody(children: [
      const H1('운동일지'),
      if (demo.ptEnded) ...[
        const Muted('선생님과 연결이 끊겼어요. 받은 일지와 영상은 계속 볼 수 있어요.'),
        AppButton('PT 코드가 있어요', kind: ButtonKind.soft, top: 0, onPressed: () => Navigator.pushNamed(context, Routes.ptCode)),
        const SizedBox(height: AppSpace.m),
      ] else
        const Muted('담당 선생님이 작성한 내 일지예요. 나만 볼 수 있어요.'),
      if (logs.isEmpty) const AppCard(child: WordText('아직 받은 일지가 없어요. 수업이 끝나면 선생님이 여기 올려 줘요.')),
      for (final log in logs)
        AppCard(
          showArrow: true,
          onTap: () {
            demo.update(() {
              demo.firstLogSeen = true;
              demo.unseenLogs.remove(log);
            });
            Navigator.pushNamed(context, Routes.logDetail, arguments: log);
          },
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: WordText('${log.date} · ${log.title}', style: AppText.bodyStrong)),
              // 안 본 일지를 구분한다 (리뷰 11/04 #7)
              LogStatusLabels(edited: log.edited, isNew: demo.unseenLogs.contains(log)),
            ]),
            Muted(
              '${log.items.length}종목'
              '${log.videos.isEmpty ? '' : ' · 영상 ${log.videos.length}개'}'
              '${log.comment.isEmpty ? '' : ' · ${log.comment}'}',
              bottom: 0,
            ),
          ]),
        ),
    ]);
  }
}

/// S14 운동일지 상세
class LogDetailScreen extends StatelessWidget {
  const LogDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    final log = arg is WorkoutLog ? arg : workoutLogs.first;
    // 새 일지가 들어와도 목록 순서와 상관없이 같은 영상을 가리키게 날짜·제목으로 구분한다
    String videoKey(int j) => '${log.date}-${log.title}-$j';
    return AppPage(title: '${log.date} · ${log.title}', children: [
      for (final item in log.items)
        LineRow(
          rightBelowOnLargeText: true,
          showArrow: true,
          onTap: () => Navigator.pushNamed(context, Routes.exerciseDetail, arguments: item.name),
          left: Row(children: [
            ExerciseThumb(item.name),
            const SizedBox(width: AppSpace.sPlus),
            Expanded(child: WordText(item.name)),
          ]),
          right: Muted(item.dose, bottom: 0),
        ),
      if (log.videos.isNotEmpty) ...[
        const H2('운동 영상'),
        for (var j = 0; j < log.videos.length; j++) ...[
          // Container 대신 Ink로 그려야 누를 때 물결이 색 위로 보인다 (디자인 리뷰 11/01 #1)
          InkWell(
            onTap: () => toast(context, '영상 재생 (데모)'),
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Ink(
              height: 130,
              decoration: BoxDecoration(color: AppColors.text, borderRadius: BorderRadius.circular(AppRadius.card)),
              child: Stack(children: [
                const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 44)),
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: Text(log.videos[j].name, style: AppText.small.copyWith(color: Colors.white)),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              // '서버 보관 만료' 대신 쉬운 말로, 3일 이하면 경고색 (리뷰 11/02 #7)
              Expanded(
                child: WordText('${log.videos[j].daysLeft}일 뒤 사라져요. 남기려면 내 폰에 저장하세요',
                    style: AppText.caption.copyWith(color: log.videos[j].daysLeft <= 3 ? AppColors.warningText : AppColors.textSub)),
              ),
              if (demo.savedVideos.contains(videoKey(j)))
                const Muted('내 폰에 저장됨', bottom: 0)
              else
                OutlinedButton(
                  onPressed: () {
                    demo.update(() => demo.savedVideos.add(videoKey(j)));
                    toast(context, '영상을 내 폰에 저장했어요');
                  },
                  child: const Text('내 폰에 저장'),
                ),
            ]),
          ),
        ],
      ],
      if (log.edited) const Muted('선생님이 보낸 뒤에 고친 일지예요.', top: AppSpace.s),
      // 다른 강조 카드와 같은 모양 (디자인 리뷰 10/28 #6)
      Padding(
        padding: const EdgeInsets.only(top: AppSpace.sPlus),
        child: AppCard(
          accent: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('선생님 코멘트', bottom: AppSpace.xs),
          if (log.comment.isNotEmpty) ...[
            Text(log.comment),
            const SizedBox(height: AppSpace.s),
          ],
          InfoTag(log.stamp),
        ]),
        ),
      ),
    ]);
  }
}
