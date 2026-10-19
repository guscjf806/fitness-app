import 'package:fitness_app/logic/tdee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('체지방량이 없으면 Mifflin-St Jeor 공식을 쓴다', () {
    // 남 175cm 30세 72kg: BMR = 720 + 1093.75 - 150 + 5 = 1668.75
    final r = calcTdee(sex: '남', heightCm: 175, age: 30, weightKg: 72, currentIntensity: '중', goal: '유지');
    expect(r.usedKatchMcArdle, isFalse);
    expect(r.bmr, 1670);
    expect(r.tdee, 2590); // 1668.75 × 1.55 = 2586.6
    expect(r.target, 2590);
  });

  test('체지방량이 있으면 Katch-McArdle 공식을 쓴다', () {
    // 370 + 21.6 × (72 - 14) = 1622.8
    final r = calcTdee(sex: '남', heightCm: 175, age: 30, weightKg: 72, bodyFatKg: 14, currentIntensity: '중', goal: '유지');
    expect(r.usedKatchMcArdle, isTrue);
    expect(r.bmr, 1620);
  });

  test('체지방량이 체중의 60% 이상이면 입력 오류로 보고 기본 공식을 쓴다', () {
    final r = calcTdee(sex: '남', heightCm: 175, age: 30, weightKg: 72, bodyFatKg: 50, currentIntensity: '중', goal: '유지');
    expect(r.usedKatchMcArdle, isFalse);
  });

  test('목표 칼로리는 안전 하한선 아래로 내려가지 않는다', () {
    // 여 150cm 60세 45kg, 강도 하, 감량 → 약 1,040kcal → 1,200kcal로 맞춤
    final r = calcTdee(sex: '여', heightCm: 150, age: 60, weightKg: 45, currentIntensity: '하', goal: '감량');
    expect(r.clampedToFloor, isTrue);
    expect(r.target, 1200);
  });

  test('만 14~18세 감량은 −10%로 줄이고 하한선을 높인다', () {
    // 남 170cm 16세 60kg, 강도 중: BMR = 600 + 1062.5 - 80 + 5 = 1587.5, TDEE = 2460.6
    final r = calcTdee(sex: '남', heightCm: 170, age: 16, weightKg: 60, currentIntensity: '중', goal: '감량');
    expect(r.teen, isTrue);
    expect(r.target, 2210); // 2460.6 × 0.9 = 2214.6 → 2210 (성인이면 × 0.82)
    final low = calcTdee(sex: '여', heightCm: 150, age: 15, weightKg: 40, currentIntensity: '하', goal: '감량');
    expect(low.target, 1500);
    expect(low.clampedToFloor, isTrue);
  });

  test('입력 범위를 벗어나면 안내한다', () {
    expect(validateBody(height: '175', age: '30', weight: '72'), isEmpty);
    expect(validateBody(height: '175', age: '13', weight: '72')['age'], '만 14세 이상');
    expect(validateBody(height: '0', age: '30', weight: '500').keys, containsAll(['height', 'weight']));
  });
}
