# fitness-app (운동 앱, 가칭)

## 문서

- 기획서: [docs/기획서.md](docs/기획서.md) — 기능 범위, 화면(S01~S20), DB·RLS, 계산 규칙, 개발 순서의 기준
- 프로토타입: [docs/prototype/index.html](docs/prototype/index.html) — 화면 흐름과 디자인 참고용 HTML 데모 (실제 앱 코드 아님)

## 작업 방식

- 개발자는 비전공자다. 작업 전에 계획을 쉬운 말로 설명한다
- 한 번에 한 단계씩 진행하고, 단계마다 실행해서 확인하는 방법을 알려준다
- 개발 순서는 기획서 17번을 따른다

## 지켜야 할 규칙

- 스택: Flutter + Supabase(Auth, Postgres, Storage, Edge Functions) + Claude API + FCM
- Claude API는 Edge Function에서만 호출한다. API 키를 앱에 넣지 않는다
- 모든 테이블에 RLS를 켠다
- 색과 글꼴은 테마 파일 한 곳에서만 정의한다
- 무료 사용 횟수 같은 값은 설정 파일 상수로 관리한다
- 몸 정보와 식단 사진은 로그에 남기지 않는다

## 실행·확인

- 앱 코드는 `app/` (Flutter). 실행: `cd app && flutter run -d chrome`, 테스트: `flutter test`, 점검: `flutter analyze`
- Flutter SDK 위치: `~/flutter` (PATH는 ~/.zshrc에 등록)
- 지금은 목업 단계: 데이터는 `app/lib/data/mock_data.dart`, 역할 전환은 `app/lib/state/demo_state.dart`
- 비밀 값(키, 서명 파일)은 `private/`에만 둔다. 이 폴더는 .gitignore 처리됨
- 운동 종목 데이터 `app/lib/data/exercises.dart`, `docs/운동설명_검수.md`, `supabase/migrations/20261027000000_exercises.sql`, `supabase/seed.sql`은 `tools/gen_exercises.py`로 만든다 (`python3 -I tools/gen_exercises.py tools/prototype_figures.json app/lib/data/exercises.dart docs/운동설명_검수.md supabase`). 트레이너 검수가 시작된 뒤에는 다시 실행하지 말고(검수 체크가 지워짐) 두 파일을 직접 고친다
