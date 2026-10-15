// 화면마다 새 인스턴스를 만들어야 데모 상태가 바뀔 때 다시 그려진다.
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

import 'screens/logbook.dart';
import 'screens/main_shell.dart';
import 'screens/meal.dart';
import 'screens/onboarding.dart';
import 'screens/profile.dart';
import 'screens/records.dart';
import 'widgets/common.dart';

/// 화면 주소. 주석의 S번호는 기획서 3번 화면 목록과 같다.
class Routes {
  static const start = '/'; // S01
  static const body = '/body'; // S02
  static const condition = '/condition'; // S03
  static const result = '/result'; // S04
  static const login = '/login'; // S05
  static const generate = '/generate'; // S06
  static const main = '/main'; // S07, S08, S11, S12/S13/S18, S15 (하단 탭)
  static const mealPost = '/meal/post'; // S09
  static const mealReply = '/meal/reply'; // S10
  static const logDetail = '/log/detail'; // S14
  static const ptCode = '/pt-code'; // S16
  static const subscribe = '/subscribe'; // S17
  static const logWrite = '/log/write'; // S19
  static const records = '/records'; // S20

  static final table = <String, WidgetBuilder>{
    start: (_) => watch(() => StartScreen()),
    body: (_) => watch(() => BodyInfoScreen()),
    condition: (_) => watch(() => ConditionScreen()),
    result: (_) => watch(() => ResultScreen()),
    login: (_) => watch(() => LoginScreen()),
    generate: (_) => watch(() => GenerateScreen()),
    main: (_) => watch(() => MainShell()),
    mealPost: (_) => watch(() => MealPostScreen()),
    mealReply: (_) => watch(() => MealReplyScreen()),
    logDetail: (_) => watch(() => LogDetailScreen()),
    ptCode: (_) => watch(() => PtCodeScreen()),
    subscribe: (_) => watch(() => SubscribeScreen()),
    logWrite: (_) => watch(() => LogWriteScreen()),
    records: (_) => watch(() => RecordsScreen()),
  };
}
