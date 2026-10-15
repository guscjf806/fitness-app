import 'package:flutter/material.dart';

import '../state/demo_state.dart';
import '../theme/app_theme.dart';

/// 데모 상태가 바뀌면 다시 그린다.
Widget watch(Widget Function() build) =>
    ListenableBuilder(listenable: demo, builder: (_, _) => build());

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
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
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, height: 1.3)),
      );
}

class H2 extends StatelessWidget {
  const H2(this.text, {super.key, this.top = 18});
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
            style: const TextStyle(fontSize: 13, color: AppColors.textSub)),
      );
}

class BigNumber extends StatelessWidget {
  const BigNumber(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark));
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
        borderRadius: BorderRadius.circular(14),
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
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: selected ? AppColors.primaryDark : AppColors.text,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
        ),
      ),
    );
  }
}

/// 가로로 스크롤되는 날짜·요일 칩
class DayChips extends StatelessWidget {
  const DayChips({super.key, required this.labels, required this.selected, required this.onSelect});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

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
                  label: Text(labels[i]),
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
  const LineRow({super.key, required this.left, this.right, this.onTap});
  final Widget left;
  final Widget? right;
  final VoidCallback? onTap;

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
            color: on ? AppColors.primary : const Color(0xFFCFD8D5), width: 2),
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
          borderRadius: BorderRadius.circular(9),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            color: AppColors.primary,
            backgroundColor: const Color(0xFFDBE6E3),
          ),
        ),
      );
}

/// 숫자 입력칸
class NumField extends StatelessWidget {
  const NumField({super.key, required this.label, required this.value, required this.onChanged, this.hint, this.enabled = true});
  final String label;
  final String value;
  final String? hint;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: onChanged,
    );
  }
}

/// 운동 종목 썸네일 (동작 그림은 나중에, 지금은 첫 글자)
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb(this.name, {super.key});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: AppColors.primaryDark, borderRadius: BorderRadius.circular(10)),
      child: Text(name.characters.first,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

class Disclaimer extends StatelessWidget {
  const Disclaimer({super.key, this.text = 'AI가 만든 식단과 루틴은 의료 조언이 아닙니다.'});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 10), child: Muted(text));
}

String formatNumber(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
