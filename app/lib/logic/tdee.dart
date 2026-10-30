/// TDEE 계산 (기획서 6번 '계산 규칙').
class TdeeResult {
  const TdeeResult({
    required this.bmr,
    required this.tdee,
    required this.target,
    required this.usedKatchMcArdle,
    required this.clampedToFloor,
    required this.floor,
    required this.teen,
  });

  final int bmr;
  final int tdee;
  final int target;
  final bool usedKatchMcArdle;
  final bool clampedToFloor;
  final int floor;

  /// 만 14~18세: 감량 폭을 줄이고 하한선을 높여 계산했다
  final bool teen;
}

const activityFactor = {'하': 1.375, '중': 1.55, '상': 1.725};
const goalFactor = {'감량': 0.82, '유지': 1.0, '증량': 1.12};

/// 성장기(만 14~18세) 규칙 — 초안 값, 출시 전 전문가 검토
const teenMaxAge = 18;
const teenLossFactor = 0.9; // 성인 −18% 대신 −10%
const teenFloor = {'남': 1800, '여': 1500};
const adultFloor = {'남': 1500, '여': 1200};

/// 입력 범위 (이 밖이면 다음으로 넘어가지 않는다)
const minAge = 14, maxAge = 100;
const minHeight = 120.0, maxHeight = 230.0;
const minWeight = 30.0, maxWeight = 250.0;

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
  final teen = age <= teenMaxAge;
  final factor = teen && goal == '감량' ? teenLossFactor : goalFactor[goal]!;
  final rawTarget = _round10(tdee * factor);
  final floor = (teen ? teenFloor : adultFloor)[sex]!;
  return TdeeResult(
    bmr: _round10(bmr),
    tdee: _round10(tdee),
    target: rawTarget < floor ? floor : rawTarget,
    usedKatchMcArdle: useKatch,
    clampedToFloor: rawTarget < floor,
    floor: floor,
    teen: teen,
  );
}

/// 만 14세 미만일 때의 안내 (화면에서 이 문구로 미성년 안내를 띄운다)
const underAgeError = '만 14세 이상만 이용할 수 있어요';

/// 몸 정보 입력 확인. 문제가 있으면 칸별 안내 문구를 돌려준다.
/// 무엇이 틀렸는지 알 수 있게 문장으로 쓴다 (리뷰 10/29 #2)
Map<String, String> validateBody({required String height, required String age, required String weight}) {
  final errors = <String, String>{};
  final h = double.tryParse(height), a = int.tryParse(age), w = double.tryParse(weight);
  if (h == null || h < minHeight || h > maxHeight) errors['height'] = '키는 ${minHeight.toInt()}~${maxHeight.toInt()}cm 사이로 적어 주세요';
  if (a == null) {
    errors['age'] = '나이를 숫자로 적어 주세요';
  } else if (a < minAge) {
    errors['age'] = underAgeError;
  } else if (a > maxAge) {
    errors['age'] = '나이는 $maxAge세 이하로 적어 주세요';
  }
  if (w == null || w < minWeight || w > maxWeight) errors['weight'] = '몸무게는 ${minWeight.toInt()}~${maxWeight.toInt()}kg 사이로 적어 주세요';
  return errors;
}
