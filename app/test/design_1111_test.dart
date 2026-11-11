import 'package:fitness_app/widgets/common.dart';
import 'package:flutter_test/flutter_test.dart';

/// 디자인 리뷰 11/11
void main() {
  test('#4 긴 알림 띠는 더 오래 보이고 8초를 넘지 않는다', () {
    expect(toastDuration('저장했어요'), const Duration(seconds: 4));
    expect(toastDuration('가' * 70), const Duration(seconds: 6));
    expect(toastDuration('가' * 300), const Duration(seconds: 8));
    expect(toastDuration('세트를 지웠어요', hasAction: true), const Duration(seconds: 6));
  });
}
