// 탭 화면을 새 인스턴스로 만들어야 데모 상태가 바뀔 때 다시 그려진다.
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

import '../state/demo_state.dart';
import '../widgets/common.dart';
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
        _ => LogIntroTab(), // S12
      };

  @override
  Widget build(BuildContext context) {
    return watch(() {
      final tabs = [
        HomeTab(),
        MealTab(),
        WorkoutTab(),
        _logbookTab(),
        ProfileTab(),
      ];
      return Scaffold(
        body: SafeArea(child: tabs[demo.tab]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: demo.tab,
          onDestinationSelected: (i) => demo.update(() => demo.tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
            NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: '식단'),
            NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: '운동'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '운동일지'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '내 정보'),
          ],
        ),
      );
    });
  }
}
