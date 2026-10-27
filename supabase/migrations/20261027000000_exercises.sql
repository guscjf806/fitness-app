-- 운동 종목 목록 (기획서 6번 `exercises`). 회원·비회원 모두에게 추천하는 공용 데이터다.
-- 장소는 두 가지: gym = 헬스장 전용(바벨·머신·케이블·고정 기구), home = 집에서도 가능(맨몸·덤벨·밴드).
-- home 종목은 헬스장에서도 할 수 있으므로 헬스장 사용자에게도 추천한다.

create table public.exercises (
  id          text primary key,                       -- 영문 고유 이름 (예: 'bench')
  name        text not null unique,                   -- 한국어 이름
  body_part   text not null check (body_part in ('가슴','등','어깨','삼두','이두','하체','코어','전신')),
  equipment   text not null check (equipment in ('바벨','덤벨','밴드','머신','케이블','맨몸')),
  place       text not null check (place in ('gym','home')),
  kind        text not null check (kind in ('compound','isolation','hold')),  -- 여러 관절 / 한 관절 / 버티기·시간
  level       smallint not null check (level between 1 and 3),                -- 1 초급 · 2 중급 · 3 상급
  impact      text not null check (impact in ('low','high')),                 -- 점프 등 충격
  noise       text not null check (noise in ('quiet','loud')),                -- 층간소음
  easier_id   text references public.exercises(id),
  harder_id   text references public.exercises(id),
  avoid_for   text[] not null default '{}',           -- 이 부위가 아프면 추천하지 않음
  how_to      text[] not null check (array_length(how_to, 1) = 3),            -- 하는 방법 3단계 (트레이너 검수)
  caution     text not null,                          -- 주의할 점
  figure_id   text not null,                          -- 앱 안 동작 그림
  reviewed    boolean not null default false,         -- 트레이너 검수 완료 여부
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index exercises_place_idx on public.exercises (place);
create index exercises_body_part_idx on public.exercises (body_part);

-- 보안(RLS): 종목 목록은 개인정보가 아닌 공용 정보라 비회원(anon)도 읽을 수 있다 (게스트 예시 루틴·추천용).
-- 추가·수정·삭제 정책은 두지 않는다 → 앱에서는 아무도 못 바꾸고, 관리자(service role)와 이후 '선생님만 수정' 정책으로만 바꾼다.
alter table public.exercises enable row level security;

create policy "누구나 운동 목록을 읽을 수 있음"
  on public.exercises for select
  to anon, authenticated
  using (true);

-- 운동 기구 (구체적인 기구 목록). place: gym = 헬스장에만 있는 큰 기구, home = 집에도 둘 수 있는 소도구·집 안 물건
create table public.gear (
  id        text primary key,
  name      text not null unique,
  category  text not null check (category in ('프리웨이트','머신','케이블','벤치','고정 기구','소도구','집 안 물건')),
  place     text not null check (place in ('gym','home'))
);

-- 운동별로 필요한 기구. required = true 꼭 필요, false 있으면 좋음
create table public.exercise_gear (
  exercise_id  text not null references public.exercises(id) on delete cascade,
  gear_id      text not null references public.gear(id),
  required     boolean not null default true,
  primary key (exercise_id, gear_id)
);
create index exercise_gear_gear_idx on public.exercise_gear (gear_id);

alter table public.gear enable row level security;
alter table public.exercise_gear enable row level security;
create policy "누구나 기구 목록을 읽을 수 있음" on public.gear for select to anon, authenticated using (true);
create policy "누구나 운동별 기구를 읽을 수 있음" on public.exercise_gear for select to anon, authenticated using (true);

-- 추천 쿼리 예시 (집 · 맨몸 · 조용히 · 무릎 통증 · 초급):
-- select * from public.exercises
--  where place = 'home' and equipment = '맨몸' and impact = 'low' and noise = 'quiet'
--    and not ('무릎' = any(avoid_for)) and level <= 2;
--
-- 내가 가진 기구로 할 수 있는 운동 (예: 덤벨·매트만 있음) — 꼭 필요한 기구가 모두 내 목록에 있는 운동:
-- select e.* from public.exercises e
--  where not exists (select 1 from public.exercise_gear g
--                     where g.exercise_id = e.id and g.required and g.gear_id <> all(array['dumbbell','mat']));
