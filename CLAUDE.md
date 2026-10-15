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
