import 'dart:async';

import 'package:flutter/material.dart';

import '../data/exercises.dart';
import '../logic/intensity.dart';
import '../logic/routine.dart';
import '../routes.dart';
import '../state/demo_state.dart';
import '../state/workout_session.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/exercise_figure.dart';
import '../widgets/rest_timer.dart';

IntensityRule get _rule =>
    intensityRules[effectiveIntensity(desired: demo.desiredIntensity, current: demo.currentIntensity)]!;

/// S23 운동 진행: 종목별로 세트를 기록하고, 세트를 마치면 휴식 타이머가 뜬다.
class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  int index = 0;
  Timer? ticker;

  WorkoutSession get session => demo.session!;
  SessionExercise get current => session.items[index];

  @override
  void initState() {
    super.initState();
    // 위쪽 경과 시간을 1초마다 새로 그린다
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  String get elapsed {
    final s = DateTime.now().difference(session.startedAt).inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  void _toggleSet(int i) {
    final set = current.sets[i];
    setState(() => set.done = !set.done);
    final lastSet = index == session.items.length - 1 && current.sets.every((s) => s.done);
    if (set.done && !lastSet) showRestTimer(context, _rule.restSeconds);
  }

  /// 3. 운동 대체: 같은 부위이면서 내 조건에 맞고, 오늘 루틴에 없는 종목
  void _swap() {
    final info = exerciseByName(current.name);
    final names = session.items.map((x) => x.name).toSet();
    final options = [
      for (final e in exercises)
        if (info != null &&
            e.part == info.part &&
            !names.contains(e.name) &&
            exerciseAllowed(e,
                atHome: session.atHome, equipment: demo.equipment, quiet: demo.noise == '예', painAreas: demo.painAreas))
          e,
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * .7),
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(20, 20, 20, 20), children: [
            const SheetTitle('운동 대체'),
            Muted('${current.name} 대신 할 수 있는 ${info?.part ?? ''} 운동이에요. 내 조건에 맞는 것만 보여 줘요.'),
            if (options.isEmpty) const Muted('바꿀 수 있는 운동이 없어요.'),
            for (final e in options)
              LineRow(
                onTap: () async {
                  // 체크한 세트가 있으면 사라진다고 먼저 묻고, 바꾼 뒤에도 되돌릴 수 있게 한다 (리뷰 10/28 #1)
                  final doneCount = current.sets.where((s) => s.done).length;
                  if (doneCount > 0) {
                    final ok = await showDialog<bool>(
                      context: sheet,
                      builder: (dialog) => AlertDialog(
                        title: Text('기록한 $doneCount세트가 사라져요. 바꿀까요?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('그대로 두기')),
                          TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('바꾸기')),
                        ],
                      ),
                    );
                    if (ok != true || !sheet.mounted) return;
                  }
                  final before = current;
                  final at = index;
                  final (amount, sets) = targetFor(e, _rule);
                  setState(() => session.items[at] = SessionExercise(e.name, amount, sets));
                  Navigator.pop(sheet);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text('${e.name}(으)로 바꿨어요'),
                      action: SnackBarAction(
                        label: '되돌리기',
                        onPressed: () {
                          if (mounted) setState(() => session.items[at] = before);
                        },
                      ),
                    ));
                },
                left: Row(children: [
                  ExerciseFigureView(e.id, size: 44, radius: 10),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.name)),
                ]),
                right: Muted(e.equipment, bottom: 0),
              ),
          ]),
        ),
      ),
    );
  }

  /// 4. 순서 변경: 끌어서 순서를 바꾸고, 눌러서 그 운동으로 이동
  void _showList() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * .7),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Row(children: [
                  const Expanded(child: SheetTitle('오늘 운동 순서')),
                  Muted('총 ${session.items.length}개 · ${session.doneSets}/${session.totalSets}세트', bottom: 0),
                ]),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Muted('오른쪽 손잡이를 끌어 순서를 바꿔요.'),
              ),
              Flexible(
                child: ReorderableListView(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  onReorderItem: (from, to) {
                    final currentItem = current;
                    setSheet(() => session.items.insert(to, session.items.removeAt(from)));
                    setState(() => index = session.items.indexOf(currentItem));
                  },
                  children: [
                    for (var i = 0; i < session.items.length; i++)
                      ListTile(
                        key: ValueKey(session.items[i]),
                        selected: i == index,
                        selectedTileColor: AppColors.primarySoft,
                        leading: ExerciseThumb(session.items[i].name),
                        title: Text(session.items[i].name),
                        subtitle: Text('${session.items[i].sets.where((s) => s.done).length}/${session.items[i].sets.length}세트'),
                        trailing: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
                        onTap: () {
                          setState(() => index = i);
                          Navigator.pop(sheet);
                        },
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _finish() {
    if (session.doneSets == 0) {
      toast(context, '체크한 세트가 없어요. 세트를 마치면 ✓를 눌러 주세요');
      return;
    }
    if (demo.isGuest) {
      requireLogin(context, '운동 기록과 연속 기록은 계정에 저장돼요. 로그인하면 오늘부터 기록이 쌓여요.');
      return;
    }
    final minutes = DateTime.now().difference(session.startedAt).inMinutes;
    final sets = session.doneSets;
    demo.update(() {
      demo.workoutDone = true;
      demo.checked.addAll([for (var i = 0; i < demo.week[0].items.length; i++) i]);
    });
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text('오늘 운동 완료! 총 $sets세트 · $minutes분 · 연속 ${demo.streak}일째예요')));
  }

  @override
  Widget build(BuildContext context) {
    final ex = current;
    final info = exerciseByName(ex.name);
    final last = index == session.items.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.timer_outlined, size: 20, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(elapsed),
        ]),
        // 같은 창을 여는 버튼이 두 개라 헷갈려서 하나로 (디자인 리뷰 10/30 #7)
        actions: [TextButton(onPressed: _showList, child: const Text('목록·순서'))],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 20), children: [
        // 끝까지 하고 나서야 저장 안 된다는 걸 알지 않게 처음부터 알린다 (리뷰 10/28 #6)
        if (demo.isGuest) const GuestBanner('체크해 볼 수 있지만 저장되지 않아요. 로그인하면 기록이 쌓여요.'),
        Muted('${index + 1} / ${session.items.length}', bottom: 2),
        Text(ex.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (info != null) Center(child: ExerciseFigureView(info.id, size: 120, radius: 16)),
        // 아픈 부위와 겹치면 운동 상세와 같은 경고 상자를 그림 바로 아래에 (리뷰 10/28 #3)
        if (info != null && info.avoidFor.any(demo.painAreas.contains))
          WarningBox(painPhrase(info.avoidFor.where(demo.painAreas.contains).toList())),
        if (info != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AppCard(child: Text(info.caution, textAlign: TextAlign.center)),
          ),
        Wrap(spacing: 6, runSpacing: 6, children: [
          ActionChip(
            avatar: const Icon(Icons.menu_book_outlined, size: 18),
            label: const Text('운동 방법'),
            onPressed: () => Navigator.pushNamed(context, Routes.exerciseDetail, arguments: ex.name),
          ),
          ActionChip(avatar: const Icon(Icons.swap_horiz, size: 18), label: const Text('운동 대체'), onPressed: _swap),
        ]),
        const SizedBox(height: 10),
        // 세트 칸이 화면 위쪽에 오도록 그림을 줄이고, 무게 고르는 법은 쉬운 말과 본문 글씨로 (리뷰 10/28 #7)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('목표 ${ex.target}${ex.bodyweight ? '' : '\n무게: 마지막 세트를 끝냈을 때 ${_rule.repsInReserve}쯤 더 할 수 있는 무게'}',
              style: const TextStyle(fontSize: 14, color: AppColors.text)),
        ),
        for (var i = 0; i < ex.sets.length; i++)
          _SetRow(
            key: ValueKey('${ex.name}-$i'),
            number: i + 1,
            entry: ex.sets[i],
            unit: ex.unit,
            bodyweight: ex.bodyweight,
            onToggle: () => _toggleSet(i),
            onKg: (v) => setState(() => ex.copyKgDown(i, v)),
          ),
        Row(children: [
          Expanded(
            child: AppButton('세트 삭제', kind: ButtonKind.soft, onPressed: ex.sets.length <= 1
                ? null
                : () => setState(() => ex.sets.removeLast())),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton('+ 세트 추가', kind: ButtonKind.soft, onPressed: () => setState(() {
              final prev = ex.sets.last;
              ex.sets.add(SetEntry(kg: prev.kg, reps: prev.reps));
            })),
          ),
        ]),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Row(children: [
            if (index > 0) ...[
              Expanded(child: AppButton('이전', kind: ButtonKind.soft, top: 0, onPressed: () => setState(() => index--))),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: AppButton(last ? '운동 완료' : '다음 운동', top: 0, onPressed: last ? _finish : () => setState(() => index++)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// 세트 한 줄: 무게(kg) / 횟수(회 또는 초) / 완료 체크
class _SetRow extends StatelessWidget {
  const _SetRow({
    super.key,
    required this.number,
    required this.entry,
    required this.unit,
    required this.bodyweight,
    required this.onToggle,
    required this.onKg,
  });
  final int number;
  final SetEntry entry;
  final String unit;
  final bool bodyweight;
  final VoidCallback onToggle;
  final ValueChanged<String> onKg;

  @override
  Widget build(BuildContext context) {
    // 폭을 숫자로 고정하지 않아서 큰 글씨·좁은 폰에서도 줄이 넘치지 않게 (디자인 리뷰 10/30 #3)
    Widget field(String value, String suffix, ValueChanged<String> onChanged) =>
        Expanded(child: _NumCell(value: value, suffix: suffix, onChanged: onChanged));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: entry.done ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: entry.done ? AppColors.primary : Colors.transparent),
      ),
      child: Row(children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44),
          child: Text('$number세트', softWrap: false, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        if (bodyweight)
          const Expanded(child: Muted('맨몸', bottom: 0, align: TextAlign.center))
        else
          field(entry.kg, 'kg', onKg),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('/')),
        field(entry.reps, unit, (v) => entry.reps = v),
        const SizedBox(width: 6),
        IconButton(
          tooltip: '$number세트 완료',
          onPressed: onToggle,
          icon: Icon(entry.done ? Icons.check_circle : Icons.check_circle_outline,
              color: entry.done ? AppColors.primary : AppColors.textSub, size: 30),
        ),
      ]),
    );
  }
}

/// 숫자 칸. 다른 세트에서 값이 채워지면(무게 복사) 이 칸도 따라 바뀐다. 입력 중인 칸은 건드리지 않는다.
class _NumCell extends StatefulWidget {
  const _NumCell({required this.value, required this.suffix, required this.onChanged});
  final String value;
  final String suffix;
  final ValueChanged<String> onChanged;

  @override
  State<_NumCell> createState() => _NumCellState();
}

class _NumCellState extends State<_NumCell> {
  late final controller = TextEditingController(text: widget.value);
  final focus = FocusNode();

  @override
  void didUpdateWidget(_NumCell old) {
    super.didUpdateWidget(old);
    if (!focus.hasFocus && controller.text != widget.value) controller.text = widget.value;
  }

  @override
  void dispose() {
    controller.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        focusNode: focus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        decoration: InputDecoration(suffixText: widget.suffix, hintText: widget.suffix, isDense: true),
        onChanged: widget.onChanged,
      );
}
