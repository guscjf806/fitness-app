import 'package:fitness_app/config.dart';
import 'package:fitness_app/data/mock_data.dart';
import 'package:fitness_app/state/demo_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PT 회원 무료 이용: PT 중 무료, 끝난 뒤 1주 유예, 하루 사진 10장 (사용자 결정 2026-11-19)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    demo.switchRole('member');
    demo.resetPt();
    demo.ptEnded = false;
    demo.failMode = '정상';
    demo.mealPosts.removeWhere((p) => p.isToday);
  });
  tearDown(() => demo.aiUsed = 0);

  test('PT 중에는 월 무료 횟수를 다 써도 막지 않는다', () {
    demo.aiUsed = AppConfig.freeMonthlyAiLimit + 3;
    expect(demo.ptActive, isTrue);
    expect(demo.ptFree, isTrue);
    expect(demo.quotaExhausted, isFalse);
    expect(demo.aiUsageText, 'PT 회원은 무료예요');
  });

  test('남은 PT가 0회가 되면 1주일 더 무료, 그 뒤에는 월 횟수로', () {
    demo.update(() => demo.ptLeft[demo.memberName] = 0);
    expect(demo.ptActive, isFalse);
    expect(demo.ptFree, isTrue);
    expect(demo.ptFreeUntil!.difference(DateTime.now()).inDays, AppConfig.ptGraceDays - 1);
    demo.ptFinishedAt = DateTime.now().subtract(const Duration(days: AppConfig.ptGraceDays + 1));
    expect(demo.ptFree, isFalse);
    // 재등록하면 다시 PT 중
    demo.update(() => demo.ptLeft[demo.memberName] = 10);
    expect(demo.ptFree, isTrue);
    expect(demo.ptFinishedAt, isNull);
  });

  test('무료 PT 회원은 오늘 사진 10장까지', () {
    for (var i = 0; i < AppConfig.ptDailyPhotoLimit - 1; i++) {
      demo.mealPosts.insert(0, MealPost('오늘 점심', '시험 $i', '', isToday: true));
    }
    expect(demo.photoLimitReached, isFalse);
    demo.mealPosts.insert(0, const MealPost('오늘 저녁', '시험', '', isToday: true));
    expect(demo.photoLimitReached, isTrue);
    demo.mealPosts.removeWhere((p) => p.isToday);
  });

  test('영상은 PT 중에는 계속 보관하고, PT가 끝난 날부터 30일', () {
    expect(demo.videoDaysLeft, isNull);
    demo.update(() => demo.ptLeft[demo.memberName] = 0);
    expect(demo.videoDaysLeft, AppConfig.videoKeepDays);
    demo.ptFinishedAt = DateTime.now().subtract(const Duration(days: 10));
    expect(demo.videoDaysLeft, AppConfig.videoKeepDays - 10);
  });

  test('리뷰 11/21 #6 답변을 못 받은 글은 하루 사진 수에 넣지 않는다', () {
    demo.mealPosts.insert(0, const MealPost('오늘 점심', '받음', '', isToday: true));
    final failed = MealPost('오늘 저녁', '실패', '', isToday: true, replied: false);
    final waiting = MealPost('오늘 간식', '받는 중', '', isToday: true, replied: false);
    demo.mealPosts.insertAll(0, [failed, waiting]);
    demo.replyPending.add(waiting);
    expect(demo.photosToday, 2);
    demo.replyPending.clear();
  });

  test('리뷰 11/21 #2 PT 끝난 날은 앱을 다시 켜도 남는다', () async {
    demo.update(() => demo.ptLeft[demo.memberName] = 0);
    final finished = demo.ptFinishedAt!;
    await demo.save();
    demo.ptFinishedAt = null;
    await demo.load();
    expect(demo.ptFinishedAt, finished);
  });
}
