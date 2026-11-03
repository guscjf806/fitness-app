import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 화면 글자에 넣은 '줄바꿈 금지' 표시(U+2060)를 빼고 비교하는 find.text (디자인 리뷰 11/03 #1)
String _plain(Widget w) => switch (w) {
      Text(data: final String d) => d,
      Text(textSpan: final InlineSpan s) => s.toPlainText(),
      EditableText() => w.controller.text,
      _ => '',
    }
        .replaceAll('⁠', '');

bool _isText(Widget w) => w is Text || w is EditableText;

Finder findText(String text) => find.byWidgetPredicate((w) => _isText(w) && _plain(w) == text, description: 'text "$text"');

Finder findTextContaining(String text) =>
    find.byWidgetPredicate((w) => _isText(w) && _plain(w).contains(text), description: 'text containing "$text"');
