/// TDEE 계산 (기획서 6번 '계산 규칙').
class TdeeResult {
  const TdeeResult({
    required this.bmr,
    required this.tdee,
    required this.target,
    required this.usedKatchMcArdle,
    required this.clampedToFloor,
    required this.floor,
  });

  final int bmr;
  final int tdee;
  final int target;
  final bool usedKatchMcArdle;
  final bool clampedToFloor;
  final int floor;
}

const activityFactor = {'하': 1.375, '중': 1.55, '상': 1.725};
const goalFactor = {'감량': 0.82, '유지': 1.0, '증량': 1.12};

int _round10(double v) => (v / 10).round() * 10;

/// [sex]: '남' 또는 '여'. [bodyFatKg]가 null이면 '잘 모르겠음'.
TdeeResult calcTdee({
  required String sex,
  required double heightCm,
  required int age,
  required double weightKg,
  double? bodyFatKg,
  required String currentIntensity,
  required String goal,
}) {
  final fat = bodyFatKg;
  // 체지방량이 비었거나 체중의 60% 이상이면 입력 오류로 보고 기본 공식을 쓴다.
  final useKatch = fat != null && fat > 0 && fat < weightKg * 0.6;
  final bmr = useKatch
      ? 370 + 21.6 * (weightKg - fat)
      : 10 * weightKg + 6.25 * heightCm - 5 * age + (sex == '남' ? 5 : -161);
  final tdee = bmr * activityFactor[currentIntensity]!;
  final rawTarget = _round10(tdee * goalFactor[goal]!);
  final floor = sex == '남' ? 1500 : 1200;
  return TdeeResult(
    bmr: _round10(bmr),
    tdee: _round10(tdee),
    target: rawTarget < floor ? floor : rawTarget,
    usedKatchMcArdle: useKatch,
    clampedToFloor: rawTarget < floor,
    floor: floor,
  );
}
