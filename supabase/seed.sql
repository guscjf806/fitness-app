-- 자동 생성 (tools/gen_exercises.py). 운동 종목 71개.
insert into public.exercises (id, name, body_part, equipment, place, kind, level, impact, noise, avoid_for, how_to, caution, figure_id) values
  ('bench', '벤치프레스', '가슴', '바벨', 'gym', 'compound', 2, 'low', 'quiet', array['어깨', '손목']::text[], array['벤치에 누워 발을 바닥에 단단히 두고 어깨뼈를 모아요', '바를 어깨너비보다 조금 넓게 잡고 가슴 중간으로 천천히 내려요', '가슴이 바에 닿을 듯하면 숨을 내쉬며 밀어 올려요']::text[], '엉덩이가 벤치에서 뜨지 않게 하고, 무거운 무게는 보조자와 함께 해요.', 'bench'),
  ('incline', '인클라인 덤벨 프레스', '가슴', '덤벨', 'gym', 'compound', 2, 'low', 'quiet', array['어깨', '손목']::text[], array['벤치 등받이를 30~45도로 세우고 덤벨을 가슴 위로 들어요', '팔꿈치를 몸통에서 45도 정도 벌린 채 가슴 위쪽으로 내려요', '가슴 위쪽에 힘을 주며 덤벨을 모으듯 밀어 올려요']::text[], '등받이를 너무 세우면 어깨 운동이 되니 45도를 넘기지 않아요.', 'incline'),
  ('floorpress', '바닥 덤벨 프레스', '가슴', '덤벨', 'home', 'compound', 1, 'low', 'quiet', array['어깨', '손목']::text[], array['바닥에 누워 무릎을 세우고 덤벨을 가슴 위로 들어요', '팔꿈치가 바닥에 살짝 닿을 때까지 천천히 내려요', '잠깐 멈춘 뒤 가슴에 힘을 주며 밀어 올려요']::text[], '팔꿈치를 바닥에 쿵 내려놓지 말고 살짝 닿게만 해요.', 'floorpress'),
  ('crossover', '케이블 크로스오버', '가슴', '케이블', 'gym', 'isolation', 2, 'low', 'quiet', array['어깨']::text[], array['케이블 손잡이를 높은 위치에서 잡고 한 발 앞으로 나와 서요', '팔꿈치를 살짝 굽힌 채 큰 원을 그리듯 손을 몸 앞으로 모아요', '가슴을 쥐어짜듯 잠깐 멈췄다가 천천히 돌아가요']::text[], '팔을 펴고 굽히는 동작이 되지 않게 팔꿈치 각도를 그대로 유지해요.', 'crossover'),
  ('pushup', '푸시업', '가슴', '맨몸', 'home', 'compound', 2, 'low', 'quiet', array['손목', '어깨']::text[], array['손을 어깨너비보다 조금 넓게 짚고 머리부터 발끝까지 일직선을 만들어요', '팔꿈치를 몸통 쪽으로 45도 굽히며 가슴을 바닥 가까이 내려요', '바닥을 밀어내듯 올라와 처음 자세로 돌아가요']::text[], '허리가 처지거나 엉덩이가 들리지 않게 배에 힘을 줘요.', 'pushup'),
  ('kpush', '무릎 푸시업', '가슴', '맨몸', 'home', 'compound', 1, 'low', 'quiet', array['손목']::text[], array['무릎을 바닥에 대고 손은 어깨너비보다 조금 넓게 짚어요', '무릎부터 머리까지 일직선을 유지하며 가슴을 내려요', '바닥을 밀어 올라와요']::text[], '무릎이 아프면 수건이나 매트를 깔아요.', 'kpush'),
  ('wallpushup', '벽 푸시업', '가슴', '맨몸', 'home', 'compound', 1, 'low', 'quiet', array['손목']::text[], array['벽에서 한 걸음 떨어져 손을 어깨 높이로 벽에 짚어요', '몸을 일직선으로 유지하며 가슴을 벽 쪽으로 기울여요', '벽을 밀어 처음 자세로 돌아와요']::text[], '발이 미끄러지지 않는 바닥에서 해요.', 'wallpushup'),
  ('deadlift', '데드리프트', '등', '바벨', 'gym', 'compound', 3, 'low', 'loud', array['허리']::text[], array['바 앞에 서서 발을 골반너비로 벌리고 바가 발 가운데 오게 해요', '엉덩이를 뒤로 빼며 허리를 곧게 편 채 바를 잡아요', '바를 몸에 붙인 채 다리와 엉덩이로 밀며 일어서요']::text[], '등이 둥글게 말리면 바로 멈춰요. 내려놓을 때도 허리를 편 채로 내려요.', 'deadlift'),
  ('row', '바벨 로우', '등', '바벨', 'gym', 'compound', 3, 'low', 'quiet', array['허리']::text[], array['바를 잡고 무릎을 살짝 굽혀 상체를 45도 정도 숙여요', '팔꿈치를 뒤로 보내며 바를 배꼽 쪽으로 당겨요', '등에 힘을 준 채 천천히 내려요']::text[], '허리를 편 자세를 끝까지 유지하고, 반동으로 당기지 않아요.', 'row'),
  ('pullup', '풀 업', '등', '맨몸', 'gym', 'compound', 3, 'low', 'quiet', array['어깨']::text[], array['바를 어깨너비보다 조금 넓게 잡고 매달려요', '어깨를 내리고 팔꿈치를 옆구리 쪽으로 당기며 몸을 끌어올려요', '턱이 바를 넘으면 천천히 내려와요']::text[], '몸을 흔들어 반동을 쓰지 말고, 어렵다면 랫 풀다운부터 해요.', 'pullup'),
  ('lat', '랫 풀다운', '등', '머신', 'gym', 'compound', 1, 'low', 'quiet', array['어깨']::text[], array['패드에 허벅지를 고정하고 바를 어깨너비보다 넓게 잡아요', '가슴을 펴고 바를 쇄골 쪽으로 당겨요', '팔이 다 펴질 때까지 천천히 올려 보내요']::text[], '목 뒤로 당기지 않아요. 상체를 너무 젖히지 않아요.', 'lat'),
  ('seatedrow', '시티드 로우', '등', '케이블', 'gym', 'compound', 1, 'low', 'quiet', array['허리']::text[], array['발판에 발을 대고 허리를 편 채 손잡이를 잡아요', '팔꿈치를 몸에 붙인 채 손잡이를 배 쪽으로 당겨요', '어깨뼈를 모았다가 천천히 팔을 펴요']::text[], '당길 때 상체를 뒤로 크게 젖히지 않아요.', 'seatedrow'),
  ('dbrow', '덤벨 로우', '등', '덤벨', 'home', 'compound', 2, 'low', 'quiet', array['허리']::text[], array['벤치나 의자에 한 손과 한 무릎을 대고 등을 평평하게 해요', '덤벨을 든 팔의 팔꿈치를 천장 쪽으로 당겨 올려요', '등에 힘을 느끼며 천천히 내려요']::text[], '몸통을 비틀어 올리지 말고 등과 팔꿈치로 당겨요.', 'dbrow'),
  ('trxrow', 'TRX 로우', '등', '맨몸', 'gym', 'compound', 2, 'low', 'quiet', array['어깨']::text[], array['스트랩 손잡이를 잡고 몸을 뒤로 기울여 일직선을 만들어요', '팔꿈치를 옆구리로 당기며 가슴을 손잡이 쪽으로 끌어올려요', '몸이 꺾이지 않게 천천히 돌아가요']::text[], '발을 앞으로 옮길수록 어려워져요. 처음에는 몸을 조금만 기울여요.', 'trxrow'),
  ('facepull', '페이스 풀', '어깨', '케이블', 'gym', 'isolation', 1, 'low', 'quiet', array['어깨']::text[], array['케이블을 얼굴 높이에 두고 로프 손잡이를 잡아요', '팔꿈치를 높게 든 채 로프를 얼굴 쪽으로 당기며 양손을 벌려요', '어깨 뒤쪽에 힘을 느끼고 천천히 돌아가요']::text[], '무게를 가볍게 하고, 허리를 젖혀서 당기지 않아요.', 'facepull'),
  ('ohp', '오버헤드 프레스', '어깨', '바벨', 'gym', 'compound', 3, 'low', 'quiet', array['어깨', '허리']::text[], array['바를 쇄골 앞에 두고 어깨너비로 잡아 서요', '배와 엉덩이에 힘을 주고 바를 머리 위로 똑바로 밀어 올려요', '팔이 다 펴지면 천천히 쇄골 앞으로 내려요']::text[], '허리를 뒤로 젖히며 밀지 않아요.', 'ohp'),
  ('latraise', '사이드 레터럴 레이즈', '어깨', '덤벨', 'home', 'isolation', 1, 'low', 'quiet', array['어깨']::text[], array['덤벨을 양손에 들고 팔꿈치를 살짝 굽혀 서요', '팔꿈치가 어깨 높이에 올 때까지 옆으로 들어 올려요', '천천히 내려요']::text[], '어깨가 귀 쪽으로 으쓱 올라가지 않게 해요. 가벼운 무게로 해요.', 'latraise'),
  ('pushdown', '트라이셉스 푸시다운', '삼두', '케이블', 'gym', 'isolation', 1, 'low', 'quiet', array['손목']::text[], array['높은 케이블 손잡이를 잡고 팔꿈치를 옆구리에 붙여요', '팔꿈치는 고정한 채 손잡이를 아래로 눌러 팔을 펴요', '팔 뒤쪽에 힘을 느끼고 천천히 올려요']::text[], '팔꿈치가 앞뒤로 움직이지 않게 고정해요.', 'pushdown'),
  ('kickback', '트라이셉스 킥백', '삼두', '덤벨', 'home', 'isolation', 2, 'low', 'quiet', array['허리']::text[], array['상체를 숙이고 덤벨을 든 팔의 팔꿈치를 옆구리 높이로 들어요', '팔꿈치는 고정한 채 팔을 뒤로 쭉 펴요', '천천히 굽혀 돌아와요']::text[], '허리를 편 자세를 유지해요.', 'kickback'),
  ('dbcurl', '덤벨 컬', '이두', '덤벨', 'home', 'isolation', 1, 'low', 'quiet', array['손목']::text[], array['덤벨을 양손에 들고 팔꿈치를 옆구리에 붙여 서요', '팔꿈치를 고정한 채 덤벨을 어깨 쪽으로 감아 올려요', '천천히 내려 팔을 거의 다 펴요']::text[], '몸을 흔들어 반동으로 올리지 않아요.', 'dbcurl'),
  ('squat', '스쿼트', '하체', '바벨', 'gym', 'compound', 3, 'low', 'loud', array['무릎', '허리']::text[], array['바를 등 위쪽에 얹고 발을 어깨너비로 벌려요', '엉덩이를 뒤로 빼며 허벅지가 바닥과 나란해질 때까지 앉아요', '발바닥 전체로 바닥을 밀며 일어서요']::text[], '무릎이 안쪽으로 모이지 않게 하고, 허리를 편 채 내려가요.', 'squat'),
  ('goblet', '고블릿 스쿼트', '하체', '덤벨', 'home', 'compound', 1, 'low', 'quiet', array['무릎']::text[], array['덤벨 한쪽 끝을 가슴 앞에 세워 들어요', '가슴을 편 채 엉덩이를 뒤로 빼며 앉아요', '발뒤꿈치로 밀며 일어서요']::text[], '무릎과 발끝이 같은 방향을 보게 해요.', 'goblet'),
  ('lunge', '제자리 런지', '하체', '맨몸', 'home', 'compound', 2, 'low', 'quiet', array['무릎']::text[], array['한 발을 앞으로, 한 발을 뒤로 두고 서요', '뒷무릎이 바닥에 닿을 듯할 때까지 곧게 내려가요', '앞발로 밀며 올라와요. 반대쪽도 같은 횟수로 해요']::text[], '앞무릎이 발끝보다 크게 나가지 않게 하고, 상체를 세워요.', 'lunge'),
  ('bulg', '한 다리 스플릿 스쿼트', '하체', '덤벨', 'home', 'compound', 3, 'low', 'quiet', array['무릎']::text[], array['뒤에 둔 의자나 벤치에 한 발 등을 올려요', '앞다리 무릎을 굽혀 곧게 내려가요', '앞발 뒤꿈치로 밀며 올라와요']::text[], '균형이 어려우면 벽을 잡고 해요.', 'bulg'),
  ('rdl', '루마니안 데드리프트', '하체', '바벨', 'gym', 'compound', 2, 'low', 'quiet', array['허리']::text[], array['바를 허벅지 앞에 들고 무릎을 살짝 굽혀 서요', '허리를 편 채 엉덩이를 뒤로 빼며 바를 정강이 쪽으로 내려요', '허벅지 뒤쪽이 당기면 엉덩이를 앞으로 밀며 일어서요']::text[], '등이 둥글게 말리기 전까지만 내려가요.', 'rdl'),
  ('legpress', '레그 프레스', '하체', '머신', 'gym', 'compound', 1, 'low', 'quiet', array['무릎']::text[], array['등과 엉덩이를 등받이에 붙이고 발판에 발을 어깨너비로 둬요', '무릎을 굽혀 발판을 천천히 내려요', '발바닥 전체로 밀어 올리되 무릎을 끝까지 잠그지 않아요']::text[], '엉덩이가 등받이에서 뜰 만큼 깊이 내리지 않아요.', 'legpress'),
  ('legcurl', '레그 컬', '하체', '머신', 'gym', 'isolation', 1, 'low', 'quiet', array['무릎']::text[], array['머신에 엎드려 발목 뒤에 패드를 맞춰요', '발뒤꿈치를 엉덩이 쪽으로 감아 올려요', '천천히 내려요']::text[], '엉덩이가 들리지 않게 배를 패드에 붙여요.', 'legcurl'),
  ('bridge', '힙 브릿지', '하체', '맨몸', 'home', 'compound', 1, 'low', 'quiet', array['허리']::text[], array['누워서 무릎을 세우고 발을 골반너비로 둬요', '엉덩이를 조이며 어깨부터 무릎까지 일직선이 되게 들어 올려요', '잠깐 멈췄다가 천천히 내려요']::text[], '허리를 꺾어 올리지 말고 엉덩이 힘으로 올려요.', 'bridge'),
  ('hipthrust', '힙 쓰러스트', '하체', '맨몸', 'home', 'compound', 2, 'low', 'quiet', array['허리']::text[], array['벤치에 등 위쪽을 기대고 무릎을 세워 앉아요', '엉덩이를 조이며 몸통이 바닥과 나란해질 때까지 들어 올려요', '천천히 내려요']::text[], '턱을 당겨 시선을 앞으로 두면 허리가 덜 꺾여요.', 'hipthrust'),
  ('calfraise', '카프 레이즈', '하체', '맨몸', 'home', 'isolation', 1, 'low', 'quiet', array['발목']::text[], array['벽을 가볍게 잡고 발을 골반너비로 벌려 서요', '발뒤꿈치를 최대한 높이 들어 올려요', '천천히 내려요']::text[], '반동 없이 천천히 오르내려요.', 'calfraise'),
  ('jumpsquat', '점프 스쿼트', '하체', '맨몸', 'home', 'compound', 2, 'high', 'loud', array['무릎', '발목']::text[], array['발을 어깨너비로 벌리고 스쿼트 자세로 앉아요', '바닥을 힘껏 밀며 위로 뛰어올라요', '무릎을 살짝 굽히며 부드럽게 착지하고 바로 다음 동작으로 이어가요']::text[], '층간소음이 있고 무릎에 부담이 커요. 착지는 발 앞쪽부터 조용히 해요.', 'jumpsquat'),
  ('jumplunge', '점프 런지', '하체', '맨몸', 'home', 'compound', 3, 'high', 'loud', array['무릎', '발목']::text[], array['런지 자세로 내려가요', '위로 뛰어오르며 공중에서 다리를 바꿔요', '반대 다리가 앞으로 온 런지 자세로 부드럽게 착지해요']::text[], '층간소음이 있고 무릎에 부담이 커요. 균형이 흔들리면 일반 런지로 바꿔요.', 'jumplunge'),
  ('burpee', '버피', '전신', '맨몸', 'home', 'compound', 3, 'high', 'loud', array['무릎', '손목', '허리']::text[], array['서 있다가 쪼그려 앉아 손을 바닥에 짚어요', '두 발을 뒤로 뻗어 푸시업 자세를 만들었다가 다시 당겨 와요', '일어서며 가볍게 뛰어올라요']::text[], '층간소음이 있어요. 힘들면 점프와 푸시업을 빼고 해요.', 'burpee'),
  ('mclimber', '마운틴 클라이머', '코어', '맨몸', 'home', 'isolation', 2, 'high', 'loud', array['손목']::text[], array['푸시업 자세로 손을 어깨 아래에 짚어요', '한쪽 무릎을 가슴 쪽으로 당겼다가 돌려놓아요', '다리를 번갈아 빠르게 반복해요']::text[], '엉덩이가 들리지 않게 하고, 소음이 걱정되면 천천히 해요.', 'mclimber'),
  ('plank', '플랭크', '코어', '맨몸', 'home', 'hold', 1, 'low', 'quiet', array['허리', '손목']::text[], array['팔꿈치를 어깨 아래에 대고 엎드려요', '발끝으로 몸을 들어 머리부터 발끝까지 일직선을 만들어요', '배와 엉덩이에 힘을 준 채 정해진 시간만큼 버텨요']::text[], '허리가 처지면 시간을 줄여요. 숨은 참지 말고 고르게 쉬어요.', 'plank'),
  ('sideplank', '사이드 플랭크', '코어', '맨몸', 'home', 'hold', 2, 'low', 'quiet', array['어깨', '허리']::text[], array['옆으로 누워 팔꿈치를 어깨 바로 아래에 대요', '엉덩이를 들어 머리부터 발까지 일직선을 만들어요', '정해진 시간만큼 버티고 반대쪽도 해요']::text[], '어렵다면 아래쪽 무릎을 바닥에 대고 해요.', 'sideplank'),
  ('deadbug', '데드버그', '코어', '맨몸', 'home', 'isolation', 1, 'low', 'quiet', '{}'::text[], array['누워서 팔을 천장으로 뻗고 무릎을 90도로 들어요', '허리를 바닥에 붙인 채 한쪽 팔과 반대쪽 다리를 천천히 뻗어요', '돌아와서 반대쪽도 해요']::text[], '허리가 바닥에서 뜨면 범위를 줄여요.', 'deadbug'),
  ('birddog', '버드독', '코어', '맨몸', 'home', 'isolation', 1, 'low', 'quiet', array['손목']::text[], array['네발 자세로 손은 어깨 아래, 무릎은 골반 아래에 둬요', '한쪽 팔과 반대쪽 다리를 바닥과 나란하게 뻗어요', '잠깐 멈췄다가 돌아와서 반대쪽도 해요']::text[], '몸통이 옆으로 기울지 않게 천천히 해요.', 'birddog'),
  ('superman', '슈퍼맨', '코어', '맨몸', 'home', 'isolation', 2, 'low', 'quiet', array['허리', '목']::text[], array['엎드려 팔을 머리 위로 뻗어요', '팔과 다리를 동시에 바닥에서 살짝 들어 올려요', '2초 멈췄다가 천천히 내려요']::text[], '허리 통증이 있으면 하지 않아요. 고개를 너무 들지 않아요.', 'superman'),
  ('bwsquat', '맨몸 스쿼트', '하체', '맨몸', 'home', 'compound', 1, 'low', 'quiet', array['무릎']::text[], array['발을 어깨너비로 벌리고 팔을 앞으로 뻗어 서요', '엉덩이를 뒤로 빼며 3초 동안 천천히 앉아요', '허벅지가 바닥과 나란해지면 발바닥으로 밀며 일어서요']::text[], '무릎이 안쪽으로 모이지 않게 하고, 아프면 앉는 깊이를 줄여요.', 'squat'),
  ('dbrdl', '덤벨 루마니안 데드리프트', '하체', '덤벨', 'home', 'compound', 2, 'low', 'quiet', array['허리']::text[], array['덤벨을 허벅지 앞에 들고 무릎을 살짝 굽혀 서요', '허리를 편 채 엉덩이를 뒤로 빼며 덤벨을 정강이 쪽으로 내려요', '허벅지 뒤쪽이 당기면 엉덩이를 앞으로 밀며 일어서요']::text[], '등이 둥글게 말리기 전까지만 내려가요. 덤벨을 바닥에 떨어뜨리지 않게 해요.', 'rdl'),
  ('bandrow', '밴드 로우', '등', '밴드', 'home', 'compound', 1, 'low', 'quiet', array['허리']::text[], array['밴드를 기둥이나 문에 고정하고 양 끝을 잡아요', '팔꿈치를 몸에 붙인 채 밴드를 배 쪽으로 당겨요', '어깨뼈를 모았다가 천천히 팔을 펴요']::text[], '밴드가 단단히 고정됐는지 먼저 확인해요.', 'seatedrow'),
  ('bandfacepull', '밴드 페이스 풀', '어깨', '밴드', 'home', 'isolation', 1, 'low', 'quiet', array['어깨']::text[], array['밴드를 얼굴 높이에 고정하고 양 끝을 잡아요', '팔꿈치를 높게 든 채 밴드를 얼굴 쪽으로 당기며 양손을 벌려요', '어깨 뒤쪽에 힘을 느끼고 천천히 돌아가요']::text[], '밴드가 튕겨 얼굴에 맞지 않게 천천히 돌아가요.', 'facepull'),
  ('dbpress', '덤벨 숄더 프레스', '어깨', '덤벨', 'home', 'compound', 2, 'low', 'quiet', array['어깨', '허리']::text[], array['덤벨을 어깨 높이로 들고 서거나 의자에 앉아요', '배에 힘을 주고 덤벨을 머리 위로 밀어 올려요', '팔이 다 펴지면 천천히 어깨 높이로 내려요']::text[], '허리를 뒤로 젖히며 밀지 않아요.', 'ohp'),
  ('chestpress', '체스트 프레스 머신', '가슴', '머신', 'gym', 'compound', 1, 'low', 'quiet', array['어깨', '손목']::text[], array['등을 등받이에 붙이고 손잡이가 가슴 중간 높이에 오게 의자를 맞춰요', '가슴에 힘을 주며 손잡이를 앞으로 밀어요', '팔이 거의 펴지면 천천히 돌아와요']::text[], '어깨가 앞으로 말리지 않게 가슴을 펴고 해요.', 'bench'),
  ('pecdeck', '펙 덱 플라이', '가슴', '머신', 'gym', 'isolation', 1, 'low', 'quiet', array['어깨']::text[], array['등을 등받이에 붙이고 손잡이를 어깨 높이로 잡아요', '팔꿈치를 살짝 굽힌 채 양팔을 가슴 앞으로 모아요', '가슴이 늘어나는 느낌이 들 때까지 천천히 벌려요']::text[], '팔을 너무 뒤로 벌리면 어깨에 무리가 가요.', 'crossover'),
  ('shoulderpressm', '숄더 프레스 머신', '어깨', '머신', 'gym', 'compound', 1, 'low', 'quiet', array['어깨']::text[], array['손잡이가 어깨 높이에 오게 의자를 맞추고 앉아요', '배에 힘을 주고 손잡이를 머리 위로 밀어 올려요', '팔이 거의 펴지면 천천히 내려요']::text[], '허리를 등받이에서 떼지 않아요.', 'ohp'),
  ('legext', '레그 익스텐션', '하체', '머신', 'gym', 'isolation', 1, 'low', 'quiet', array['무릎']::text[], array['의자에 앉아 발목 앞에 패드를 맞춰요', '허벅지 앞쪽에 힘을 주며 무릎을 펴요', '끝에서 1초 멈췄다가 천천히 내려요']::text[], '무릎이 아프면 무게를 줄이거나 범위를 줄여요.', 'legcurl'),
  ('hacksquat', '핵 스쿼트', '하체', '머신', 'gym', 'compound', 2, 'low', 'quiet', array['무릎', '허리']::text[], array['등을 패드에 붙이고 어깨를 받침 아래에 넣어요', '발을 어깨너비로 두고 허벅지가 나란해질 때까지 앉아요', '발바닥 전체로 밀며 일어서요']::text[], '무릎을 끝까지 잠그지 않아요.', 'squat'),
  ('smithsquat', '스미스 머신 스쿼트', '하체', '머신', 'gym', 'compound', 2, 'low', 'quiet', array['무릎', '허리']::text[], array['바를 등 위쪽에 얹고 발을 살짝 앞으로 둬요', '엉덩이를 뒤로 빼며 허벅지가 나란해질 때까지 앉아요', '발바닥으로 밀며 일어서요']::text[], '안전 고리 높이를 먼저 맞춰 두세요.', 'squat'),
  ('tbarrow', '티바 로우', '등', '바벨', 'gym', 'compound', 2, 'low', 'quiet', array['허리']::text[], array['손잡이를 잡고 무릎을 굽혀 상체를 45도 숙여요', '팔꿈치를 뒤로 보내며 손잡이를 배 쪽으로 당겨요', '등에 힘을 준 채 천천히 내려요']::text[], '허리를 편 자세를 끝까지 지켜요.', 'row'),
  ('chinup', '친업', '등', '맨몸', 'gym', 'compound', 3, 'low', 'quiet', array['어깨']::text[], array['바를 어깨너비로, 손바닥이 나를 보게 잡고 매달려요', '팔꿈치를 옆구리로 당기며 몸을 끌어올려요', '턱이 바를 넘으면 천천히 내려와요']::text[], '반동을 쓰지 말고, 어렵다면 랫 풀다운부터 해요.', 'pullup'),
  ('cablecurl', '케이블 컬', '이두', '케이블', 'gym', 'isolation', 1, 'low', 'quiet', array['손목']::text[], array['낮은 케이블 손잡이를 잡고 팔꿈치를 옆구리에 붙여요', '팔꿈치를 고정한 채 손잡이를 어깨 쪽으로 감아 올려요', '천천히 내려 팔을 거의 다 펴요']::text[], '몸을 뒤로 젖혀 반동으로 올리지 않아요.', 'dbcurl'),
  ('hipabd', '힙 어브덕션 머신', '하체', '머신', 'gym', 'isolation', 1, 'low', 'quiet', '{}'::text[], array['머신에 앉아 무릎 바깥쪽에 패드를 맞춰요', '엉덩이 옆쪽에 힘을 주며 다리를 바깥으로 벌려요', '천천히 모아요']::text[], '반동 없이 천천히 해요.', 'hipthrust'),
  ('reverselunge', '리버스 런지', '하체', '맨몸', 'home', 'compound', 1, 'low', 'quiet', array['무릎']::text[], array['발을 모으고 서서 한 발을 크게 뒤로 내딛어요', '뒷무릎이 바닥에 닿을 듯할 때까지 내려가요', '앞발로 밀며 처음 자세로 돌아와요. 반대쪽도 해요']::text[], '앞으로 내딛는 런지보다 무릎 부담이 적어요. 상체는 세워요.', 'lunge'),
  ('stepup', '스텝업', '하체', '맨몸', 'home', 'compound', 1, 'low', 'quiet', array['무릎']::text[], array['튼튼한 의자나 계단 앞에 서요', '한 발을 올리고 그 발로 밀어 몸을 올려요', '천천히 내려와요. 반대쪽도 해요']::text[], '흔들리지 않는 의자나 계단에서만 해요.', 'lunge'),
  ('wallsit', '월 싯', '하체', '맨몸', 'home', 'hold', 1, 'low', 'quiet', array['무릎']::text[], array['벽에 등을 대고 서요', '허벅지가 바닥과 나란해질 때까지 벽을 따라 내려가요', '정해진 시간만큼 버텨요']::text[], '무릎이 아프면 덜 앉아서 해요.', 'squat'),
  ('sumosquat', '덤벨 스모 스쿼트', '하체', '덤벨', 'home', 'compound', 1, 'low', 'quiet', array['무릎']::text[], array['발을 어깨너비보다 넓게, 발끝은 바깥으로 두고 덤벨을 다리 사이로 들어요', '가슴을 편 채 엉덩이를 뒤로 빼며 앉아요', '허벅지 안쪽에 힘을 주며 일어서요']::text[], '무릎이 발끝 방향으로 나가게 해요.', 'goblet'),
  ('singlebridge', '싱글 레그 브릿지', '하체', '맨몸', 'home', 'compound', 2, 'low', 'quiet', array['허리']::text[], array['누워서 한쪽 무릎을 세우고 다른 다리는 뻗어요', '세운 발로 밀며 엉덩이를 들어 올려요', '천천히 내려요. 반대쪽도 해요']::text[], '골반이 한쪽으로 기울지 않게 해요.', 'bridge'),
  ('donkeykick', '덩키 킥', '하체', '맨몸', 'home', 'isolation', 1, 'low', 'quiet', '{}'::text[], array['네발 자세로 손은 어깨 아래, 무릎은 골반 아래에 둬요', '무릎을 굽힌 채 한쪽 다리를 천장 쪽으로 들어요', '엉덩이에 힘을 주고 천천히 내려요. 반대쪽도 해요']::text[], '허리를 꺾지 말고 엉덩이 힘으로 들어요.', 'birddog'),
  ('chairdip', '의자 딥스', '삼두', '맨몸', 'home', 'compound', 2, 'low', 'quiet', array['어깨', '손목']::text[], array['튼튼한 의자 끝에 손을 짚고 엉덩이를 앞으로 빼요', '팔꿈치를 뒤로 굽히며 몸을 내려요', '팔 뒤쪽 힘으로 밀어 올라와요']::text[], '어깨가 아프면 내려가는 깊이를 줄여요. 바퀴 달린 의자는 쓰지 않아요.', 'kickback'),
  ('dbfly', '덤벨 플라이', '가슴', '덤벨', 'home', 'isolation', 1, 'low', 'quiet', array['어깨']::text[], array['바닥이나 벤치에 누워 덤벨을 가슴 위로 들어요', '팔꿈치를 살짝 굽힌 채 양팔을 옆으로 천천히 벌려요', '가슴을 모으듯 덤벨을 다시 모아요']::text[], '팔을 너무 깊이 내리지 않아요.', 'floorpress'),
  ('hammercurl', '해머 컬', '이두', '덤벨', 'home', 'isolation', 1, 'low', 'quiet', array['손목']::text[], array['덤벨을 손바닥이 마주 보게 들고 서요', '팔꿈치를 고정한 채 덤벨을 어깨 쪽으로 올려요', '천천히 내려요']::text[], '손목을 꺾지 말고 일자로 유지해요.', 'dbcurl'),
  ('bandpulldown', '밴드 랫 풀다운', '등', '밴드', 'home', 'compound', 1, 'low', 'quiet', array['어깨']::text[], array['밴드를 문 위쪽에 고정하고 무릎을 꿇고 앉아요', '팔꿈치를 옆구리 쪽으로 당겨 밴드를 가슴 쪽으로 내려요', '천천히 팔을 펴요']::text[], '밴드가 단단히 고정됐는지 먼저 확인해요.', 'lat'),
  ('bandpress', '밴드 체스트 프레스', '가슴', '밴드', 'home', 'compound', 1, 'low', 'quiet', array['어깨']::text[], array['밴드를 등 뒤 기둥에 고정하고 양 끝을 잡아요', '가슴 높이에서 팔을 앞으로 밀어 펴요', '천천히 돌아와요']::text[], '밴드가 튕기지 않게 천천히 돌아와요.', 'crossover'),
  ('bandpullapart', '밴드 풀 어파트', '어깨', '밴드', 'home', 'isolation', 1, 'low', 'quiet', '{}'::text[], array['밴드를 어깨너비로 잡고 팔을 앞으로 뻗어요', '어깨뼈를 모으며 밴드를 양옆으로 벌려요', '천천히 돌아와요']::text[], '어깨가 으쓱 올라가지 않게 해요.', 'facepull'),
  ('crunch', '크런치', '코어', '맨몸', 'home', 'isolation', 1, 'low', 'quiet', array['목', '허리']::text[], array['누워서 무릎을 세우고 손은 가슴 위에 둬요', '배에 힘을 주며 어깨를 바닥에서 살짝 들어요', '천천히 내려요']::text[], '손으로 목을 당기지 않아요.', 'deadbug'),
  ('legraise', '레그 레이즈', '코어', '맨몸', 'home', 'isolation', 2, 'low', 'quiet', array['허리']::text[], array['누워서 손을 엉덩이 옆에 두고 다리를 뻗어요', '허리를 바닥에 붙인 채 다리를 천장 쪽으로 들어요', '바닥에 닿기 전까지 천천히 내려요']::text[], '허리가 뜨면 무릎을 굽혀서 해요.', 'deadbug'),
  ('russiantwist', '러시안 트위스트', '코어', '맨몸', 'home', 'isolation', 2, 'low', 'quiet', array['허리']::text[], array['앉아서 무릎을 세우고 상체를 살짝 뒤로 기울여요', '손을 모은 채 몸통을 왼쪽으로 돌려요', '오른쪽으로 번갈아 돌려요']::text[], '허리가 아프면 발을 바닥에 댄 채 해요.', 'deadbug'),
  ('stepjack', '스텝 잭', '전신', '맨몸', 'home', 'hold', 1, 'low', 'quiet', '{}'::text[], array['발을 모으고 서요', '한 발을 옆으로 내딛으며 두 팔을 머리 위로 올려요', '돌아와서 반대쪽으로 번갈아 해요']::text[], '점프 없이 하는 점핑 잭이라 층간소음 걱정이 없어요.', 'lunge'),
  ('jumpingjack', '점핑 잭', '전신', '맨몸', 'home', 'hold', 1, 'high', 'loud', array['무릎', '발목']::text[], array['발을 모으고 서요', '뛰면서 다리를 벌리고 두 팔을 머리 위로 올려요', '뛰면서 처음 자세로 돌아와요']::text[], '층간소음이 있어요. 발 앞쪽으로 부드럽게 착지해요.', 'jumpsquat')
on conflict (id) do nothing;

-- 쉬운/어려운 동작 연결 (모든 행이 들어간 뒤에 연결한다)
update public.exercises set easier_id = 'floorpress', harder_id = null where id = 'incline';
update public.exercises set easier_id = null, harder_id = 'incline' where id = 'floorpress';
update public.exercises set easier_id = 'kpush', harder_id = null where id = 'pushup';
update public.exercises set easier_id = 'wallpushup', harder_id = 'pushup' where id = 'kpush';
update public.exercises set easier_id = null, harder_id = 'kpush' where id = 'wallpushup';
update public.exercises set easier_id = 'rdl', harder_id = null where id = 'deadlift';
update public.exercises set easier_id = 'dbrow', harder_id = null where id = 'row';
update public.exercises set easier_id = 'lat', harder_id = null where id = 'pullup';
update public.exercises set easier_id = null, harder_id = 'pullup' where id = 'lat';
update public.exercises set easier_id = null, harder_id = 'row' where id = 'seatedrow';
update public.exercises set easier_id = null, harder_id = 'row' where id = 'dbrow';
update public.exercises set easier_id = null, harder_id = 'pullup' where id = 'trxrow';
update public.exercises set easier_id = 'goblet', harder_id = null where id = 'squat';
update public.exercises set easier_id = null, harder_id = 'squat' where id = 'goblet';
update public.exercises set easier_id = null, harder_id = 'jumplunge' where id = 'lunge';
update public.exercises set easier_id = 'lunge', harder_id = null where id = 'bulg';
update public.exercises set easier_id = null, harder_id = 'deadlift' where id = 'rdl';
update public.exercises set easier_id = null, harder_id = 'hipthrust' where id = 'bridge';
update public.exercises set easier_id = 'bridge', harder_id = null where id = 'hipthrust';
update public.exercises set easier_id = 'goblet', harder_id = null where id = 'jumpsquat';
update public.exercises set easier_id = 'lunge', harder_id = null where id = 'jumplunge';
update public.exercises set easier_id = 'mclimber', harder_id = null where id = 'burpee';
update public.exercises set easier_id = 'plank', harder_id = 'burpee' where id = 'mclimber';
update public.exercises set easier_id = 'deadbug', harder_id = 'mclimber' where id = 'plank';
update public.exercises set easier_id = 'plank', harder_id = null where id = 'sideplank';
update public.exercises set easier_id = null, harder_id = 'plank' where id = 'deadbug';
update public.exercises set easier_id = 'birddog', harder_id = null where id = 'superman';
update public.exercises set easier_id = null, harder_id = 'jumpsquat' where id = 'bwsquat';
update public.exercises set easier_id = null, harder_id = 'rdl' where id = 'dbrdl';
update public.exercises set easier_id = null, harder_id = 'dbrow' where id = 'bandrow';
update public.exercises set easier_id = null, harder_id = 'ohp' where id = 'dbpress';
update public.exercises set easier_id = null, harder_id = 'bench' where id = 'chestpress';
update public.exercises set easier_id = null, harder_id = 'ohp' where id = 'shoulderpressm';
update public.exercises set easier_id = 'legpress', harder_id = null where id = 'hacksquat';
update public.exercises set easier_id = 'goblet', harder_id = 'squat' where id = 'smithsquat';
update public.exercises set easier_id = 'seatedrow', harder_id = null where id = 'tbarrow';
update public.exercises set easier_id = 'lat', harder_id = null where id = 'chinup';
update public.exercises set easier_id = 'lunge', harder_id = 'bulg' where id = 'reverselunge';
update public.exercises set easier_id = null, harder_id = 'bulg' where id = 'stepup';
update public.exercises set easier_id = null, harder_id = 'bwsquat' where id = 'wallsit';
update public.exercises set easier_id = 'bwsquat', harder_id = null where id = 'sumosquat';
update public.exercises set easier_id = 'bridge', harder_id = 'hipthrust' where id = 'singlebridge';
update public.exercises set easier_id = null, harder_id = 'singlebridge' where id = 'donkeykick';
update public.exercises set easier_id = null, harder_id = 'pullup' where id = 'bandpulldown';
update public.exercises set easier_id = 'pushup', harder_id = null where id = 'bandpress';
update public.exercises set easier_id = null, harder_id = 'legraise' where id = 'crunch';
update public.exercises set easier_id = 'crunch', harder_id = null where id = 'legraise';
update public.exercises set easier_id = 'crunch', harder_id = null where id = 'russiantwist';
update public.exercises set easier_id = null, harder_id = 'jumpingjack' where id = 'stepjack';
update public.exercises set easier_id = 'stepjack', harder_id = null where id = 'jumpingjack';

-- 운동 기구 25종
insert into public.gear (id, name, category, place) values
  ('barbell', '바벨', '프리웨이트', 'gym'),
  ('rack', '스쿼트 랙', '고정 기구', 'gym'),
  ('flatbench', '플랫 벤치', '벤치', 'gym'),
  ('inclinebench', '각도 조절 벤치', '벤치', 'gym'),
  ('smith', '스미스 머신', '머신', 'gym'),
  ('cablemachine', '케이블 머신', '케이블', 'gym'),
  ('latmachine', '랫 풀다운 머신', '머신', 'gym'),
  ('rowmachine', '시티드 로우 머신', '머신', 'gym'),
  ('legpressm', '레그 프레스 머신', '머신', 'gym'),
  ('legcurlm', '레그 컬 머신', '머신', 'gym'),
  ('legextm', '레그 익스텐션 머신', '머신', 'gym'),
  ('hacksquatm', '핵 스쿼트 머신', '머신', 'gym'),
  ('chestpressm', '체스트 프레스 머신', '머신', 'gym'),
  ('pecdeckm', '펙 덱 머신', '머신', 'gym'),
  ('shoulderpressm', '숄더 프레스 머신', '머신', 'gym'),
  ('hipabdm', '힙 어브덕션 머신', '머신', 'gym'),
  ('tbar', '티바 로우 머신', '머신', 'gym'),
  ('pullupbar', '풀업 바', '고정 기구', 'gym'),
  ('trx', 'TRX 스트랩', '고정 기구', 'gym'),
  ('dumbbell', '덤벨', '소도구', 'home'),
  ('band', '저항 밴드', '소도구', 'home'),
  ('anchor', '밴드 고정 고리(문·기둥)', '소도구', 'home'),
  ('mat', '운동 매트', '소도구', 'home'),
  ('chair', '튼튼한 의자·계단', '집 안 물건', 'home'),
  ('wall', '벽', '집 안 물건', 'home')
on conflict (id) do nothing;

-- 운동별 기구 연결 (required: true 꼭 필요, false 있으면 좋음)
insert into public.exercise_gear (exercise_id, gear_id, required) values
  ('bench', 'barbell', true),
  ('bench', 'flatbench', true),
  ('bench', 'rack', true),
  ('incline', 'dumbbell', true),
  ('incline', 'inclinebench', true),
  ('floorpress', 'dumbbell', true),
  ('floorpress', 'mat', false),
  ('crossover', 'cablemachine', true),
  ('pushup', 'mat', false),
  ('kpush', 'mat', false),
  ('wallpushup', 'wall', true),
  ('deadlift', 'barbell', true),
  ('row', 'barbell', true),
  ('pullup', 'pullupbar', true),
  ('lat', 'latmachine', true),
  ('seatedrow', 'rowmachine', true),
  ('seatedrow', 'cablemachine', false),
  ('dbrow', 'dumbbell', true),
  ('dbrow', 'chair', false),
  ('trxrow', 'trx', true),
  ('facepull', 'cablemachine', true),
  ('ohp', 'barbell', true),
  ('ohp', 'rack', false),
  ('latraise', 'dumbbell', true),
  ('pushdown', 'cablemachine', true),
  ('kickback', 'dumbbell', true),
  ('dbcurl', 'dumbbell', true),
  ('squat', 'barbell', true),
  ('squat', 'rack', true),
  ('goblet', 'dumbbell', true),
  ('bulg', 'chair', true),
  ('bulg', 'dumbbell', false),
  ('rdl', 'barbell', true),
  ('legpress', 'legpressm', true),
  ('legcurl', 'legcurlm', true),
  ('bridge', 'mat', false),
  ('hipthrust', 'chair', true),
  ('hipthrust', 'dumbbell', false),
  ('hipthrust', 'mat', false),
  ('calfraise', 'wall', false),
  ('burpee', 'mat', false),
  ('mclimber', 'mat', false),
  ('plank', 'mat', false),
  ('sideplank', 'mat', false),
  ('deadbug', 'mat', false),
  ('birddog', 'mat', false),
  ('superman', 'mat', false),
  ('dbrdl', 'dumbbell', true),
  ('bandrow', 'band', true),
  ('bandrow', 'anchor', true),
  ('bandfacepull', 'band', true),
  ('bandfacepull', 'anchor', true),
  ('dbpress', 'dumbbell', true),
  ('dbpress', 'chair', false),
  ('chestpress', 'chestpressm', true),
  ('pecdeck', 'pecdeckm', true),
  ('shoulderpressm', 'shoulderpressm', true),
  ('legext', 'legextm', true),
  ('hacksquat', 'hacksquatm', true),
  ('smithsquat', 'smith', true),
  ('tbarrow', 'tbar', true),
  ('chinup', 'pullupbar', true),
  ('cablecurl', 'cablemachine', true),
  ('hipabd', 'hipabdm', true),
  ('stepup', 'chair', true),
  ('wallsit', 'wall', true),
  ('sumosquat', 'dumbbell', true),
  ('singlebridge', 'mat', false),
  ('donkeykick', 'mat', false),
  ('chairdip', 'chair', true),
  ('dbfly', 'dumbbell', true),
  ('dbfly', 'mat', false),
  ('hammercurl', 'dumbbell', true),
  ('bandpulldown', 'band', true),
  ('bandpulldown', 'anchor', true),
  ('bandpress', 'band', true),
  ('bandpress', 'anchor', true),
  ('bandpullapart', 'band', true),
  ('crunch', 'mat', false),
  ('legraise', 'mat', false),
  ('russiantwist', 'mat', false)
on conflict do nothing;
