import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/exercise_lookup.dart';
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
      const Muted('담당 선생님이 작성한 내 일지예요. 나만 볼 수 있어요.'),
      if (logs.isEmpty) const AppCard(child: Text('아직 받은 일지가 없어요. 수업이 끝나면 선생님이 여기 올려 줘요.')),
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
              Expanded(child: Text('${log.date} · ${log.title}', style: AppText.bodyStrong)),
              // 안 본 일지를 구분한다 (리뷰 11/04 #7)
              if (demo.unseenLogs.contains(log))
                Text('새 일지', style: AppText.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
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
      // 다른 강조 카드와 같은 모양 (디자인 리뷰 10/28 #6)
      Padding(
        padding: const EdgeInsets.only(top: 10),
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

/// 회원 한 줄: 마지막 일지 날짜와 일지 작성 버튼. 회원 관리와 선생님 홈이 같이 쓴다
class MemberLogRow extends StatelessWidget {
  const MemberLogRow(this.member, {super.key});
  final String member;

  @override
  Widget build(BuildContext context) => LineRow(
        left: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member, style: AppText.bodyStrong),
          Muted(demo.lastLogOf(member) == null ? '아직 쓴 일지가 없어요' : '마지막 일지 ${demo.lastLogOf(member)}', bottom: 0),
          if (hasLogDraft(member)) const Muted('임시 저장한 일지가 있어요', bottom: 0),
        ]),
        right: Row(mainAxisSize: MainAxisSize.min, children: [
          FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => Navigator.pushNamed(context, Routes.logWrite, arguments: member),
            child: Text(hasLogDraft(member) ? '이어 쓰기' : '일지 작성'),
          ),
          IconButton(
            tooltip: '$member 회원 더 보기',
            icon: const Icon(Icons.more_vert),
            onPressed: () => showMemberSheet(context, member),
          ),
        ]),
      );
}

/// 회원 더 보기: 보낸 일지와 연결 끊기
void showMemberSheet(BuildContext context, String member) {
  showAppSheet<void>(
    context,
    builder: (sheet) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      SheetTitle('$member 회원'),
      LineRow(
        left: const Text('연결 끊기', style: TextStyle(color: AppColors.warningText)),
        onTap: () async {
          // 회원과 선생님 모두 끊을 수 있고 상대에게 알린다 (결정 d1104-2)
          final ok = await confirmDialog(sheet,
              title: '$member 회원과 연결을 끊을까요?',
              body: '더 이상 이 회원의 일지를 볼 수 없어요. 회원님께 알림이 가요.',
              keepLabel: '그대로 두기',
              okLabel: '연결 끊기',
              danger: true);
          if (!ok || !sheet.mounted) return;
          demo.update(() {
            demo.removedMembers.add(member);
            demo.missions.remove(member);
          });
          Navigator.pop(sheet);
          if (context.mounted) toast(context, '$member 회원과 연결을 끊고 알렸어요');
        },
      ),
    ]),
  );
}

/// S18 회원 관리 (선생님)
class MemberManageTab extends StatefulWidget {
  const MemberManageTab({super.key});

  @override
  State<MemberManageTab> createState() => _MemberManageTabState();
}

class _MemberManageTabState extends State<MemberManageTab> {
  String? selectedMember;

  /// 미션 받을 회원. 연결을 끊은 회원은 고를 수 없다
  String? get member {
    final active = demo.activeMembers;
    if (active.contains(selectedMember)) return selectedMember;
    return active.isEmpty ? null : active.first;
  }
  final missionController = TextEditingController();
  final inviteMemoController = TextEditingController();

  @override
  void dispose() {
    missionController.dispose();
    inviteMemoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final member = this.member;
    return TabBody(children: [
      const H1('회원 관리'),
      // 수업 끝나고 가장 자주 쓰는 회원 목록을 맨 위로, 가끔 쓰는 초대 코드는 맨 아래로 (리뷰 11/04 #3)
      if (demo.activeMembers.isEmpty) const Muted('연결된 회원이 없어요. 아래에서 초대 코드를 만들어 보세요.'),
      for (final m in demo.activeMembers) MemberLogRow(m),
      const SizedBox(height: AppSpace.l),
      if (member != null) AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('이번 주 미션', bottom: 6),
          DropdownButtonFormField<String>(
            key: ValueKey(member),
            initialValue: member,
            items: [for (final m in demo.activeMembers) DropdownMenuItem(value: m, child: Text(m))],
            onChanged: (v) => setState(() => selectedMember = v),
          ),
          // 고른 회원에게 지금 보낸 미션을 보여 준다 (리뷰 11/02 #4)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Muted(demo.missions[member] == null ? '아직 보낸 미션이 없어요' : '지금 미션: ${demo.missions[member]}', bottom: 0),
          ),
          const SizedBox(height: AppSpace.s),
          TextField(
            controller: missionController,
            decoration: const InputDecoration(hintText: '예: 이번 주 운동 3회 + 단백질 챙기기'),
          ),
          // 다른 회원에게 보내지 않게 버튼에 이름을 쓰고, 있던 미션은 말없이 덮어쓰지 않는다 (리뷰 11/04 #2)
          AppButton(demo.missions[member] == null ? '$member 회원님께 보내기' : '$member 회원님 미션 바꾸기', kind: ButtonKind.soft,
              onPressed: () async {
            final text = missionController.text.trim();
            // 빈칸이면 회색 예시 문구가 그대로 보내지지 않게 막는다
            if (text.isEmpty) {
              toast(context, '미션 내용을 적어 주세요');
              return;
            }
            final old = demo.missions[member];
            if (old != null) {
              final ok = await confirmDialog(context,
                  title: '$member 회원님 미션을 바꿀까요?',
                  body: '지금 미션: $old',
                  keepLabel: '그대로 두기',
                  okLabel: '바꾸기');
              if (!ok || !context.mounted) return;
            }
            demo.update(() => demo.missions[member] = text);
            missionController.clear();
            toast(context, '$member 회원님께 이번 주 미션을 보냈어요');
          }),
        ]),
      ),
      const SizedBox(height: AppSpace.s),
      // 회원 이름(또는 메모)을 먼저 적고 만든다. 어느 코드가 누구 것인지 헷갈리지 않게 (결정 d1102-3)
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FieldLabel('새 회원 초대', sub: '회원 이름이나 메모를 먼저 적어 주세요'),
          const SizedBox(height: AppSpace.s),
          TextField(
            controller: inviteMemoController,
            decoration: const InputDecoration(hintText: '예: 김지아 회원님'),
          ),
          AppButton('초대 코드 만들기', kind: ButtonKind.soft, onPressed: () {
            final memo = inviteMemoController.text.trim();
            if (memo.isEmpty) {
              toast(context, '회원 이름이나 메모를 적어 주세요');
              return;
            }
            demo.update(() => demo.inviteCodes.insert(0, InviteCode(memo, '${100000 + Random().nextInt(900000)}')));
            inviteMemoController.clear();
          }),
        ]),
      ),
      for (final c in demo.inviteCodes)
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.memo, style: AppText.bodyStrong),
            Muted('1회용 · ${c.daysLeft}일 남음', bottom: 2),
            Row(children: [
              Expanded(child: BigNumber(c.code)),
              // 손으로 옮겨 적지 않게 복사 버튼
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('복사'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: c.code));
                  if (context.mounted) toast(context, '초대 코드를 복사했어요');
                },
              ),
            ]),
          ]),
        ),
    ]);
  }
}

/// 회원에게 아직 보내지 않은 일지 (결정 d1102-2). 목업이라 메모리에만 둔다
class _LogDraft {
  const _LogDraft(this.date, this.rows, this.stamp, this.comment, this.videos);
  final DateTime date;
  final List<_LogRow> rows;
  final String stamp;
  final String comment;
  final List<String> videos;
}

final Map<String, _LogDraft> _logDrafts = {};
bool hasLogDraft(String member) => _logDrafts.containsKey(member);
void clearLogDrafts() => _logDrafts.clear();

/// 일지의 종목 한 줄 (결정 dd1101-logwrite: '+ 종목 추가'로 줄을 늘린다)
class _LogRow {
  /// 고른 종목. 미리 채워 두면 다른 운동을 그대로 저장하기 쉬워서 비워 둔다 (리뷰 11/06 #1)
  String? exercise;
  bool custom = false;

  // 적은 값을 상태에 남긴다 (리뷰 11/02 #2). 직접 입력한 종목 이름은 칩을 껐다 켜도 남는다 (#7)
  String customName = '';
  String kg = '';
  String reps = '';
  String sets = '';

  String get name => custom ? customName.trim() : (exercise ?? '');
  bool get hasInput => exercise != null || [customName, kg, reps, sets].any((v) => v.trim().isNotEmpty);
}

/// S19 일지 작성 (선생님)
class LogWriteScreen extends StatefulWidget {
  const LogWriteScreen({super.key});

  @override
  State<LogWriteScreen> createState() => _LogWriteScreenState();
}

class _LogWriteScreenState extends State<LogWriteScreen> {
  String? member;

  /// 수업 날짜. 다음 날 몰아서 써도 그날 일지·출석 도장이 되게 고른다 (리뷰 11/04 #4)
  DateTime date = demoTodayDate;
  final List<_LogRow> rows = [_LogRow()];
  String stamp = stamps.first;
  final List<String> videos = [];
  String comment = '';

  /// 적은 게 있는지 (뒤로 갈 때 버릴지 묻는 기준)
  bool get dirty =>
      rows.length > 1 || rows.any((r) => r.hasInput) || comment.trim().isNotEmpty || videos.isNotEmpty || date != demoTodayDate;

  String get dateLabel => '${date.month}월 ${date.day}일';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: demoTodayDate.subtract(const Duration(days: 30)),
      lastDate: demoTodayDate,
      helpText: '수업 날짜',
    );
    if (picked != null) setState(() => date = picked);
  }

  /// 임시 저장: 회원에게 알림이 가지 않는다 (결정 d1102-2)
  void _saveDraft() {
    if (!dirty) {
      toast(context, '적은 내용이 없어요');
      return;
    }
    demo.update(() => _logDrafts[member!] = _LogDraft(date, [...rows], stamp, comment, [...videos]));
    toast(context, '임시 저장했어요. 회원님께는 아직 가지 않았어요');
    Navigator.pop(context);
  }

  void _save() {
    // 줄이 여러 개면 몇 번째 줄인지 함께 알린다
    for (var i = 0; i < rows.length; i++) {
      final where = rows.length > 1 ? '${i + 1}번째 줄의 ' : '';
      if (rows[i].name.isEmpty) {
        toast(context, rows[i].custom ? '$where종목 이름을 적어 주세요' : '$where종목을 골라 주세요');
        return;
      }
      // 횟수·세트는 1 이상의 정수만. 비었거나 0이면 말없이 저장하지 않는다 (리뷰 11/06 #2)
      final reps = int.tryParse(rows[i].reps.trim());
      if (reps == null || reps < 1) {
        toast(context, rows[i].reps.trim().isEmpty ? '$where횟수를 적어 주세요' : '$where횟수는 1 이상으로 적어 주세요');
        return;
      }
      final sets = int.tryParse(rows[i].sets.trim());
      if (sets == null || sets < 1) {
        toast(context, rows[i].sets.trim().isEmpty ? '$where세트를 적어 주세요' : '$where세트는 1 이상으로 적어 주세요');
        return;
      }
    }
    // 저장한 일지를 남겨서 회원 관리의 '마지막 일지'와 회원의 일지 목록에 바로 보이게 한다 (리뷰 11/04 #1)
    final log = WorkoutLog(
      dateLabel,
      {for (final r in rows) exerciseByName(r.name)?.part ?? '수업'}.join(' · '),
      [
        for (final r in rows)
          LogItem(r.name, r.kg.trim().isEmpty ? '체중' : '${r.kg.trim()}kg', '${int.parse(r.reps.trim())}개', int.parse(r.sets.trim())),
      ],
      [for (final v in videos) LogVideo(v, 30)], // 기획서 6번 초안: 올린 날부터 30일
      comment.trim(),
      stamp,
    );
    demo.update(() {
      _logDrafts.remove(member);
      (demo.sentLogs[member!] ??= []).add(log);
      demo.unseenLogs.add(log);
    });
    toast(context, '$member 회원님께 일지${videos.isEmpty ? '' : '와 영상 ${videos.length}개'}를 보내고 알림을 보냈어요 ($dateLabel 출석 도장 완료)');
    Navigator.pop(context);
  }

  void _addVideo(String source) {
    if (videos.length >= 5) {
      toast(context, '영상은 일지당 최대 5개까지 올릴 수 있어요');
      return;
    }
    final name = rows.last.name;
    setState(() => videos.add('${name.isEmpty ? '직접 입력' : name} 영상 · 0:1${videos.length + 1}'));
    toast(context, source == '촬영' ? '15초가 되면 촬영이 자동으로 끝나요' : '15초보다 긴 영상은 앞 15초만 올라가요');
  }

  /// 줄을 빼고 되돌릴 수 있게 한다
  void _removeRow(int i) {
    final removed = rows[i];
    setState(() => rows.removeAt(i));
    toast(context, '${i + 1}번째 종목을 뺐어요', actionLabel: '되돌리기', onAction: () {
      if (mounted) setState(() => rows.insert(i.clamp(0, rows.length), removed));
    });
  }

  Widget _rowEditor(int i) {
    final r = rows[i];
    return AppCard(
      key: ObjectKey(r),
      child: Column(children: [
        if (rows.length > 1)
          Row(children: [
            Expanded(child: Text('종목 ${i + 1}', style: AppText.bodyStrong)),
            TextButton(onPressed: () => _removeRow(i), child: const Text('빼기', style: TextStyle(color: AppColors.warningText))),
          ]),
        // 카드 안은 좁아서 글자가 잘리지 않게 종목 칸과 '직접 입력'을 두 줄로
        r.custom
                ? TextFormField(
                    initialValue: r.customName,
                    decoration: const InputDecoration(labelText: '종목 이름', hintText: '예: TRX 로우'),
                    onChanged: (v) => setState(() => r.customName = v),
                  )
                : InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    // 운동 추가하기(S21)에서 1개를 고른다
                    onTap: () async {
                      final picked = await Navigator.pushNamed(context, Routes.exercisePick, arguments: 1);
                      if (picked is List<String> && picked.isNotEmpty) setState(() => r.exercise = picked.first);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: '종목'),
                      child: Row(children: [
                        if (r.exercise != null) ...[
                          ExerciseThumb(r.exercise!, size: 32),
                          const SizedBox(width: AppSpace.sPlus),
                        ],
                        Expanded(
                          child: WordText(r.exercise ?? '종목을 골라 주세요',
                              style: r.exercise == null ? const TextStyle(color: AppColors.textSub) : null),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textSub),
                      ]),
                    ),
                  ),
        Align(
          alignment: Alignment.centerRight,
          child: SelectChip('직접 입력', selected: r.custom, onSelected: (v) => setState(() => r.custom = v)),
        ),
        const SizedBox(height: AppSpace.m),
        // 휴대폰에서 숫자 자판이 뜨게 공용 숫자 칸으로 (디자인 리뷰 11/01 #2)
        Row(children: [
          Expanded(child: NumField(label: '무게', suffix: 'kg', hint: '60', value: r.kg, onChanged: (v) => setState(() => r.kg = v))),
          const SizedBox(width: 8),
          Expanded(child: NumField(label: '횟수', hint: '8', decimal: false, value: r.reps, onChanged: (v) => setState(() => r.reps = v))),
          const SizedBox(width: 8),
          Expanded(child: NumField(label: '세트', hint: '4', decimal: false, value: r.sets, onChanged: (v) => setState(() => r.sets = v))),
        ]),
        const Align(
          alignment: Alignment.centerLeft,
          child: Muted('맨몸이면 무게 칸을 비워 두세요', top: AppSpace.xs, bottom: 0),
        ),
      ]),
    );
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
    if (member == null) {
      member = (ModalRoute.of(context)?.settings.arguments as String?) ?? members.first;
      // 임시 저장한 일지가 있으면 이어서 쓴다
      final draft = _logDrafts[member];
      if (draft != null) {
        date = draft.date;
        rows
          ..clear()
          ..addAll(draft.rows);
        stamp = draft.stamp;
        comment = draft.comment;
        videos
          ..clear()
          ..addAll(draft.videos);
      }
    }
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
        items: [for (final m in {...demo.activeMembers, member!}) DropdownMenuItem(value: m, child: Text(m))],
        onChanged: (v) => setState(() => member = v),
      ),
      const SizedBox(height: AppSpace.m),
      InkWell(
        borderRadius: BorderRadius.circular(AppRadius.small),
        onTap: _pickDate,
        child: InputDecorator(
          decoration: const InputDecoration(labelText: '수업 날짜'),
          child: Row(children: [
            Expanded(child: Text('$dateLabel (${dayLabels[date.weekday - 1]})${date == demoTodayDate ? ' · 오늘' : ''}')),
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSub),
          ]),
        ),
      ),
      const Muted('이 날짜에 출석 도장이 찍혀요', top: AppSpace.xs, bottom: AppSpace.m),
      for (var i = 0; i < rows.length; i++) _rowEditor(i),
      AppButton('+ 종목 추가', kind: ButtonKind.soft, top: 0, onPressed: () => setState(() => rows.add(_LogRow()))),
      const SizedBox(height: AppSpace.sPlus),
      // 촬영 동의 안내가 묻히지 않게 제목·규칙·동의를 나눈다. 문구는 그대로 (디자인 리뷰 11/01 #4)
      H2('운동 영상 ${videos.length}/5', top: 0),
      const Text('회원님 촬영 동의 후 올려 주세요', style: AppText.bodyStrong),
      const Muted('영상당 15초 이내 · 회원님 본인에게만 보여요'),
      for (var i = 0; i < videos.length; i++)
        LineRow(
          left: Text(videos[i]),
          right: TextButton(onPressed: () => _removeVideo(i), child: const Text('빼기', style: TextStyle(color: AppColors.warningText))),
        ),
      Row(children: [
        Expanded(child: AppButton('촬영하기', kind: ButtonKind.soft, onPressed: () => _addVideo('촬영'))),
        const SizedBox(width: 8),
        Expanded(child: AppButton('앨범에서 선택', kind: ButtonKind.soft, onPressed: () => _addVideo('앨범'))),
      ]),
      const SizedBox(height: AppSpace.m),
      TextFormField(
        initialValue: comment,
        maxLines: 3,
        decoration: const InputDecoration(labelText: '코멘트', hintText: '자세, 다음 목표 등', alignLabelWithHint: true),
        onChanged: (v) => setState(() => comment = v),
      ),
      const SizedBox(height: AppSpace.m),
      const FieldLabel('응원 스탬프'),
      Seg(options: stamps, value: stamp, onChanged: (v) => setState(() => stamp = v)),
      // 저장과 보내기를 나눠, 다 쓰기 전에 회원에게 알림이 가지 않게 (결정 d1102-2)
      Row(children: [
        Expanded(child: AppButton('임시 저장', kind: ButtonKind.soft, onPressed: _saveDraft)),
        const SizedBox(width: AppSpace.s),
        Expanded(child: AppButton('회원님께 보내기', onPressed: _save)),
      ]),
    ]),
    );
  }
}
