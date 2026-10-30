import '../data/exercise_lookup.dart';

/// 한 세트 기록 (기획서: 회원님이 직접 쓰는 운동 기록의 가벼운 1차 버전)
class SetEntry {
  SetEntry({this.kg = '', this.reps = '', this.done = false});
  String kg;
  String reps;
  bool done;

  /// 위 세트에서 복사해 온 무게인지 (직접 적은 무게는 덮어쓰지 않는다)
  bool kgCopied = false;
}

class SessionExercise {
  SessionExercise(this.name, this.target, int sets)
      : sets = [for (var i = 0; i < sets; i++) SetEntry(reps: RegExp(r'\d+').firstMatch(target)?.group(0) ?? '')];

  String name;

  /// 목표 개수 (예: '8~12개', '30~40초')
  String target;
  final List<SetEntry> sets;

  /// [i]세트에 무게를 적으면 아래의 빈 칸(또는 복사해 온 칸)에도 같은 값을 채운다 (리뷰 10/28 #5)
  void copyKgDown(int i, String kg) {
    sets[i]
      ..kg = kg
      ..kgCopied = false;
    for (final s in sets.skip(i + 1)) {
      if (s.kg.isEmpty || s.kgCopied) {
        s
          ..kg = kg
          ..kgCopied = kg.isNotEmpty;
      }
    }
  }

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
