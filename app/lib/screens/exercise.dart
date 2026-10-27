import 'package:flutter/material.dart';

import '../config.dart';
import '../data/exercise_models.dart';
import '../data/exercises.dart';
import '../logic/routine.dart';
import '../routes.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/exercise_figure.dart';

const _parts = ['전체', '가슴', '등', '하체', '어깨', '삼두', '이두', '코어', '전신'];
const _equipments = ['전체', '바벨', '덤벨', '밴드', '머신', '케이블', '맨몸'];
const _placeLabel = {'gym': '헬스장 전용', 'home': '집에서도 가능'};
const _levelLabel = {1: '초급', 2: '중급', 3: '상급'};

/// 내 조건(장소·장비·층간소음·아픈 부위)에 맞는 종목인지 (기획서 6번 '홈트 조건 필터', 16번 안전 규칙)
/// 장소가 '둘 다'면 헬스장 종목도 고를 수 있다
bool fitsMyCondition(ExerciseInfo e) => exerciseAllowed(e,
    atHome: demo.place == '집', equipment: demo.equipment, quiet: demo.noise == '예', painAreas: demo.painAreas);

/// 검색할 때 띄어쓰기를 무시한다: '벤치 프레스'로도 '벤치프레스'를 찾는다 (리뷰 10/27 #4)
String _squash(String s) => s.replaceAll(RegExp(r'\s+'), '');

/// S21 운동 추가하기. 고른 종목 이름 목록을 돌려준다.
/// arguments: 한 번에 고를 수 있는 개수 (선생님 일지는 1개)
class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  String query = '';
  String part = '전체';
  String equipment = '전체';
  bool fitOnly = false;
  final List<String> selected = [];

  static final Set<String> favorites = {'deadlift'};

  int get maxPick => (ModalRoute.of(context)?.settings.arguments as int?) ?? AppConfig.maxExercisePick;

  List<ExerciseInfo> get filtered => [
        for (final e in exercises)
          if ((part == '전체' || e.part == part) &&
              (equipment == '전체' || e.equipment == equipment) &&
              (_squash(query).isEmpty || _squash(e.name).contains(_squash(query))) &&
              (!fitOnly || fitsMyCondition(e)))
            e,
      ];

  void _toggle(ExerciseInfo e) {
    setState(() {
      if (selected.contains(e.id)) {
        selected.remove(e.id);
      } else if (maxPick == 1) {
        selected
          ..clear()
          ..add(e.id);
      } else if (selected.length >= maxPick) {
        toast(context, '한 번에 $maxPick개까지 고를 수 있어요');
      } else {
        selected.add(e.id);
      }
    });
  }

  Widget _filterRow(List<String> options, String value, ValueChanged<String> onChanged) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(o),
                selected: o == value,
                showCheckmark: false,
                selectedColor: AppColors.primarySoft,
                labelStyle: TextStyle(
                    color: o == value ? AppColors.primaryDark : AppColors.text,
                    fontWeight: o == value ? FontWeight.w700 : FontWeight.w400),
                shape: const StadiumBorder(),
                onSelected: (_) => onChanged(o),
              ),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    // 고른 운동이 있는데 뒤로 가면 버릴지 먼저 묻는다 (리뷰 10/27 #5)
    return PopScope(
      canPop: selected.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: Text('고른 운동 ${selected.length}개를 버릴까요?'),
            content: const Text('나가면 고른 운동이 추가되지 않아요.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('계속 고르기')),
              TextButton(
                onPressed: () => Navigator.pop(dialog, true),
                child: const Text('버리고 나가기', style: TextStyle(color: AppColors.warning)),
              ),
            ],
          ),
        );
        if (discard == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
      appBar: AppBar(title: const Text('운동 추가하기')),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 20), children: [
        Row(children: [
          const Expanded(child: Muted('운동을 골라 주세요', bottom: 0)),
          FilterChip(
            label: const Text('내 조건 맞춤'),
            selected: fitOnly,
            selectedColor: AppColors.primarySoft,
            onSelected: (v) => setState(() => fitOnly = v),
          ),
        ]),
        if (fitOnly)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${demo.conditionText}${demo.painAreas.isEmpty ? '' : ' · ${demo.painAreas.join(', ')} 주의'} 기준이에요.',
                style: const TextStyle(fontSize: 14, color: AppColors.text)),
          ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(hintText: '운동 이름으로 검색해 보세요', prefixIcon: Icon(Icons.search)),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 10),
        const Muted('부위', bottom: 4),
        _filterRow(_parts, part, (v) => setState(() => part = v)),
        const Muted('기구', bottom: 4),
        _filterRow(_equipments, equipment, (v) => setState(() => equipment = v)),
        Row(children: [
          Expanded(child: Muted('선택한 운동 ${selected.length} / $maxPick', bottom: 4)),
          Muted('전체 ${list.length}개', bottom: 4),
        ]),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 30),
            child: Muted('조건에 맞는 운동이 없어요', align: TextAlign.center),
          ),
        for (final e in list)
          Material(
            color: selected.contains(e.id) ? AppColors.primarySoft : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: selected.contains(e.id) ? AppColors.primary : Colors.transparent, width: 2),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _toggle(e),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(children: [
                  ExerciseFigureView(e.id),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Muted('${e.part} · ${e.equipment}', bottom: 0),
                      // '내 조건 맞춤'을 꺼도 아픈 부위와 겹치면 표시한다 (리뷰 10/27 #2)
                      if (e.avoidFor.any(demo.painAreas.contains))
                        Text('${e.avoidFor.where(demo.painAreas.contains).join(', ')} 주의',
                            style: const TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  IconButton(
                    tooltip: '운동 방법 보기',
                    icon: const Icon(Icons.info_outline, color: AppColors.textSub),
                    onPressed: () => Navigator.pushNamed(context, Routes.exerciseDetail, arguments: e.id),
                  ),
                  IconButton(
                    tooltip: '즐겨찾기',
                    icon: Icon(favorites.contains(e.id) ? Icons.favorite : Icons.favorite_border,
                        color: favorites.contains(e.id) ? AppColors.primaryDark : AppColors.textSub),
                    onPressed: () => setState(() => favorites.contains(e.id) ? favorites.remove(e.id) : favorites.add(e.id)),
                  ),
                  // 고른 운동은 색뿐 아니라 체크 표시로도 알린다 (리뷰 10/27 #3)
                  CheckCircle(selected.contains(e.id)),
                ]),
              ),
            ),
          ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: AppButton(
            selected.isEmpty ? '추가 완료' : '추가 완료 (${selected.length})',
            top: 8,
            onPressed: () {
              if (selected.isEmpty) {
                toast(context, '운동을 하나 이상 골라 주세요');
                return;
              }
              Navigator.pop(context, [for (final id in selected) exerciseById(id)!.name]);
            },
          ),
        ),
      ),
    ),
    );
  }
}

/// S22 운동 상세 (방법 3단계 + 주의할 점). arguments: 종목 id 또는 이름
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = (ModalRoute.of(context)?.settings.arguments as String?) ?? 'squat';
    final e = exerciseById(arg) ?? exerciseByName(arg);
    if (e == null) {
      return AppPage(title: arg, children: const [Muted('선생님이 직접 추가한 운동이라 설명이 없어요.')]);
    }
    final painHit = e.avoidFor.where(demo.painAreas.contains).toList();
    Widget related(String label, String? id) {
      if (id == null) return const SizedBox.shrink();
      final r = exerciseById(id)!;
      return LineRow(
        onTap: () => Navigator.pushReplacementNamed(context, Routes.exerciseDetail, arguments: r.id),
        left: Row(children: [
          ExerciseFigureView(r.id, size: 40, radius: 10),
          const SizedBox(width: 10),
          Expanded(child: Text(r.name)),
        ]),
        right: Muted('$label ›', bottom: 0),
      );
    }

    return AppPage(title: e.name, children: [
      Center(child: ExerciseFigureView(e.id, size: 200, radius: 20)),
      // 내 아픈 부위와 겹치면 그림 바로 아래에 크게 경고한다 (리뷰 10/27 #1)
      if (painHit.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text('${painHit.join(', ')} 통증이 있으면 이 운동은 피하는 게 좋아요.',
                  style: const TextStyle(color: AppColors.warning, fontSize: 16, fontWeight: FontWeight.w700, height: 1.4)),
            ),
          ]),
        ),
      const SizedBox(height: 14),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final t in [e.part, e.equipment, _placeLabel[e.place]!, _levelLabel[e.level]!]) Chip(label: Text(t)),
        if (e.impact == 'high') const Chip(label: Text('점프·고충격')),
        if (e.noise == 'loud') const Chip(label: Text('소음 큼')),
      ]),
      const H2('필요한 기구'),
      Text(e.gear.isEmpty ? '기구 없이 할 수 있어요' : e.gear.join(', ')),
      // 작은 회색 글씨 대신 14px 본문 색으로 (리뷰 10/27 #6)
      if (e.gearOptional.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('있으면 좋은 것: ${e.gearOptional.join(', ')}', style: const TextStyle(fontSize: 14, color: AppColors.text)),
        ),
      const H2('하는 방법'),
      for (var i = 0; i < e.howTo.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
              child: Text('${i + 1}',
                  style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(e.howTo[i])),
          ]),
        ),
      AppCard(
        accent: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Muted('주의할 점', bottom: 2),
          Text(e.caution),
        ]),
      ),
      if (e.easierId != null || e.harderId != null) ...[
        const H2('비슷한 운동'),
        related('쉬운 동작', e.easierId),
        related('어려운 동작', e.harderId),
      ],
      const Disclaimer(text: '통증이 느껴지면 바로 멈추세요. 이 설명은 의료 조언이 아닙니다.'),
    ]);
  }
}
