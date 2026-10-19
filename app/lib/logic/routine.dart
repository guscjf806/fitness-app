import '../data/exercise_lookup.dart';
import '../data/exercise_models.dart';
import '../data/mock_data.dart';
import 'intensity.dart';

/// 이 종목을 이 조건에서 써도 되는지 (기획서 6번 '홈트 조건 필터', 16번 안전 규칙).
/// - 아픈 부위에 무리가 가는 종목은 장소와 상관없이 뺀다
/// - 집에서 하는 날: 헬스장 전용 종목, 가진 장비가 아닌 종목, (조용히일 때) 점프·소음 종목을 뺀다
bool exerciseAllowed(
  ExerciseInfo e, {
  required bool atHome,
  required String equipment,
  required bool quiet,
  required List<String> painAreas,
}) {
  if (e.avoidFor.any(painAreas.contains)) return false;
  if (!atHome) return true;
  if (e.place == 'gym') return false;
  if (quiet && (e.impact == 'high' || e.noise == 'loud')) return false;
  final allowed = equipment == '맨몸' ? const {'맨몸'} : const {'맨몸', '덤벨', '밴드'};
  return allowed.contains(e.equipment);
}

/// 한 번에 운동할 시간에 맞는 종목 수 (기획서 초안: 15분 3종목, 30분 4~5종목, 45분 6~7종목)
int maxExercisesFor(String minutes) => switch (minutes) {
      '15분' => 3,
      '30분' => 5,
      _ => 7,
    };

/// 안전망: 루틴에서 조건에 맞지 않는 종목을 빼고 시간에 맞게 줄인다.
/// AI가 만든 루틴도 저장하기 전에 반드시 이 함수를 거친다. 목록에 없는 종목도 뺀다.
WorkoutDay enforceConditions(
  WorkoutDay day, {
  required String equipment,
  required bool quiet,
  required List<String> painAreas,
  required String minutes,
}) {
  final kept = [
    for (final x in day.items)
      if (exerciseByName(x.name) case final info?)
        if (exerciseAllowed(info, atHome: day.atHome, equipment: equipment, quiet: quiet, painAreas: painAreas)) x,
  ];
  final trimmed = kept.take(maxExercisesFor(minutes)).toList();
  return WorkoutDay(day.title, trimmed, atHome: day.atHome, removed: day.items.length - kept.length);
}

/// 일주일 중 운동하는 요일 (0=월 … 6=일). 쉬는 날이 몰리지 않게 띄운다.
/// 주 2~3일은 하루씩 쉬어 회복 시간을 두고, 주 6일은 일요일 하루를 쉰다.
const trainingDays = {
  2: [0, 3], // 월 목
  3: [0, 2, 4], // 월 수 금
  4: [0, 1, 3, 4], // 월 화 목 금
  5: [0, 1, 2, 3, 4], // 월~금
  6: [0, 1, 2, 3, 4, 5], // 월~토
};

/// 목업 루틴: 운동하는 요일마다 세션을 차례로 배치한 7일(월~일)을 만들고 안전망을 거친다.
/// (실제 앱에서는 AI가 만든 루틴이 이 자리에 들어간다)
List<WorkoutDay> demoWeek({
  required String place,
  required String equipment,
  required String noise,
  required String minutes,
  required List<String> painAreas,
  required String daysPerWeek,
  String desiredIntensity = '중',
  String currentIntensity = '중',
}) {
  final quiet = noise == '예';
  final intensity = effectiveIntensity(desired: desiredIntensity, current: currentIntensity);
  final homeBase = equipment == '맨몸' ? homeBodyweightSessions : homeDumbbellSessions;
  // 층간소음 걱정이 없으면 맨몸 루틴의 일부를 점프 동작으로 바꾼다
  final home = [
    for (final d in homeBase)
      WorkoutDay(d.title, [for (final x in d.items) quiet || x.loudAlt == null ? x : Exercise(x.loudAlt!, x.amount, x.sets)],
          atHome: true),
  ];
  final days = trainingDays[int.tryParse(daysPerWeek.replaceAll('일', '')) ?? 3] ?? trainingDays[3]!;
  var gymIndex = 0, homeIndex = 0;
  WorkoutDay session(int n) => switch (place) {
        '헬스장' => gymSessions[gymIndex++ % gymSessions.length],
        '집' => home[homeIndex++ % home.length],
        // 둘 다: 헬스장 날과 집 날을 번갈아 둔다 (기획서 16번)
        _ => n.isEven ? gymSessions[gymIndex++ % gymSessions.length] : home[homeIndex++ % home.length],
      };
  return [
    for (var weekday = 0; weekday < 7; weekday++)
      days.contains(weekday)
          ? _build(session(days.indexOf(weekday)),
              intensity: intensity, equipment: equipment, quiet: quiet, painAreas: painAreas, minutes: minutes)
          : const WorkoutDay('휴식', []),
  ];
}

/// 한 운동일: 강도에 맞는 동작으로 바꾸기 → 안전망 → 개수·세트와 시간 맞추기
WorkoutDay _build(
  WorkoutDay day, {
  required String intensity,
  required String equipment,
  required bool quiet,
  required List<String> painAreas,
  required String minutes,
}) {
  bool allowed(ExerciseInfo e) =>
      exerciseAllowed(e, atHome: day.atHome, equipment: equipment, quiet: quiet, painAreas: painAreas);
  final varied = WorkoutDay(
      day.title, [for (final x in day.items) Exercise(variantFor(x.name, intensity, allowed), x.amount, x.sets)],
      atHome: day.atHome);
  final safe = enforceConditions(varied, equipment: equipment, quiet: quiet, painAreas: painAreas, minutes: minutes);
  return applyIntensity(safe, intensity: intensity, minutes: minutes);
}
