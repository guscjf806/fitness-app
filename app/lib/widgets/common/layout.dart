/// 공용 부품: 화면 틀과 카드
library;

import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../common.dart';

/// 탭 밖의 화면 (뒤로가기 있는 화면)
class AppPage extends StatelessWidget {
  const AppPage({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null ? null : AppBar(title: Text(title!)),
      body: TabBody(children: children),
    );
  }
}

/// 스크롤되는 본문
class TabBody extends StatelessWidget {
  const TabBody({super.key, required this.children, this.top = AppSpace.l});

  final List<Widget> children;

  /// 위 여백. 목록을 한 화면에 많이 보여야 하는 작업 화면(운동 추가·운동 진행)은 좁게 쓴다
  final double top;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // 스크롤하면 키보드가 닫힌다 (디자인 리뷰 11/04 #1)
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(AppSpace.page, top, AppSpace.page, AppSpace.pageBottom),
      children: children,
    );
  }
}

/// 화면 아래에 붙는 버튼 띠. 위에 선을 그어 목록이 버튼 뒤에서 잘려 보이지 않게 한다 (디자인 리뷰 10/31 #1)
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.s, AppSpace.page, AppSpace.m), child: child),
        ),
      );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.accent = false, this.showArrow = false});
  final Widget child;
  final VoidCallback? onTap;
  final bool accent;

  /// 눌리는 카드임을 알리는 오른쪽 화살표. LineRow와 같은 모양 (디자인 리뷰 11/05 #6)
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            decoration: accent
                ? const BoxDecoration(
                    border: Border(
                        left: BorderSide(color: AppColors.primary, width: 4)))
                : null,
            padding: const EdgeInsets.all(14),
            child: showArrow
                ? Row(children: [
                    Expanded(child: child),
                    const SizedBox(width: AppSpace.xs),
                    const Icon(Icons.chevron_right, size: 20, color: AppColors.textSub),
                  ])
                : child,
          ),
        ),
      ),
    );
  }
}

/// 게스트 모드 안내 (탭 화면 위쪽)
class GuestBanner extends StatelessWidget {
  const GuestBanner(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accent: true,
      onTap: () => Navigator.pushNamed(context, Routes.login),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('로그인 없이 둘러보는 중', style: AppText.bodyStrong),
        Muted(text, bottom: AppSpace.xs),
        const MoreLink('로그인하기'),
      ]),
    );
  }
}
