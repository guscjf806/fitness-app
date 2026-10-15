import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../logic/tdee.dart';
import '../routes.dart';

final demoNavigatorKey = GlobalKey<NavigatorState>();

/// 목업 전용 앱 상태. 서버 없이 화면 흐름만 확인하려고 메모리에만 둔다.
final demo = DemoState();

class DemoState extends ChangeNotifier {
  /// guest(비회원) / user(일반) / member(PT 회원) / trainer(선생님)
  String role = 'guest';
  int tab = 0;
  bool continueToGenerate = false;

  // S02 몸 정보
  String sex = '남';
  String height = '175';
  String age = '30';
  String weight = '72';
  String muscle = '';
  bool muscleUnknown = false;
  String bodyFat = '';
  bool bodyFatUnknown = false;
  String goal = '감량';

  /// 칼로리 결과(S04)를 한 번이라도 봤는지
  bool calorieCalculated = false;

  // S03 강도·조건
  String currentIntensity = '중';
  String desiredIntensity = '중';
  String place = '헬스장';
  String equipment = '맨몸';
  String noise = '예';
  String minutes = '30분';
  String period = '일주일';

  // 운동·참여 기능
  final Set<int> checked = {};
  bool workoutDone = false;
  bool weightLogged = false;
  bool restMode = false;
  int freezesLeft = 1;
  bool firstLogSeen = false;
  final List<MealPost> mealPosts = [...initialMealPosts];

  // PT
  final Map<String, String> missions = {'김지아': '이번 주 운동 3회 + 단백질 챙기기'};
  String? inviteCode;
  final Set<String> savedVideos = {};

  // 내 정보
  bool pushOn = true;
  TimeOfDay pushTime = const TimeOfDay(hour: 7, minute: 30);

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  bool get loggedIn => role != 'guest';
  bool get isGuest => role == 'guest';

  String get displayName => switch (role) {
        'trainer' => '선생님',
        'guest' => '게스트님',
        _ => '지아님',
      };

  TdeeResult get tdee => calcTdee(
        sex: sex,
        heightCm: double.tryParse(height) ?? 175,
        age: int.tryParse(age) ?? 30,
        weightKg: double.tryParse(weight) ?? 72,
        bodyFatKg: bodyFatUnknown ? null : double.tryParse(bodyFat),
        currentIntensity: currentIntensity,
        goal: goal,
      );

  List<WorkoutDay> get week => place == '집' ? homeWeek : gymWeek;

  String get conditionText {
    if (place == '헬스장') return '헬스장 · $minutes';
    final where = place == '둘 다' ? '헬스장+집' : '집';
    return '$where $equipment${noise == '예' ? ' · 조용히' : ''} · $minutes';
  }

  bool get mealPostedToday => mealPosts.any((p) => p.isToday);
  bool get recordedToday => mealPostedToday || workoutDone;
  int get streak => 6 + (recordedToday ? 1 : 0);

  void switchRole(String newRole) {
    role = newRole;
    tab = 0;
    continueToGenerate = false;
    notifyListeners();
    demoNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        newRole == 'guest' ? Routes.start : Routes.main, (_) => false);
  }
}
