import 'package:flutter/material.dart';

import '../../data/exercise_lookup.dart';
import '../../data/mock_data.dart';
import '../../routes.dart';
import '../../state/demo_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// 보낸 일지를 고칠 때 일지 작성 화면에 넘기는 값
class LogEditArgs {
  const LogEditArgs(this.member, this.log);
  final String member;
  final WorkoutLog log;
}

/// 회원에게 아직 보내지 않은 일지 (결정 d1102-2). 목업이라 메모리에만 둔다
class _LogDraft {
  const _LogDraft(this.date, this.rows, this.stamp, this.comment);
  final DateTime date;
  final List<_LogRow> rows;
  final String stamp;
  final String comment;
}

final Map<String, _LogDraft> _logDrafts = {};
bool hasLogDraft(String member) => _logDrafts.containsKey(member);
void clearLogDraft(String member) => _logDrafts.remove(member);
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

  /// 보낸 일지의 한 줄에서 만든다 (지난 수업 불러오기, 일지 고치기)
  _LogRow.fromItem(LogItem item) {
    if (exerciseByName(item.name) != null) {
      exercise = item.name;
    } else {
      custom = true;
      customName = item.name;
    }
    kg = item.weight == '체중' ? '' : item.weight.replaceAll('kg', '');
    reps = item.reps.replaceAll(RegExp(r'[^0-9]'), '');
    sets = '${item.sets}';
  }
  _LogRow();

  /// 임시 저장과 화면이 같은 줄을 쓰지 않게 복사한다 (리뷰 11/07 #4)
  _LogRow copy() => _LogRow()
    ..exercise = exercise
    ..custom = custom
    ..customName = customName
    ..kg = kg
    ..reps = reps
    ..sets = sets
    ..videos.addAll(videos);

  /// 바뀌었는지 비교할 값
  String get fingerprint => [exercise, custom, customName, kg, reps, sets, ...videos].join('|');

  /// 종목을 바꾸면 영상 이름도 따라 바뀐다 (리뷰 11/07 #7)
  String videoLabel(String v) {
    final at = v.indexOf(' 영상');
    return at < 0 ? v : '$name${v.substring(at)}';
  }

  /// 이 종목에 붙인 영상 (결정 d1106-1)
  final List<String> videos = [];

  String get name => custom ? customName.trim() : (exercise ?? '');

  /// 플랭크처럼 시간으로 하는 운동이면 칸 이름과 단위가 바뀐다 (결정 d1106-2)
  bool get isHold => !custom && exercise != null && exerciseByName(exercise!)?.kind == 'hold';
  bool get hasInput => exercise != null || videos.isNotEmpty || [customName, kg, reps, sets].any((v) => v.trim().isNotEmpty);
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
  String comment = '';

  /// 보낸 일지를 고치는 중이면 그 일지 (결정 d1104-3)
  WorkoutLog? editing;

  /// 내용을 통째로 바꿀 때 코멘트 칸을 새로 그리게 올린다
  int formVersion = 0;

  /// 빈 일지로 새로 시작한다 (리뷰 11/08 #2)
  void _startBlank() {
    date = demoTodayDate;
    rows
      ..clear()
      ..add(_LogRow());
    stamp = stamps.first;
    comment = '';
    formVersion++;
    baseFingerprint = fingerprint;
  }

  int get videoCount => rows.fold(0, (n, r) => n + r.videos.length);

  /// 적은 게 있는지 (뒤로 갈 때 버릴지 묻는 기준)
  /// 처음 열었을 때(또는 임시 저장을 불러왔을 때)에서 바뀌었는지
  String get fingerprint => [date, stamp, comment.trim(), ...rows.map((r) => r.fingerprint)].join('//');
  String? baseFingerprint;
  bool get dirty => baseFingerprint != null && fingerprint != baseFingerprint;
  bool get hasOwnDraft => member != null && hasLogDraft(member!);

  /// 적은 내용이 다른 회원 일지가 되지 않게 묻고, 그 회원의 임시 저장이 있으면 연다 (리뷰 11/07 #5)
  Future<void> _changeMember(String? next) async {
    if (next == null || next == member) return;
    if (dirty) {
      final hasDraft = hasLogDraft(next);
      final ok = await confirmDialog(context,
          title: '$next 회원 일지로 바꿀까요?',
          body: hasDraft ? '$next 회원의 임시 저장을 열어요. 지금 적은 내용은 사라져요.' : '지금 적은 내용이 $next 회원 일지가 돼요.',
          keepLabel: '그대로 두기',
          okLabel: '바꾸기');
      if (!ok || !mounted) {
        setState(() {}); // 고르는 칸을 원래 회원으로 되돌린다
        return;
      }
    }
    setState(() {
      member = next;
      final draft = _logDrafts[next];
      if (draft != null) {
        date = draft.date;
        rows
          ..clear()
          ..addAll(draft.rows.map((r) => r.copy()));
        stamp = draft.stamp;
        comment = draft.comment;
        formVersion++;
        baseFingerprint = fingerprint;
      } else if (!dirty) {
        // 임시 저장에서 불러온 그대로면 다른 회원 일지로 남기지 않는다 (리뷰 11/08 #2)
        _startBlank();
      }
    });
  }

  /// 임시 저장을 지운다 (리뷰 11/07 #4)
  Future<void> _deleteDraft() async {
    final ok = await confirmDialog(context,
        title: '임시 저장을 지울까요?', body: '지우면 되돌릴 수 없어요.', keepLabel: '그대로 두기', okLabel: '지우기', danger: true);
    if (!ok || !mounted) return;
    demo.update(() => _logDrafts.remove(member));
    // 바로 새로 쓸 수 있게 화면은 닫지 않는다 (리뷰 11/08 #6)
    setState(_startBlank);
    toast(context, '임시 저장을 지웠어요. 새로 쓸 수 있어요');
  }

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

  /// 지난 수업의 종목·무게·횟수를 불러온다. 코멘트와 영상은 가져오지 않는다 (결정 d1106-3)
  Future<void> _loadLast() async {
    final logs = demo.logsOf(member!);
    if (logs.isEmpty) return;
    if (rows.any((r) => r.hasInput)) {
      final ok = await confirmDialog(context,
          title: '지난 수업을 불러올까요?', body: videoCount > 0 ? '지금 적은 종목은 지난 수업 내용으로 바뀌고, 붙여 둔 영상도 빠져요.' : '지금 적은 종목은 지난 수업 내용으로 바뀌어요.', keepLabel: '그대로 두기', okLabel: '불러오기');
      if (!ok || !mounted) return;
    }
    setState(() {
      rows
        ..clear()
        ..addAll(logs.first.items.map(_LogRow.fromItem));
    });
    toast(context, '${logs.first.date} 수업을 불러왔어요. 오늘 값으로 고쳐 주세요');
  }

  /// 임시 저장: 회원에게 알림이 가지 않는다 (결정 d1102-2)
  void _saveDraft() {
    if (!dirty) {
      toast(context, '적은 내용이 없어요');
      return;
    }
    demo.update(() => _logDrafts[member!] = _LogDraft(date, [for (final r in rows) r.copy()], stamp, comment));
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
        final hold = rows[i].isHold;
        toast(context, rows[i].reps.trim().isEmpty ? '$where${hold ? '시간을' : '횟수를'} 적어 주세요' : '$where${hold ? '시간은' : '횟수는'} 1 이상으로 적어 주세요');
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
          LogItem(r.name, r.kg.trim().isEmpty ? '체중' : '${r.kg.trim()}kg', '${int.parse(r.reps.trim())}${r.isHold ? '초' : '개'}', int.parse(r.sets.trim())),
      ],
      [for (final r in rows) for (final v in r.videos) LogVideo(r.videoLabel(v), 30)], // 기획서 6번 초안: 올린 날부터 30일
      comment.trim(),
      stamp,
      edited: editing != null,
    );
    demo.update(() {
      if (editing == null) _logDrafts.remove(member);
      final sent = demo.sentLogs[member!] ??= [];
      if (editing != null) {
        sent.remove(editing);
        demo.unseenLogs.remove(editing);
      }
      sent.add(log);
      demo.unseenLogs.add(log);
    });
    // 고친 일지는 처음 보낼 때와 구분하고 출석 도장 말은 뺀다 (리뷰 11/08 #5)
    if (editing != null) {
      toast(context, '$member 회원님 일지를 고쳤어요');
      Navigator.pop(context);
      return;
    }
    toast(context, '$member 회원님께 일지${videoCount == 0 ? '' : '와 영상 $videoCount개'}를 보내고 알림을 보냈어요 ($dateLabel 출석 도장 완료)');
    Navigator.pop(context);
  }

  /// 영상은 어느 종목인지 알 수 있게 줄마다 올린다 (결정 d1106-1)
  void _addVideo(_LogRow r, String source) {
    if (videoCount >= 5) {
      toast(context, '영상은 일지당 최대 5개까지 올릴 수 있어요');
      return;
    }
    if (r.name.isEmpty) {
      toast(context, '종목을 먼저 골라 주세요');
      return;
    }
    setState(() => r.videos.add('${r.name} 영상 · 0:1${videoCount + 1}'));
    toast(context, source == '촬영' ? '15초가 되면 촬영이 자동으로 끝나요' : '15초보다 긴 영상은 앞 15초만 올라가요');
  }

  void _chooseVideo(_LogRow r) {
    showAppSheet<void>(
      context,
      builder: (sheet) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SheetTitle('영상 추가'),
        // 누르기 전에 보이게 같은 안내를 시트에도 (문구는 약관 검토 대기라 그대로)
        const WordText('회원님 촬영 동의 후 올려 주세요', style: AppText.bodyStrong),
        const Muted('영상당 15초 이내 · 회원님 본인에게만 보여요'),
        LineRow(left: const Text('촬영하기'), showArrow: true, onTap: () {
          Navigator.pop(sheet);
          _addVideo(r, '촬영');
        }),
        LineRow(left: const Text('앨범에서 선택'), showArrow: true, onTap: () {
          Navigator.pop(sheet);
          _addVideo(r, '앨범');
        }),
      ]),
    );
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
            DangerTextButton('빼기', onPressed: () => _removeRow(i)),
          ]),
        // 카드 안은 좁아서 글자가 잘리지 않게 종목 칸과 '직접 입력'을 두 줄로
        r.custom
                ? TextFormField(
                    initialValue: r.customName,
                    decoration: const InputDecoration(labelText: '종목 이름', hintText: '예: TRX 로우'),
                    onChanged: (v) => setState(() => r.customName = v),
                  )
                : PickerField(
                    label: '종목',
                    icon: const Icon(Icons.chevron_right, color: AppColors.textSub),
                    // 운동 추가하기(S21)에서 1개를 고른다
                    onTap: () async {
                      final picked = await Navigator.pushNamed(context, Routes.exercisePick, arguments: 1);
                      if (picked is List<String> && picked.isNotEmpty) setState(() => r.exercise = picked.first);
                    },
                    child: Row(children: [
                      if (r.exercise != null) ...[
                        ExerciseThumb(r.exercise!, size: 32),
                        const SizedBox(width: AppSpace.sPlus),
                      ],
                      Expanded(
                        child: WordText(r.exercise ?? '종목을 골라 주세요',
                            style: r.exercise == null ? const TextStyle(color: AppColors.textSub) : null),
                      ),
                    ]),
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
          Expanded(child: NumField(key: ValueKey('${r.hashCode}-${r.isHold}'), label: r.isHold ? '시간(초)' : '횟수', hint: r.isHold ? '30' : '8', decimal: false, value: r.reps, onChanged: (v) => setState(() => r.reps = v))),
          const SizedBox(width: 8),
          Expanded(child: NumField(label: '세트', hint: '4', decimal: false, value: r.sets, onChanged: (v) => setState(() => r.sets = v))),
        ]),
        const Align(
          alignment: Alignment.centerLeft,
          child: Muted('맨몸이면 무게 칸을 비워 두세요', top: AppSpace.xs, bottom: 0),
        ),
        for (var j = 0; j < r.videos.length; j++)
          LineRow(
            left: WordText(r.videoLabel(r.videos[j])),
            right: DangerTextButton('빼기', onPressed: () => _removeVideo(r, j)),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.videocam_outlined, size: 18),
            label: const Text('영상 추가'),
            onPressed: () => _chooseVideo(r),
          ),
        ),
      ]),
    );
  }

  /// 영상을 빼고, 지운 자리에 되돌릴 수 있게 한다 (디자인 리뷰 11/01 #3)
  void _removeVideo(_LogRow r, int i) {
    final removed = r.videos[i];
    setState(() => r.videos.removeAt(i));
    toast(context, '영상을 뺐어요', actionLabel: '되돌리기', onAction: () {
      if (mounted) setState(() => r.videos.insert(i.clamp(0, r.videos.length), removed));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (member == null) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is LogEditArgs) {
        member = arg.member;
        editing = arg.log;
        final m = RegExp(r'(\d+)월 (\d+)일').firstMatch(arg.log.date);
        if (m != null) {
          // 12월 일지를 1월에 고쳐도 다음 해 날짜가 되지 않게 (리뷰 11/08 #6)
          final d = DateTime(demoTodayDate.year, int.parse(m[1]!), int.parse(m[2]!));
          date = d.isAfter(demoTodayDate) ? DateTime(d.year - 1, d.month, d.day) : d;
        }
        rows
          ..clear()
          ..addAll(arg.log.items.map(_LogRow.fromItem));
        for (final v in arg.log.videos) {
          rows.firstWhere((r) => v.name.startsWith('${r.name} 영상'), orElse: () => rows.first).videos.add(v.name);
        }
        stamp = arg.log.stamp;
        comment = arg.log.comment;
      } else {
        member = arg as String? ?? members.first;
      }
      // 임시 저장한 일지가 있으면 이어서 쓴다. 보낸 일지를 고칠 때는 건드리지 않는다 (리뷰 11/08 #1)
      final draft = editing == null ? _logDrafts[member] : null;
      if (draft != null) {
        date = draft.date;
        rows
          ..clear()
          ..addAll(draft.rows.map((r) => r.copy()));
        stamp = draft.stamp;
        comment = draft.comment;
      }
      baseFingerprint = fingerprint;
    }
    // 수업 뒤 길게 적은 일지가 뒤로 가기로 사라지지 않게 먼저 묻는다 (리뷰 11/02 #3)
    return DiscardGuard(
      dirty: dirty,
      title: '작성 중인 일지를 버릴까요?',
      body: editing != null
          ? '고친 내용은 사라지고 보낸 일지는 그대로예요.'
          : (hasOwnDraft ? '고친 내용만 사라지고 임시 저장은 남아요.' : '나가면 적은 내용과 영상이 사라져요.'),
      keepLabel: '계속 쓰기',
      okLabel: '버리고 나가기',
      child: AppPage(title: '일지 작성', children: [
      DropdownButtonFormField<String>(
        initialValue: member,
        decoration: const InputDecoration(labelText: '회원'),
        key: ValueKey('member-$member'),
        items: [for (final m in {...demo.activeMembers, member!}) DropdownMenuItem(value: m, child: Text(m))],
        onChanged: editing != null ? null : (v) => _changeMember(v),
      ),
      const SizedBox(height: AppSpace.m),
      PickerField(
        label: '수업 날짜',
        icon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSub),
        onTap: _pickDate,
        child: Text('$dateLabel (${dayLabels[date.weekday - 1]})${date == demoTodayDate ? ' · 오늘' : ''}'),
      ),
      const Muted('이 날짜에 출석 도장이 찍혀요', top: AppSpace.xs, bottom: AppSpace.m),
      // 영상은 종목 칸에서 올리니 동의 안내를 첫 종목 위에 둔다. 문구는 그대로 (디자인 리뷰 11/07 #5)
      const WordText('회원님 촬영 동의 후 올려 주세요', style: AppText.bodyStrong),
      const Muted('영상당 15초 이내 · 회원님 본인에게만 보여요. 종목 칸의 영상 추가로 올려요.'),
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(children: [
          Expanded(child: Muted('영상 $videoCount/5', bottom: 0)),
          if (demo.logsOf(member!).isNotEmpty) TextButton(onPressed: _loadLast, child: const Text('지난 수업 불러오기')),
        ]),
      ),
      for (var i = 0; i < rows.length; i++) _rowEditor(i),
      AppButton('+ 종목 추가', kind: ButtonKind.soft, top: 0, onPressed: () => setState(() => rows.add(_LogRow()))),
      const SizedBox(height: AppSpace.m),
      TextFormField(
        key: ValueKey('comment-$formVersion'),
        initialValue: comment,
        maxLines: 3,
        decoration: const InputDecoration(labelText: '코멘트', hintText: '자세, 다음 목표 등', alignLabelWithHint: true),
        onChanged: (v) => setState(() => comment = v),
      ),
      const SizedBox(height: AppSpace.m),
      const FieldLabel('응원 스탬프'),
      Seg(options: stamps, value: stamp, onChanged: (v) => setState(() => stamp = v)),
      // 저장과 보내기를 나눠, 다 쓰기 전에 회원에게 알림이 가지 않게 (결정 d1102-2)
      // 회원 이름이 들어가 길어진 보내기 버튼이 줄바꿈되지 않게 세로로 쌓는다 (디자인 리뷰 11/08 #1)
      AppButton(editing == null ? '$member 회원님께 보내기' : '$member 회원님 일지 고쳐서 보내기', onPressed: _save),
      if (editing == null) AppButton('임시 저장', kind: ButtonKind.soft, top: AppSpace.s, onPressed: _saveDraft),
      if (editing == null && hasOwnDraft)
        Center(
          child: DangerTextButton('임시 저장 지우기', onPressed: _deleteDraft),
        ),
    ]),
    );
  }
}
