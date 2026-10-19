import '../data/exercise_lookup.dart';
import '../data/exercise_models.dart';
import '../data/mock_data.dart';

/// '앞으로 원하는 강도'(상·중·하)에 따른 루틴 규칙 (기획서 6번 '계산 규칙'). 숫자는 초안 값.
class IntensityRule {
  const IntensityRule({
    required this.compoundSets,
    required this.compoundReps,
    required this.isolationSets,
    required this.isolationReps,
    required this.holdSeconds,
    required this.repsInReserve,
    required this.restSeconds,
    required this.restText,
  });

  /// 큰 운동(여러 관절: 스쿼트, 벤치프레스, 로우 등)
  final int compoundSets;
  final String compoundReps;

  /// 작은 운동(한 관절: 컬, 레이즈, 푸시다운 등)
  final int isolationSets;
  final String isolationReps;

  /// 버티기 운동(플랭크 등)
  final String holdSeconds;

  /// 무게 안내: 마지막 세트 뒤에 몇 개 더 할 수 있는 무게로 할지
  final String repsInReserve;

  /// 세트 사이 휴식 (시간 계산용 평균값과 안내 문구)
  final int restSeconds;
  final String restText;
}

const intensityRules = {
  '하': IntensityRule(
      compoundSets: 3, compoundReps: '12~15개', isolationSets: 2, isolationReps: '15개', holdSeconds: '20초',
      repsInReserve: '3~4개', restSeconds: 60, restText: '60초'),
  '중': IntensityRule(
      compoundSets: 4, compoundReps: '8~12개', isolationSets: 3, isolationReps: '12개', holdSeconds: '30~40초',
      repsInReserve: '2개', restSeconds: 75, restText: '60~90초'),
  '상': IntensityRule(
      compoundSets: 5, compoundReps: '6~8개', isolationSets: 4, isolationReps: '10~12개', holdSeconds: '45~60초',
      repsInReserve: '1개', restSeconds: 105, restText: '90~120초'),
};

/// 한 관절만 쓰는 작은 운동 (나머지는 큰 운동)
const isolationIds = {
  'crossover', 'facepull', 'bandfacepull', 'latraise', 'pushdown', 'kickback', 'dbcurl', 'legcurl', 'calfraise',
  'deadbug', 'birddog', 'superman', 'mclimber',
};

/// 버티기 운동 (개수 대신 초)
const holdIds = {'plank', 'sideplank'};

/// 지금 강도가 '하'인데 '상'을 고르면 첫 2주는 '중'으로 시작한다 (갑자기 올리면 다칠 위험)
const rampUpWeeks = 2;

String effectiveIntensity({required String desired, required String current, int weeksDone = 0}) =>
    current == '하' && desired == '상' && weeksDone < rampUpWeeks ? '중' : desired;

/// 맨몸 운동은 무게 대신 동작 난이도로 강도를 바꾼다: 하 → 쉬운 동작, 상 → 어려운 동작.
/// 바꾼 동작이 내 조건에 맞지 않으면([allowed]가 false) 원래 동작을 그대로 쓴다.
String variantFor(String name, String intensity, bool Function(ExerciseInfo) allowed) {
  final info = exerciseByName(name);
  if (info == null || info.equipment != '맨몸' || intensity == '중') return name;
  final otherId = intensity == '하' ? info.easierId : info.harderId;
  final other = otherId == null ? null : exerciseById(otherId);
  return other != null && allowed(other) ? other.name : name;
}

/// 강도 규칙으로 개수·세트를 정하고, 고른 운동 시간 안에 끝나도록 종목 수를 줄인다(최소 2종목).
WorkoutDay applyIntensity(WorkoutDay day, {required String intensity, required String minutes}) {
  if (day.isRest) return day;
  final rule = intensityRules[intensity]!;
  final items = [
    for (final x in day.items)
      if (exerciseByName(x.name) case final info?)
        holdIds.contains(info.id)
            ? Exercise(x.name, rule.holdSeconds, 3)
            : isolationIds.contains(info.id)
                ? Exercise(x.name, rule.isolationReps, rule.isolationSets)
                : Exercise(x.name, rule.compoundReps, rule.compoundSets),
  ];
  final budget = (int.tryParse(minutes.replaceAll('분', '')) ?? 30) * 60;
  var used = 0;
  final fitted = <Exercise>[];
  for (final x in items) {
    // 한 세트 약 40초 + 세트 사이 휴식
    final cost = x.sets * (40 + rule.restSeconds);
    if (fitted.length >= 2 && used + cost > budget) break;
    fitted.add(x);
    used += cost;
  }
  return WorkoutDay(day.title, fitted, atHome: day.atHome, removed: day.removed);
}
