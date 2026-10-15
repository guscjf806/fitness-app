# fitness-app

운동앱 (가칭) — 1차 버전 개발 중

## 폴더 구조

- `app/` — Flutter 앱 (아이폰·안드로이드·웹)
- `docs/` — 기획서와 HTML 프로토타입
- `private/` — API 키 등 비밀 파일 보관 (GitHub에 올라가지 않음)

## 목업 실행하기

Chrome에서 바로 실행돼요 (Xcode·Android Studio 없이 가능).

```bash
cd ~/Developer/fitness-app/app && flutter run -d chrome
```

- 위쪽 "데모 보기 모드"에서 비회원 / 일반 회원 / PT 회원 / 선생님을 바꿔 가며 볼 수 있어요
- 실행 중에 코드를 고치면 터미널에서 `r`을 눌러 바로 반영해요 (`q`는 종료)

## 테스트

```bash
cd ~/Developer/fitness-app/app && flutter test
```
