/// 공용 부품: 제목·안내 글자 (H1, Muted, BulletList 등)
library;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// 한글이 단어 중간(예: '받/아요')에서 줄바꿈되지 않게, 단어 안 글자 사이에
/// 보이지 않는 '줄바꿈 금지' 표시(U+2060)를 넣는다. 띄어쓰기에서만 줄이 바뀐다 (디자인 리뷰 11/03 #1)
String keepWords(String text) => text.split(' ').map((w) => w.characters.join('\u2060')).join(' ');

/// 단어 중간에서 줄이 바뀌지 않는 글 (디자인 리뷰 11/06 #3). 화면 낭독은 원문으로 읽는다
class WordText extends StatelessWidget {
  const WordText(this.text, {super.key, this.style, this.textAlign});
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(keepWords(text), semanticsLabel: text, style: style, textAlign: textAlign);
}

class H1 extends StatelessWidget {
  const H1(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: WordText(text, style: AppText.h1),
      );
}

/// 아래에서 올라오는 창(바텀시트)의 제목 (디자인 리뷰 10/28 #4)
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => WordText(text, style: AppText.title);
}

class H2 extends StatelessWidget {
  const H2(this.text, {super.key, this.top = 18});
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 8),
        child: WordText(text, style: AppText.title),
      );
}

class Muted extends StatelessWidget {
  const Muted(this.text, {super.key, this.top = 0, this.bottom = AppSpace.s, this.align});
  final String text;

  /// 위 여백. 'Padding(top: …) + Muted'로 감싸지 않게 (디자인 리뷰 11/03 #6)
  final double top;
  final double bottom;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top, bottom: bottom),
        child: Text(keepWords(text),
            semanticsLabel: text,
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

/// 고르기 버튼(Seg) 위의 질문 라벨: 굵은 제목 + 회색 설명 (디자인 리뷰 11/02 #3)
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.sub});
  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: AppText.bodyStrong),
          if (sub != null) Muted(sub!, bottom: 0),
        ]),
      );
}

/// 앞에 체크 아이콘이 붙는 목록 (혜택 안내 등) (디자인 리뷰 11/02 #5)
class BulletList extends StatelessWidget {
  const BulletList(this.items, {super.key});
  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.check_circle, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(keepWords(items[i]), semanticsLabel: items[i])),
            ]),
          ),
      ]);
}

class Disclaimer extends StatelessWidget {
  const Disclaimer({super.key, this.text = 'AI가 만든 식단과 운동 루틴은 의료 조언이 아닙니다.'});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 10), child: Muted(text));
}

String formatNumber(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
