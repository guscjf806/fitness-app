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
    atHome: demo.place == '집', homeGear: demo.homeGear, quiet: demo.noise == '예', painAreas: demo.painAreas);

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
  /// 처음부터 내 조건에 맞는 운동만, 끄면 전체 (결정 d1027-fit-default). 선생님은 회원 일지용으로 고르니 전체로 시작
  bool fitOnly = demo.role != 'trainer';
  final List<String> selected = [];

  /// 찜한 운동만 모아 보기 (결정 dd1104-favorite)
  bool favoriteOnly = false;

  int get maxPick => (ModalRoute.of(context)?.settings.arguments as int?) ?? AppConfig.maxExercisePick;

  List<ExerciseInfo> get filtered => [
        for (final e in exercises)
          if ((part == '전체' || e.part == part) &&
              (equipment == '전체' || e.equipment == equipment) &&
              (_squash(query).isEmpty || _squash(e.name).contains(_squash(query))) &&
              (!favoriteOnly || demo.favorites.contains(e.id)) &&
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
              child: SelectChip(o, selected: o == value, onSelected: (_) => onChanged(o)),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    // 고른 운동이 있는데 뒤로 가면 버릴지 먼저 묻는다 (리뷰 10/27 #5)
    return DiscardGuard(
      dirty: selected.isNotEmpty,
      title: '고른 운동 ${selected.length}개를 버릴까요?',
      body: '나가면 고른 운동이 추가되지 않아요.',
      keepLabel: '계속 고르기',
      okLabel: '버리고 나가기',
      child: Scaffold(
      appBar: AppBar(title: const Text('운동 추가하기')),
      body: TabBody(top: AppSpace.s, children: [
        Row(children: [
          const Expanded(child: FieldLabel('운동 고르기')),
          SelectChip('내 조건 맞춤', selected: fitOnly, onSelected: (v) => setState(() => fitOnly = v)),
          const SizedBox(width: AppSpace.xsPlus),
          SelectChip('즐겨찾기', selected: favoriteOnly, onSelected: (v) => setState(() => favoriteOnly = v)),
        ]),
        if (fitOnly)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${demo.conditionText}${demo.painAreas.isEmpty ? '' : ' · ${demo.painAreas.join(', ')} 주의'} 기준이에요.',
                style: AppText.body),
          ),
        const SizedBox(height: AppSpace.s),
        TextField(
          decoration: const InputDecoration(hintText: '운동 이름으로 검색해 보세요', prefixIcon: Icon(Icons.search)),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: AppSpace.sPlus),
        const Muted('부위', bottom: AppSpace.xs),
        _filterRow(_parts, part, (v) => setState(() => part = v)),
        const Muted('기구', bottom: AppSpace.xs),
        _filterRow(_equipments, equipment, (v) => setState(() => equipment = v)),
        Row(children: [
          Expanded(child: Muted('선택한 운동 ${selected.length} / $maxPick', bottom: AppSpace.xs)),
          Muted('전체 ${list.length}개', bottom: AppSpace.xs),
        ]),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Muted(favoriteOnly && demo.favorites.isEmpty ? '찜한 운동이 없어요. 하트를 눌러 모아 보세요' : '조건에 맞는 운동이 없어요', align: TextAlign.center),
          ),
        for (final e in list)
          Material(
            color: selected.contains(e.id) ? AppColors.primarySoft : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: BorderSide(color: selected.contains(e.id) ? AppColors.primary : Colors.transparent, width: 2),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: () => _toggle(e),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(children: [
                  ExerciseFigureView(e.id),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      WordText(e.name, style: AppText.bodyStrong),
                      Muted('${e.part} · ${e.equipment}${e.level == 3 ? ' · 상급' : ''}', bottom: 0),
                      // '내 조건 맞춤'을 꺼도 아픈 부위와 겹치면 표시한다 (리뷰 10/27 #2)
                      if (e.avoidFor.any(demo.painAreas.contains))
                        PainTag(e.avoidFor.where(demo.painAreas.contains).toList()),
                    ]),
                  ),
                  IconButton(
                    tooltip: '운동 방법 보기',
                    icon: const Icon(Icons.info_outline, color: AppColors.textSub),
                    onPressed: () => Navigator.pushNamed(context, Routes.exerciseDetail, arguments: e.id),
                  ),
                  IconButton(
                    tooltip: '즐겨찾기',
                    icon: Icon(demo.favorites.contains(e.id) ? Icons.favorite : Icons.favorite_border,
                        color: demo.favorites.contains(e.id) ? AppColors.primaryDark : AppColors.textSub),
                    onPressed: () => setState(() => demo.update(() => demo.favorites.contains(e.id) ? demo.favorites.remove(e.id) : demo.favorites.add(e.id))),
                  ),
                  // 고른 운동은 색뿐 아니라 체크 표시로도 알린다 (리뷰 10/27 #3)
                  CheckCircle(selected.contains(e.id)),
                ]),
              ),
            ),
          ),
      ]),
      bottomNavigationBar: BottomActionBar(
          child: AppButton(
            selected.isEmpty ? '추가 완료' : '추가 완료 (${selected.length})',
            top: 0,
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
        // 바꿔치기 대신 위에 쌓아서, 뒤로 가면 원래 보던 운동으로 돌아온다 (리뷰 10/27 #7)
        onTap: () => Navigator.pushNamed(context, Routes.exerciseDetail, arguments: r.id),
        left: Row(children: [
          ExerciseFigureView(r.id, size: 40, radius: AppRadius.small),
          const SizedBox(width: AppSpace.sPlus),
          Expanded(child: Text(r.name)),
        ]),
        right: Muted(label, bottom: 0),
        showArrow: true,
      );
    }

    return AppPage(title: e.name, children: [
      Center(child: ExerciseFigureView(e.id, size: 200, radius: AppRadius.large)),
      // 내 아픈 부위와 겹치면 그림 바로 아래에 크게 경고한다 (리뷰 10/27 #1)
      if (painHit.isNotEmpty) WarningBox(painPhrase(painHit)),
      const SizedBox(height: 14),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final t in [e.part, e.equipment, _placeLabel[e.place]!, _levelLabel[e.level]!]) InfoTag(t),
        if (e.impact == 'high') const InfoTag('점프·고충격', caution: true),
        if (e.noise == 'loud') const InfoTag('소음 큼', caution: true),
      ]),
      const H2('필요한 기구'),
      Text(e.gear.isEmpty ? '기구 없이 할 수 있어요' : e.gear.join(', ')),
      // 작은 회색 글씨 대신 14px 본문 색으로 (리뷰 10/27 #6)
      if (e.gearOptional.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('있으면 좋은 것: ${e.gearOptional.join(', ')}', style: AppText.body),
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
                  style: AppText.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: AppSpace.sPlus),
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
