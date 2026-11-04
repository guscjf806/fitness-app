import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../data/mock_data.dart';
import '../logic/intensity.dart';
import '../logic/routine.dart';
import '../logic/tdee.dart';
import '../routes.dart';
import 'workout_session.dart';

final demoNavigatorKey = GlobalKey<NavigatorState>();

/// 목업 전용 앱 상태. 서버 없이 화면 흐름을 확인하려고 쓴다.
/// 몸 정보와 조건은 이 기기에만 저장한다 (게스트도 다시 열면 이어서 쓸 수 있게).
final demo = DemoState();

class WeightLog {
  const WeightLog(this.date, this.kg);
  final String date;
  final double kg;
}

class DemoState extends ChangeNotifier {
  /// guest(비회원) / user(일반) / member(PT 회원) / trainer(선생님)
  String role = 'guest';

  /// 시작 화면을 지나 앱 안(하단 탭)에 들어왔는지. 다시 열 때 바로 탭으로 간다.
  bool entered = false;
  int tab = 0;
  bool continueToGenerate = false;

  /// 로그인 직후 동의 화면(S05-1)을 마쳤는지
  bool consented = false;

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

  // S03-2 식단·몸 상태 (기획서 B1)
  List<String> allergies = [];
  String allergyNote = '';
  List<String> painAreas = [];
  String daysPerWeek = '3일';

  // 운동·참여 기능
  final Set<int> checked = {};
  final List<String> addedExercises = [];

  /// 직접 추가한 운동 중 체크한 것 (리뷰 10/30 #2)
  final Set<String> checkedAdded = {};

  /// 진행 중인 운동 (S23 운동 진행)
  WorkoutSession? session;
  bool workoutDone = false;
  bool restMode = false;
  int freezesLeft = 1;
  bool firstLogSeen = false;
  final List<MealPost> mealPosts = [...initialMealPosts];
  List<WeightLog> weightLogs = [];

  // AI 사용 횟수 (목업 값)
  int aiUsed = 2;

  // PT
  final Map<String, String> missions = {'김지아': '이번 주 운동 3회 + 단백질 챙기기'};

  /// 지금 로그인한 PT 회원 이름 (목업). 실제 연결 때는 계정 정보에서 가져온다 (리뷰 10/30 #7)
  String memberName = '김지아';
  String? inviteCode;
  final Set<String> savedVideos = {};

  /// 선생님이 저장한 일지 (목업, 회원별). 저장 결과가 화면에 바로 보이게 한다 (리뷰 11/04 #1)
  final Map<String, List<WorkoutLog>> sentLogs = {};

  /// 회원이 아직 열어 보지 않은 일지 (목업: 가장 최근 일지 하나로 시작)
  final Set<WorkoutLog> unseenLogs = {workoutLogs.first};

  /// 그 회원의 일지 목록 (최신이 위). 목업 일지(workoutLogs)는 처음 회원의 것으로 둔다
  List<WorkoutLog> logsOf(String member) => [
        ...?sentLogs[member],
        if (member == members.first) ...workoutLogs,
      ]..sort((a, b) => logDateKey(b.date).compareTo(logDateKey(a.date)));

  /// 그 회원의 마지막 일지 날짜. 일지가 없으면 null
  String? lastLogOf(String member) {
    final dates = [?lastLogDates[member], for (final log in logsOf(member)) log.date]
      ..sort((a, b) => logDateKey(b).compareTo(logDateKey(a)));
    return dates.isEmpty ? null : dates.first;
  }

  // 내 정보
  bool pushOn = true;
  TimeOfDay pushTime = const TimeOfDay(hour: 7, minute: 30);

  /// 목업 전용: 실패 상황 미리 보기 (목록은 demo_bar.dart의 failModes)
  String failMode = '정상';

  void update(VoidCallback change) {
    change();
    notifyListeners();
    save();
  }

  bool get loggedIn => role != 'guest';
  bool get isGuest => role == 'guest';

  /// 홈 첫 줄 인사. 로그인 안 했으면 낯선 '게스트님' 없이 (리뷰 11/04 #7)
  String get greeting => switch (role) {
        'trainer' => '안녕하세요, 선생님',
        'guest' => '안녕하세요',
        _ => '안녕하세요, 지아님',
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

  /// 지금 적용되는 강도 규칙 (처음 몇 주는 낮춰서 시작할 수 있다). 여러 화면이 같이 쓴다 (디자인 리뷰 10/31 #7)
  IntensityRule get intensityRule => intensityRules[effectiveIntensity(desired: desiredIntensity, current: currentIntensity)]!;

  /// 조건(장소·장비·소음·시간·통증)을 반영한 이번 주 루틴
  List<WorkoutDay> get week => demoWeek(
      place: place, equipment: equipment, noise: noise, minutes: minutes, painAreas: painAreas, daysPerWeek: daysPerWeek,
      desiredIntensity: desiredIntensity, currentIntensity: currentIntensity);

  String get conditionText {
    final where = switch (place) {
      '헬스장' => '헬스장',
      '둘 다' => '헬스장+집 $equipment${noise == '예' ? ' · 조용히' : ''}',
      _ => '집 $equipment${noise == '예' ? ' · 조용히' : ''}',
    };
    return '$where · $minutes · 주 $daysPerWeek';
  }

  /// 이번 주 운동하는 날 수 (쉬는 날 제외)
  int get workoutDaysThisWeek => week.where((d) => !d.isRest).length;

  bool get weightLoggedThisWeek => weightLogs.isNotEmpty;
  bool get mealPostedToday => mealPosts.any((p) => p.isToday);
  bool get recordedToday => mealPostedToday || workoutDone;
  int get streak => 6 + (recordedToday ? 1 : 0);
  /// 이번 달 무료 횟수를 다 썼는지 (실제로 다 쓴 경우와 목업의 '횟수 소진' 미리 보기)
  bool get quotaExhausted => failMode == '횟수 소진' || aiUsed >= AppConfig.freeMonthlyAiLimit;

  /// 화면에 보여 줄 이번 달 사용 횟수 (식단 올리기·내 정보가 같은 숫자를 쓴다, 리뷰 11/01 #1)
  int get aiUsedShown => quotaExhausted ? AppConfig.freeMonthlyAiLimit : aiUsed;

  void switchRole(String newRole) {
    role = newRole;
    entered = newRole != 'guest';
    // 데모 바로 바꾼 역할은 이미 가입·동의를 마친 계정으로 본다
    if (newRole != 'guest') consented = true;
    tab = 0;
    continueToGenerate = false;
    notifyListeners();
    save();
    demoNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        newRole == 'guest' ? Routes.start : Routes.main, (_) => false);
  }

  // ── 기기 저장 ─────────────────────────────────────────

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('role', role);
    await p.setBool('entered', entered);
    await p.setBool('consented', consented);
    await p.setStringList('profile', [
      sex, height, age, weight, muscle, '$muscleUnknown', bodyFat, '$bodyFatUnknown', goal,
      '$calorieCalculated', currentIntensity, desiredIntensity, place, equipment, noise, minutes,
      daysPerWeek, allergyNote,
    ]);
    await p.setStringList('allergies', allergies);
    await p.setStringList('painAreas', painAreas);
    await p.setStringList('weightLogs', [for (final w in weightLogs) '${w.date}|${w.kg}']);
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    role = p.getString('role') ?? role;
    entered = p.getBool('entered') ?? entered;
    consented = p.getBool('consented') ?? consented;
    // 동의를 마치지 않은 채 앱이 꺼졌으면 로그인하지 않은 상태로 본다 (리뷰 10/29 #1)
    if (role != 'guest' && !consented) role = 'guest';
    final f = p.getStringList('profile');
    if (f != null && f.length == 18) {
      sex = f[0];
      height = f[1];
      age = f[2];
      weight = f[3];
      muscle = f[4];
      muscleUnknown = f[5] == 'true';
      bodyFat = f[6];
      bodyFatUnknown = f[7] == 'true';
      goal = f[8];
      calorieCalculated = f[9] == 'true';
      currentIntensity = f[10];
      desiredIntensity = f[11];
      place = f[12];
      equipment = f[13];
      noise = f[14];
      minutes = f[15];
      daysPerWeek = f[16];
      allergyNote = f[17];
    }
    allergies = p.getStringList('allergies') ?? allergies;
    painAreas = p.getStringList('painAreas') ?? painAreas;
    weightLogs = [
      for (final s in p.getStringList('weightLogs') ?? <String>[])
        WeightLog(s.split('|').first, double.tryParse(s.split('|').last) ?? 0),
    ];
  }
}
