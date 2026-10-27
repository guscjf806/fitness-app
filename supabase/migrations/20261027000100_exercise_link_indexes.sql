-- 쉬운/어려운 동작 연결(외래 키)에 인덱스 (Supabase 성능 점검 권고)
create index exercises_easier_id_idx on public.exercises (easier_id);
create index exercises_harder_id_idx on public.exercises (harder_id);
