import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/demo_state.dart';
import '../theme/app_theme.dart';
import 'exercise_figure.dart';

/// 데모 상태가 바뀌면 다시 그린다.
Widget watch(Widget Function() build) =>
    ListenableBuilder(listenable: demo, builder: (_, _) => build());

/// 아래에 잠깐 뜨는 알림. [actionLabel]을 주면 '되돌리기' 같은 버튼이 붙는다 (디자인 리뷰 10/31 #3)
void toast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) =>
    toastOn(ScaffoldMessenger.of(context), message, actionLabel: actionLabel, onAction: onAction);

/// 화면을 닫은 뒤에 띄우는 알림. 닫기 전에 잡아 둔 [messenger]로 띄운다.
/// 알림 띠는 이 함수 한 곳에서만 만든다 (디자인 리뷰 11/01 #6)
void toastOn(ScaffoldMessengerState messenger, String message, {String? actionLabel, VoidCallback? onAction}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ));
}

/// 게스트가 로그인이 필요한 기능을 누르면 이유를 알려 주고 로그인으로 안내한다.
/// [thenGenerate]가 true면 로그인 후 바로 기간 선택(S06)으로 이어진다.
void requireLogin(BuildContext context, String reason, {bool thenGenerate = false}) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SheetTitle('로그인이 필요해요'),
        const SizedBox(height: 8),
        Muted(reason),
        const Muted('게스트로 입력한 몸 정보는 로그인 후에도 그대로 이어져요.'),
        AppButton('3초 만에 로그인하기', onPressed: () {
          Navigator.pop(sheetContext);
          demo.continueToGenerate = thenGenerate;
          Navigator.pushNamed(context, Routes.login);
        }),
        AppButton('계속 둘러보기', kind: ButtonKind.soft, onPressed: () => Navigator.pop(sheetContext)),
      ]),
    ),
  );
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
        const Text('게스트로 둘러보는 중', style: AppText.bodyStrong),
        Muted(text, bottom: 4),
        const MoreLink('로그인하기'),
      ]),
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
          child: Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 12), child: child),
        ),
      );
}

/// '더 보기' 글자 링크: 글자 + 화살표 아이콘. 목록 줄의 화살표와 같은 모양 (디자인 리뷰 10/31 #2)
class MoreLink extends StatelessWidget {
  const MoreLink(this.text, {super.key, this.color = AppColors.primaryDark});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(text, style: AppText.bodyStrong.copyWith(color: color)),
        Icon(Icons.chevron_right, size: 18, color: color),
      ]);
}

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
  const TabBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: children,
    );
  }
}

class H1 extends StatelessWidget {
  const H1(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Text(text,
            style: AppText.h1),
      );
}

/// 아래에서 올라오는 창(바텀시트)의 제목 (디자인 리뷰 10/28 #4)
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.title);
}

class H2 extends StatelessWidget {
  const H2(this.text, {super.key, this.top = 18});
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 8),
        child: Text(text,
            style: AppText.title),
      );
}

class Muted extends StatelessWidget {
  const Muted(this.text, {super.key, this.bottom = 8, this.align});
  final String text;
  final double bottom;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Text(text,
            textAlign: align,
            style: AppText.caption.copyWith(color: AppColors.textSub)),
      );
}

class BigNumber extends StatelessWidget {
  const BigNumber(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: AppText.bigNumber.copyWith(color: AppColors.primaryDark));
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.accent = false});
  final Widget child;
  final VoidCallback? onTap;
  final bool accent;

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
            child: child,
          ),
        ),
      ),
    );
  }
}

enum ButtonKind { primary, soft }

class AppButton extends StatelessWidget {
  const AppButton(this.label,
      {super.key, required this.onPressed, this.kind = ButtonKind.primary, this.top = 12});
  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: FilledButton(
        onPressed: onPressed,
        style: kind == ButtonKind.soft
            ? FilledButton.styleFrom(
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.primaryDark)
            : null,
        child: Text(label),
      ),
    );
  }
}

/// 여러 개 중 하나 고르기 (예: 남/여, 상/중/하)
class Seg extends StatelessWidget {
  const Seg({super.key, required this.options, required this.value, required this.onChanged});
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _SegButton(
                    label: o, selected: o == value, onTap: () => onChanged(o)),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.small),
        onTap: onTap,
        // 손가락으로 누르기 쉽게 높이 48px 이상 (디자인 리뷰 10/30 #1)
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: selected ? AppColors.primaryDark : AppColors.text,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
          ),
        ),
      ),
    );
  }
}

/// 가로로 스크롤되는 날짜·요일 칩
class DayChips extends StatelessWidget {
  /// '화 휴식' 같은 뒷말은 그대로 두고 요일 바로 뒤에 '·오늘'을 넣는다
  String _label(int i) {
    final l = labels[i];
    if (i != today) return l;
    final space = l.indexOf(' ');
    return space < 0 ? '$l·오늘' : '${l.substring(0, space)}·오늘${l.substring(space)}';
  }

  const DayChips({super.key, required this.labels, required this.selected, required this.onSelect, this.today});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  /// 오늘인 칸. 주면 그 칩에 '·오늘'을 붙여 식단·운동 탭이 같은 모양이 된다 (리뷰 11/01 #6)
  final int? today;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(_label(i)),
                  selected: i == selected,
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                      color: i == selected ? Colors.white : AppColors.text),
                  shape: const StadiumBorder(),
                  onSelected: (_) => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 아래 구분선이 있는 한 줄
class LineRow extends StatelessWidget {
  const LineRow({super.key, required this.left, this.right, this.onTap, this.showArrow = false});
  final Widget left;
  final Widget? right;
  final VoidCallback? onTap;

  /// 오른쪽 끝에 누를 수 있다는 화살표를 붙인다 (디자인 리뷰 10/29 #3)
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(
          children: [
            Expanded(child: left),
            if (right != null) ...[const SizedBox(width: 10), right!],
            if (showArrow) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textSub),
            ],
          ],
        ),
      ),
    );
  }
}

class CheckCircle extends StatelessWidget {
  const CheckCircle(this.on, {super.key});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? AppColors.primary : null,
        border: Border.all(
            color: on ? AppColors.primary : AppColors.lineStrong, width: 2),
      ),
      child: on ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar(this.value, {super.key});
  final double value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            color: AppColors.primary,
            backgroundColor: AppColors.track,
          ),
        ),
      );
}

/// 숫자 입력칸
class NumField extends StatelessWidget {
  const NumField({super.key, required this.label, required this.value, required this.onChanged, this.hint, this.error, this.enabled = true});
  final String label;
  final String value;
  final String? hint;
  final String? error;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, hintText: hint, errorText: error, errorMaxLines: 2),
      onChanged: onChanged,
    );
  }
}

/// 운동 종목 썸네일: 동작 그림이 있으면 그림, 선생님이 직접 입력한 종목이면 첫 글자
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb(this.name, {super.key, this.size = 40});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final info = exerciseByName(name);
    if (info != null) return ExerciseFigureView(info.id, size: size, radius: AppRadius.small);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: AppColors.primaryDark, borderRadius: BorderRadius.circular(AppRadius.small)),
      child: Text(name.characters.first,
          style: AppText.bodyStrong.copyWith(color: Colors.white)),
    );
  }
}

class Disclaimer extends StatelessWidget {
  const Disclaimer({super.key, this.text = 'AI가 만든 식단과 운동 루틴은 의료 조언이 아닙니다.'});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 10), child: Muted(text));
}

/// 아픈 부위와 겹치는 운동에 붙이는 표시. 예: '무릎·허리 주의' (디자인 리뷰 10/28 #2)
class PainTag extends StatelessWidget {
  const PainTag(this.areas, {super.key});
  final List<String> areas;

  @override
  Widget build(BuildContext context) => Text('${areas.join('·')} 주의',
      style: AppText.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700));
}

/// '만드는 중' 로딩 표시: 빙글빙글 + 굵은 문구 + 회색 보조 문구 (디자인 리뷰 10/30 #5)
class LoadingView extends StatelessWidget {
  const LoadingView(this.message, {super.key, this.sub});
  final String message;
  final String? sub;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center, style: AppText.bodyStrong),
        if (sub != null) Muted(sub!, align: TextAlign.center),
      ]);
}

/// 아픈 부위와 겹치는 운동의 경고 문구 (운동 상세와 운동 진행에서 같이 쓴다)
String painPhrase(List<String> areas) => '${areas.join(', ')} 통증이 있으면 이 운동은 피하는 게 좋아요.';

/// 빨간 큰 경고 상자 (디자인 리뷰 10/28 #3)
class WarningBox extends StatelessWidget {
  const WarningBox(this.text, {super.key, this.top = 12});
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: top),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.box),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: AppText.warning.copyWith(color: AppColors.warning)),
        ),
      ]),
    );
  }
}

String formatNumber(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
