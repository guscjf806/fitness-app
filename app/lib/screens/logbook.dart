import 'dart:math';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../routes.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// S12 운동일지 안내 (일반 회원)
class LogIntroTab extends StatelessWidget {
  const LogIntroTab({super.key});

  @override
  Widget build(BuildContext context) {
    return TabBody(children: [
      const H1('운동일지'),
      const Muted('PT 회원님 전용 기능이에요. 선생님이 수업마다 작성한 일지를 여기서 받아볼 수 있어요.'),
      Opacity(
        opacity: 0.45,
        child: IgnorePointer(
          child: Column(children: [
            for (final log in workoutLogs.take(2))
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${log.date} · ${log.title}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(log.items.take(2).map((i) => '${i.name} ${i.weight} ${i.sets}×${i.reps}').join('\n')),
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
    return TabBody(children: [
      const H1('운동일지'),
      const Muted('담당 선생님이 작성한 내 일지예요. 나만 볼 수 있어요.'),
      for (var i = 0; i < workoutLogs.length; i++)
        AppCard(
          onTap: () {
            demo.firstLogSeen = true;
            Navigator.pushNamed(context, Routes.logDetail, arguments: i);
          },
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${workoutLogs[i].date} · ${workoutLogs[i].title}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Muted(
              '${workoutLogs[i].items.length}종목'
              '${workoutLogs[i].videos.isEmpty ? '' : ' · 영상 ${workoutLogs[i].videos.length}개'}'
              ' · ${workoutLogs[i].comment}',
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
    final index = (ModalRoute.of(context)?.settings.arguments as int?) ?? 0;
    final log = workoutLogs[index];
    return AppPage(title: '${log.date} · ${log.title}', children: [
      for (final item in log.items)
        LineRow(
          onTap: () => Navigator.pushNamed(context, Routes.exerciseDetail, arguments: item.name),
          left: Row(children: [
            ExerciseThumb(item.name),
            const SizedBox(width: 10),
            Expanded(child: Text(item.name)),
          ]),
          right: Muted('${item.weight}, ${item.reps} × ${item.sets}세트', bottom: 0),
        ),
      if (log.videos.isNotEmpty) ...[
        const H2('운동 영상'),
        for (var j = 0; j < log.videos.length; j++) ...[
          InkWell(
            onTap: () => toast(context, '영상 재생 (데모)'),
            child: Container(
              height: 130,
              decoration: BoxDecoration(color: AppColors.text, borderRadius: BorderRadius.circular(14)),
              child: Stack(children: [
                const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 44)),
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: Text(log.videos[j].name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(child: Muted('서버 보관 만료까지 ${log.videos[j].daysLeft}일', bottom: 0)),
              if (demo.savedVideos.contains('$index-$j'))
                const Muted('내 폰에 저장됨', bottom: 0)
              else
                OutlinedButton(
                  onPressed: () {
                    demo.update(() => demo.savedVideos.add('$index-$j'));
                    toast(context, '영상을 내 폰에 저장했어요');
                  },
                  child: const Text('내 폰에 저장'),
                ),
            ]),
          ),
        ],
      ],
      // 다른 강조 카드와 같은 모양 (디자인 리뷰 10/28 #6)
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: AppCard(
          accent: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('선생님 코멘트', bottom: 4),
          Text(log.comment),
          const SizedBox(height: 8),
          Chip(
            label: Text(log.stamp),
            backgroundColor: AppColors.primarySoft,
            labelStyle: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
          ),
        ]),
        ),
      ),
    ]);
  }
}

/// S18 회원 관리 (선생님)
class MemberManageTab extends StatefulWidget {
  const MemberManageTab({super.key});

  @override
  State<MemberManageTab> createState() => _MemberManageTabState();
}

class _MemberManageTabState extends State<MemberManageTab> {
  String member = members.first;
  final missionController = TextEditingController();

  @override
  void dispose() {
    missionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBody(children: [
      const H1('회원 관리'),
      AppButton('초대 코드 만들기',
          top: 0,
          onPressed: () => demo.update(() => demo.inviteCode = '${100000 + Random().nextInt(900000)}')),
      const SizedBox(height: 12),
      if (demo.inviteCode != null)
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Muted('회원님께 알려 주세요 (1회용 · 7일 유효)', bottom: 2),
            BigNumber(demo.inviteCode!),
          ]),
        ),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('이번 주 미션', bottom: 6),
          DropdownButtonFormField<String>(
            initialValue: member,
            items: [for (final m in members) DropdownMenuItem(value: m, child: Text(m))],
            onChanged: (v) => setState(() => member = v ?? member),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: missionController,
            decoration: const InputDecoration(hintText: '예: 이번 주 운동 3회 + 단백질 챙기기'),
          ),
          AppButton('미션 보내기', kind: ButtonKind.soft, onPressed: () {
            final text = missionController.text.trim();
            demo.update(() => demo.missions[member] = text.isEmpty ? '이번 주 운동 3회 + 단백질 챙기기' : text);
            missionController.clear();
            toast(context, '$member 회원님께 이번 주 미션을 보냈어요');
          }),
        ]),
      ),
      for (final m in members)
        LineRow(
          left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Muted('마지막 일지 10월 6일', bottom: 0),
          ]),
          right: FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
            onPressed: () => Navigator.pushNamed(context, Routes.logWrite, arguments: m),
            child: const Text('일지 작성'),
          ),
        ),
    ]);
  }
}

/// S19 일지 작성 (선생님)
class LogWriteScreen extends StatefulWidget {
  const LogWriteScreen({super.key});

  @override
  State<LogWriteScreen> createState() => _LogWriteScreenState();
}

class _LogWriteScreenState extends State<LogWriteScreen> {
  String? member;
  String exercise = exerciseNames.first;
  bool customExercise = false;
  String stamp = stamps.first;
  final List<String> videos = [];

  void _addVideo(String source) {
    if (videos.length >= 5) {
      toast(context, '영상은 일지당 최대 5개까지 올릴 수 있어요');
      return;
    }
    setState(() => videos.add('${customExercise ? '직접 입력' : exercise} 영상 · 0:1${videos.length + 1}'));
    toast(context, source == '촬영' ? '15초가 되면 촬영이 자동으로 끝나요' : '15초보다 긴 영상은 앞 15초만 올라가요');
  }

  @override
  Widget build(BuildContext context) {
    member ??= (ModalRoute.of(context)?.settings.arguments as String?) ?? members.first;
    return AppPage(title: '일지 작성', children: [
      DropdownButtonFormField<String>(
        initialValue: member,
        decoration: const InputDecoration(labelText: '회원'),
        items: [for (final m in members) DropdownMenuItem(value: m, child: Text(m))],
        onChanged: (v) => setState(() => member = v),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: customExercise
              ? const TextField(decoration: InputDecoration(labelText: '종목 이름', hintText: '예: TRX 로우'))
              : InkWell(
                  borderRadius: BorderRadius.circular(10),
                  // 운동 추가하기(S21)에서 1개를 고른다
                  onTap: () async {
                    final picked = await Navigator.pushNamed(context, Routes.exercisePick, arguments: 1);
                    if (picked is List<String> && picked.isNotEmpty) setState(() => exercise = picked.first);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: '종목'),
                    child: Row(children: [
                      ExerciseThumb(exercise, size: 32),
                      const SizedBox(width: 10),
                      Expanded(child: Text(exercise)),
                      const Icon(Icons.chevron_right, color: AppColors.textSub),
                    ]),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('직접 입력'),
          selected: customExercise,
          onSelected: (v) => setState(() => customExercise = v),
        ),
      ]),
      const SizedBox(height: 12),
      const Row(children: [
        Expanded(child: TextField(decoration: InputDecoration(labelText: '무게', hintText: '60kg'))),
        SizedBox(width: 8),
        Expanded(child: TextField(decoration: InputDecoration(labelText: '횟수', hintText: '8'))),
        SizedBox(width: 8),
        Expanded(child: TextField(decoration: InputDecoration(labelText: '세트', hintText: '4'))),
      ]),
      const SizedBox(height: 10),
      Muted('운동 영상 ${videos.length}/5 (영상당 15초 이내 · 회원님 촬영 동의 후 올려 주세요 · 회원님 본인에게만 보여요)'),
      for (var i = 0; i < videos.length; i++)
        LineRow(
          left: Text(videos[i]),
          right: TextButton(onPressed: () => setState(() => videos.removeAt(i)), child: const Text('삭제')),
        ),
      Row(children: [
        Expanded(child: AppButton('촬영하기', kind: ButtonKind.soft, onPressed: () => _addVideo('촬영'))),
        const SizedBox(width: 8),
        Expanded(child: AppButton('앨범에서 선택', kind: ButtonKind.soft, onPressed: () => _addVideo('앨범'))),
      ]),
      const SizedBox(height: 12),
      const TextField(maxLines: 3, decoration: InputDecoration(labelText: '코멘트', hintText: '자세, 다음 목표 등')),
      const SizedBox(height: 12),
      const Muted('응원 스탬프 (저장하면 그날 출석 도장도 찍혀요)', bottom: 0),
      Seg(options: stamps, value: stamp, onChanged: (v) => setState(() => stamp = v)),
      AppButton('저장하고 알림 보내기', onPressed: () {
        toast(context, '$member 회원님께 일지${videos.isEmpty ? '' : '와 영상 ${videos.length}개'}를 저장하고 알림을 보냈어요 (출석 도장 완료)');
        Navigator.pop(context);
      }),
    ]);
  }
}
