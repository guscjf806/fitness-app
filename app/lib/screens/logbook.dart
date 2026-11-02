import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return TabBody(children: [
      const H1('운동일지'),
      const Muted('담당 선생님이 작성한 내 일지예요. 나만 볼 수 있어요.'),
      if (workoutLogs.isEmpty) const AppCard(child: Text('아직 받은 일지가 없어요. 수업이 끝나면 선생님이 여기 올려 줘요.')),
      for (var i = 0; i < workoutLogs.length; i++)
        AppCard(
          onTap: () {
            demo.firstLogSeen = true;
            Navigator.pushNamed(context, Routes.logDetail, arguments: i);
          },
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${workoutLogs[i].date} · ${workoutLogs[i].title}', style: AppText.bodyStrong),
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
                child: Text('${log.videos[j].daysLeft}일 뒤 사라져요. 남기려면 내 폰에 저장하세요',
                    style: AppText.caption.copyWith(color: log.videos[j].daysLeft <= 3 ? AppColors.warning : AppColors.textSub)),
              ),
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
      // 코드가 있으면 다시 누를 때 새 코드로 바뀐다는 걸 이름으로 알린다 (리뷰 11/02 #5)
      AppButton(demo.inviteCode == null ? '초대 코드 만들기' : '새 코드 만들기',
          top: 0,
          onPressed: () => demo.update(() => demo.inviteCode = '${100000 + Random().nextInt(900000)}')),
      const SizedBox(height: 12),
      if (demo.inviteCode != null)
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Muted('회원님께 알려 주세요 (1회용 · 7일 유효)', bottom: 2),
            Row(children: [
              Expanded(child: BigNumber(demo.inviteCode!)),
              // 손으로 옮겨 적지 않게 복사 버튼
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('복사'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: demo.inviteCode!));
                  if (context.mounted) toast(context, '초대 코드를 복사했어요');
                },
              ),
            ]),
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
          // 고른 회원에게 지금 보낸 미션을 보여 준다 (리뷰 11/02 #4)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Muted(demo.missions[member] == null ? '아직 보낸 미션이 없어요' : '지금 미션: ${demo.missions[member]}', bottom: 0),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: missionController,
            decoration: const InputDecoration(hintText: '예: 이번 주 운동 3회 + 단백질 챙기기'),
          ),
          AppButton('미션 보내기', kind: ButtonKind.soft, onPressed: () {
            final text = missionController.text.trim();
            // 빈칸이면 회색 예시 문구가 그대로 보내지지 않게 막는다
            if (text.isEmpty) {
              toast(context, '미션 내용을 적어 주세요');
              return;
            }
            demo.update(() => demo.missions[member] = text);
            missionController.clear();
            toast(context, '$member 회원님께 이번 주 미션을 보냈어요');
          }),
        ]),
      ),
      for (final m in members)
        LineRow(
          left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m, style: AppText.bodyStrong),
            Muted(lastLogDates[m] == null ? '아직 쓴 일지가 없어요' : '마지막 일지 ${lastLogDates[m]}', bottom: 0),
          ]),
          right: FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
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

  // 적은 값을 상태에 남긴다 (리뷰 11/02 #2). 직접 입력한 종목 이름은 칩을 껐다 켜도 남는다 (#7)
  String customName = '';
  String kg = '';
  String reps = '';
  String sets = '';
  String comment = '';

  String get exerciseName => customExercise ? customName.trim() : exercise;

  /// 적은 게 있는지 (뒤로 갈 때 버릴지 묻는 기준)
  bool get dirty => [customName, kg, reps, sets, comment].any((v) => v.trim().isNotEmpty) || videos.isNotEmpty;

  void _save() {
    if (exerciseName.isEmpty) {
      toast(context, '종목 이름을 적어 주세요');
      return;
    }
    if (reps.trim().isEmpty) {
      toast(context, '횟수를 적어 주세요');
      return;
    }
    toast(context, '$member 회원님께 일지${videos.isEmpty ? '' : '와 영상 ${videos.length}개'}를 저장하고 알림을 보냈어요 (출석 도장 완료)');
    Navigator.pop(context);
  }

  void _addVideo(String source) {
    if (videos.length >= 5) {
      toast(context, '영상은 일지당 최대 5개까지 올릴 수 있어요');
      return;
    }
    setState(() => videos.add('${exerciseName.isEmpty ? '직접 입력' : exerciseName} 영상 · 0:1${videos.length + 1}'));
    toast(context, source == '촬영' ? '15초가 되면 촬영이 자동으로 끝나요' : '15초보다 긴 영상은 앞 15초만 올라가요');
  }

  /// 영상을 빼고, 지운 자리에 되돌릴 수 있게 한다 (디자인 리뷰 11/01 #3)
  void _removeVideo(int i) {
    final removed = videos[i];
    setState(() => videos.removeAt(i));
    toast(context, '영상을 뺐어요', actionLabel: '되돌리기', onAction: () {
      if (mounted) setState(() => videos.insert(i.clamp(0, videos.length), removed));
    });
  }

  @override
  Widget build(BuildContext context) {
    member ??= (ModalRoute.of(context)?.settings.arguments as String?) ?? members.first;
    // 수업 뒤 길게 적은 일지가 뒤로 가기로 사라지지 않게 먼저 묻는다 (리뷰 11/02 #3)
    return DiscardGuard(
      dirty: dirty,
      title: '작성 중인 일지를 버릴까요?',
      body: '나가면 적은 내용과 영상이 사라져요.',
      keepLabel: '계속 쓰기',
      okLabel: '버리고 나가기',
      child: AppPage(title: '일지 작성', children: [
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
              ? TextFormField(
                  initialValue: customName,
                  decoration: const InputDecoration(labelText: '종목 이름', hintText: '예: TRX 로우'),
                  onChanged: (v) => setState(() => customName = v),
                )
              : InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.small),
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
      // 휴대폰에서 숫자 자판이 뜨게 공용 숫자 칸으로 (디자인 리뷰 11/01 #2)
      Row(children: [
        Expanded(child: NumField(label: '무게 (kg)', hint: '60', value: kg, onChanged: (v) => setState(() => kg = v))),
        const SizedBox(width: 8),
        Expanded(child: NumField(label: '횟수', hint: '8', value: reps, onChanged: (v) => setState(() => reps = v))),
        const SizedBox(width: 8),
        Expanded(child: NumField(label: '세트', hint: '4', value: sets, onChanged: (v) => setState(() => sets = v))),
      ]),
      const SizedBox(height: 10),
      // 촬영 동의 안내가 묻히지 않게 제목·규칙·동의를 나눈다. 문구는 그대로 (디자인 리뷰 11/01 #4)
      H2('운동 영상 ${videos.length}/5', top: 0),
      const Text('회원님 촬영 동의 후 올려 주세요', style: AppText.bodyStrong),
      const Muted('영상당 15초 이내 · 회원님 본인에게만 보여요'),
      for (var i = 0; i < videos.length; i++)
        LineRow(
          left: Text(videos[i]),
          right: TextButton(onPressed: () => _removeVideo(i), child: const Text('빼기', style: TextStyle(color: AppColors.warning))),
        ),
      Row(children: [
        Expanded(child: AppButton('촬영하기', kind: ButtonKind.soft, onPressed: () => _addVideo('촬영'))),
        const SizedBox(width: 8),
        Expanded(child: AppButton('앨범에서 선택', kind: ButtonKind.soft, onPressed: () => _addVideo('앨범'))),
      ]),
      const SizedBox(height: 12),
      TextFormField(
        initialValue: comment,
        maxLines: 3,
        decoration: const InputDecoration(labelText: '코멘트', hintText: '자세, 다음 목표 등'),
        onChanged: (v) => setState(() => comment = v),
      ),
      const SizedBox(height: 12),
      const Muted('응원 스탬프 (저장하면 그날 출석 도장도 찍혀요)', bottom: 0),
      Seg(options: stamps, value: stamp, onChanged: (v) => setState(() => stamp = v)),
      AppButton('저장하고 알림 보내기', onPressed: _save),
    ]),
    );
  }
}
