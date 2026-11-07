import '../data/exercise_lookup.dart';

/// 한 세트 기록 (기획서: 회원님이 직접 쓰는 운동 기록의 가벼운 1차 버전)
class SetEntry {
  SetEntry({this.kg = '', this.reps = '', this.done = false});
  String kg;
  String reps;
  bool done;

  /// 위 세트에서 복사해 온 무게인지 (직접 적은 무게는 덮어쓰지 않는다)
  bool kgCopied = false;

  /// 지난번 무게를 미리 채운 칸. 회색으로 보여 준다 (결정 d1028-weight-prefill)
  bool suggested = false;
}

class SessionExercise {
  SessionExercise(this.name, this.target, int sets)
      : sets = [for (var i = 0; i < sets; i++) SetEntry(reps: RegExp(r'\d+').firstMatch(target)?.group(0) ?? '')];

  String name;

  /// 오늘 루틴의 원래 종목. 대체해도 어느 줄인지 알 수 있게 (리뷰 11/07 #2)
  late String originName = name;

  /// 목표 개수 (예: '8~12개', '30~40초')
  String target;
  final List<SetEntry> sets;

  /// [i]세트에 무게를 적으면 아래의 빈 칸(또는 복사해 온 칸)에도 같은 값을 채운다 (리뷰 10/28 #5)
  void copyKgDown(int i, String kg) {
    sets[i]
      ..kg = kg
      ..kgCopied = false
      ..suggested = false;
    // 직접 적은 칸을 만나면 거기서 멈춘다 (그 아래는 그 칸의 무게를 따른다)
    for (final s in sets.skip(i + 1)) {
      if (s.kg.isNotEmpty && !s.kgCopied) break;
      s
        ..kg = kg
        ..kgCopied = kg.isNotEmpty
        ..suggested = false;
    }
  }

  /// 지난번 무게를 모든 세트에 미리 채운다. 한 칸을 고치면 아래로 함께 바뀐다
  void prefillKg(String kg) {
    if (bodyweight || kg.isEmpty) return;
    for (final s in sets) {
      s
        ..kg = kg
        ..kgCopied = true
        ..suggested = true;
    }
  }

  bool get hasSuggestedKg => sets.any((s) => s.suggested);

  /// 버티기 운동이면 '초', 아니면 '회'
  String get unit => target.endsWith('초') ? '초' : '회';

  /// 맨몸 운동은 무게를 적지 않는다
  bool get bodyweight => exerciseByName(name)?.equipment == '맨몸';
}

/// 오늘 진행 중인 운동 (S23). 목업에서는 메모리에만 둔다.
class WorkoutSession {
  WorkoutSession(this.items, {required this.atHome}) : startedAt = DateTime.now();

  final List<SessionExercise> items;
  final bool atHome;
  final DateTime startedAt;

  int get doneSets => items.fold(0, (t, x) => t + x.sets.where((s) => s.done).length);
  int get totalSets => items.fold(0, (t, x) => t + x.sets.length);
}
