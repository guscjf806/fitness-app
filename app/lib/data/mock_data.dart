/// 화면 확인용 더미 데이터. Supabase를 붙이면 실제 데이터로 바뀐다.
library;

class Food {
  const Food(this.name, this.grams, this.altName, this.altGrams);
  final String name;
  final int grams;
  final String altName;
  final int altGrams;
}

class Meal {
  const Meal(this.title, this.kcal, this.foods);
  final String title;
  final int kcal;
  final List<Food> foods;
}

const mealDays = <List<Meal>>[
  [
    Meal('아침', 570, [
      Food('오트밀', 60, '현미 시리얼', 60),
      Food('달걀', 100, '두부', 150),
      Food('바나나', 120, '사과', 150),
      Food('아몬드', 15, '호두', 15),
    ]),
    Meal('점심', 650, [
      Food('닭가슴살', 170, '소고기 우둔살', 130),
      Food('현미밥', 200, '고구마', 220),
      Food('샐러드 채소', 100, '쌈채소', 100),
      Food('올리브오일', 10, '아보카도', 50),
    ]),
    Meal('간식', 310, [
      Food('그릭요거트', 200, '무가당 플레인 요거트', 200),
      Food('블루베리', 50, '딸기', 100),
      Food('호두', 20, '아몬드', 20),
    ]),
    Meal('저녁', 530, [
      Food('연어구이', 150, '고등어구이', 150),
      Food('고구마', 200, '현미밥', 140),
      Food('브로콜리', 100, '아스파라거스', 100),
    ]),
  ],
  [
    Meal('아침', 580, [
      Food('통밀빵', 100, '호밀빵', 100),
      Food('아보카도', 70, '땅콩버터', 15),
      Food('달걀', 150, '닭가슴살', 100),
    ]),
    Meal('점심', 650, [
      Food('소고기 우둔살', 150, '닭안심', 170),
      Food('잡곡밥', 200, '고구마', 250),
      Food('비빔 채소', 150, '쌈채소', 150),
      Food('참기름', 5, '들기름', 5),
    ]),
    Meal('간식', 310, [
      Food('단백질 분말', 30, '그릭요거트', 200),
      Food('사과', 200, '배', 200),
      Food('아몬드', 15, '호두', 15),
    ]),
    Meal('저녁', 540, [
      Food('두부', 250, '닭가슴살', 150),
      Food('잡곡밥', 200, '귀리밥', 200),
      Food('나물', 150, '구운 채소', 150),
      Food('참기름', 5, '들기름', 5),
    ]),
  ],
];

class Exercise {
  const Exercise(this.name, this.amount, this.sets);
  final String name;

  /// '8개' 또는 '40초'
  final String amount;
  final int sets;
}

class WorkoutDay {
  const WorkoutDay(this.title, this.items);
  final String title;
  final List<Exercise> items;
  bool get isRest => items.isEmpty;
}

const weekdayLabels = ['월', '화', '수', '목', '금'];
const dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

const gymWeek = [
  WorkoutDay('가슴 · 삼두', [
    Exercise('벤치프레스', '8개', 4),
    Exercise('인클라인 덤벨 프레스', '10개', 3),
    Exercise('케이블 크로스오버', '12개', 3),
    Exercise('트라이셉스 푸시다운', '12개', 3),
  ]),
  WorkoutDay('등 · 이두', [
    Exercise('랫 풀다운', '10개', 4),
    Exercise('바벨 로우', '8개', 4),
    Exercise('시티드 로우', '12개', 3),
    Exercise('덤벨 컬', '12개', 3),
  ]),
  WorkoutDay('휴식', []),
  WorkoutDay('하체', [
    Exercise('바벨 스쿼트', '8개', 4),
    Exercise('루마니안 데드리프트', '10개', 3),
    Exercise('레그 프레스', '12개', 3),
    Exercise('레그 컬', '12개', 3),
  ]),
  WorkoutDay('어깨 · 복부', [
    Exercise('오버헤드 프레스', '8개', 4),
    Exercise('사이드 레터럴 레이즈', '15개', 3),
    Exercise('페이스 풀', '15개', 3),
    Exercise('플랭크', '40초', 3),
  ]),
];

const homeWeek = [
  WorkoutDay('하체 · 코어', [
    Exercise('슬로우 스쿼트', '12개', 3),
    Exercise('제자리 런지', '10개', 3),
    Exercise('힙 브릿지', '15개', 3),
    Exercise('데드버그', '10개', 3),
  ]),
  WorkoutDay('상체 · 코어', [
    Exercise('무릎 푸시업', '10개', 3),
    Exercise('슈퍼맨', '10개', 3),
    Exercise('사이드 플랭크', '20초', 3),
    Exercise('버드독', '10개', 3),
  ]),
  WorkoutDay('휴식', []),
  WorkoutDay('전신 서킷', [
    Exercise('슬로우 스쿼트', '12개', 3),
    Exercise('무릎 푸시업', '8개', 3),
    Exercise('버드독', '10개', 3),
    Exercise('플랭크', '30초', 3),
  ]),
  WorkoutDay('하체 · 상체', [
    Exercise('글루트 브릿지', '15개', 3),
    Exercise('제자리 런지', '10개', 3),
    Exercise('벽 푸시업', '12개', 3),
    Exercise('데드버그', '10개', 3),
  ]),
];

class MealPost {
  const MealPost(this.date, this.note, this.reply, {this.isToday = false});
  final String date;
  final String note;
  final String reply;
  final bool isToday;
}

const sampleMealReply =
    '단백질은 충분해요. 탄수화물은 밥 1공기로 적당합니다. 채소가 조금 부족하니 샐러드나 나물을 한 접시 더해 보세요. 이 답변은 의료 조언이 아닙니다.';

const initialMealPosts = [
  MealPost('어제 점심', '제육덮밥 1공기, 샐러드',
      '단백질은 충분해요. 밥 양이 많아서 절반만 드시면 목표 칼로리에 더 가까워요. 이 답변은 의료 조언이 아닙니다.'),
];

class LogItem {
  const LogItem(this.name, this.weight, this.reps, this.sets);
  final String name;
  final String weight;
  final String reps;
  final int sets;
}

class LogVideo {
  const LogVideo(this.name, this.daysLeft);
  final String name;
  final int daysLeft;
}

class WorkoutLog {
  const WorkoutLog(this.date, this.title, this.items, this.videos, this.comment,
      this.stamp);
  final String date;
  final String title;
  final List<LogItem> items;
  final List<LogVideo> videos;
  final String comment;
  final String stamp;
}

const workoutLogs = [
  WorkoutLog(
    '10월 6일',
    '하체',
    [
      LogItem('바벨 스쿼트', '60kg', '8개', 4),
      LogItem('루마니안 데드리프트', '50kg', '10개', 3),
      LogItem('레그 프레스', '100kg', '12개', 3),
      LogItem('TRX 로우 (직접 추가)', '체중', '12개', 3),
    ],
    [LogVideo('바벨 스쿼트 · 0:12', 23), LogVideo('루마니안 데드리프트 · 0:09', 23)],
    '스쿼트 자세가 안정됐어요. 올라올 때 무릎이 안쪽으로 모이지 않게만 신경 써 주세요.',
    '참 잘했어요',
  ),
  WorkoutLog(
    '10월 3일',
    '가슴 · 삼두',
    [
      LogItem('벤치프레스', '45kg', '8개', 4),
      LogItem('인클라인 덤벨 프레스', '16kg', '10개', 3),
      LogItem('트라이셉스 푸시다운', '20kg', '12개', 3),
    ],
    [LogVideo('벤치프레스 · 0:14', 20)],
    '벤치프레스 무게를 2.5kg 올려도 좋아요. 어깨가 말리지 않게 가슴을 열어 주세요.',
    '꾸준해요',
  ),
  WorkoutLog(
    '9월 30일',
    '등 · 이두',
    [
      LogItem('랫 풀다운', '35kg', '10개', 4),
      LogItem('시티드 로우', '30kg', '12개', 3),
      LogItem('덤벨 컬', '8kg', '12개', 3),
    ],
    [],
    '등 근육 느낌이 좋아졌어요. 당길 때 팔보다 등으로 당긴다는 느낌을 유지하세요.',
    '자세 좋아요',
  ),
];

const members = ['김지아', '이도현', '박서연'];
const exerciseNames = ['벤치프레스', '바벨 스쿼트', '랫 풀다운', '오버헤드 프레스', '데드리프트', '레그 프레스'];
const stamps = ['참 잘했어요', '꾸준해요', '자세 좋아요'];

/// 데모 달력: 2026년 10월, 오늘은 12일(월)로 가정
const demoToday = 12;
const monthDoneDays = [1, 2, 3, 5, 6, 8, 9];
const monthRestDays = [4, 7, 10, 11];
const todayEatenKcal = 1240;
