// 탭 화면을 새 인스턴스로 만들어야 데모 상태가 바뀔 때 다시 그려진다.
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

import '../state/demo_state.dart';
import '../widgets/common.dart';
import 'exercise.dart';
import 'home.dart';
import 'logbook.dart';
import 'meal.dart';
import 'profile.dart';
import 'workout.dart';

/// 하단 탭 5개: 홈 / 식단 / 운동 / 운동일지 / 내 정보
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  Widget _logbookTab() => switch (demo.role) {
        'trainer' => MemberManageTab(), // S18
        'member' => LogListTab(), // S13
        // S12. 로그인한 회원이 연결을 끊었으면 받은 일지를 계속 본다
        _ => demo.ptEnded && !demo.isGuest ? LogListTab() : LogIntroTab(),
      };

  @override
  Widget build(BuildContext context) {
    return watch(() {
      // 선생님은 식단 탭 없이, 운동 탭은 종목 찾아보기, 네 번째는 '회원 관리' (결정 d1107-4).
      // 탭 번호(demo.tab)는 그대로 두고 보이는 칸만 고른다
      final trainer = demo.role == 'trainer';
      final tabs = [
        HomeTab(),
        MealTab(),
        trainer ? ExerciseBrowseTab() : WorkoutTab(),
        _logbookTab(),
        ProfileTab(),
      ];
      final destinations = [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
        NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: '식단'),
        NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: '운동'),
        trainer
            ? NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: '회원 관리')
            : NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '운동일지'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '내 정보'),
      ];
      final visible = trainer ? const [0, 2, 3, 4] : const [0, 1, 2, 3, 4];
      final current = visible.contains(demo.tab) ? demo.tab : 0;
      return Scaffold(
        body: SafeArea(child: tabs[current]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: visible.indexOf(current),
          onDestinationSelected: (i) => demo.update(() => demo.tab = visible[i]),
          destinations: [for (final i in visible) destinations[i]],
        ),
      );
    });
  }
}
