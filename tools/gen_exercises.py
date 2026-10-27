"""prototype 그림 데이터(figs.json) + 종목 설명·태그 → app/lib/data/exercises.dart, docs/운동설명_검수.md"""
import json, sys

figs_path, dart_out, md_out, sql_dir = sys.argv[1:5]
d = json.load(open(figs_path))
FIG, EXS, AL = d['FIG'], d['EXS'], d['AL']

# id: (장소 gym/home — 아래에서 두 가지로 정리, 충격 low/high, 소음 quiet/loud, 쉬운 id, 어려운 id, 피할 통증 부위, [방법 3단계], 주의)
INFO = {
 'bench': ('gym','low','quiet',None,None,['어깨','손목'],['벤치에 누워 발을 바닥에 단단히 두고 어깨뼈를 모아요','바를 어깨너비보다 조금 넓게 잡고 가슴 중간으로 천천히 내려요','가슴이 바에 닿을 듯하면 숨을 내쉬며 밀어 올려요'],'엉덩이가 벤치에서 뜨지 않게 하고, 무거운 무게는 보조자와 함께 해요.'),
 'incline': ('both','low','quiet','floorpress',None,['어깨','손목'],['벤치 등받이를 30~45도로 세우고 덤벨을 가슴 위로 들어요','팔꿈치를 몸통에서 45도 정도 벌린 채 가슴 위쪽으로 내려요','가슴 위쪽에 힘을 주며 덤벨을 모으듯 밀어 올려요'],'등받이를 너무 세우면 어깨 운동이 되니 45도를 넘기지 않아요.'),
 'floorpress': ('both','low','quiet',None,'incline',['어깨','손목'],['바닥에 누워 무릎을 세우고 덤벨을 가슴 위로 들어요','팔꿈치가 바닥에 살짝 닿을 때까지 천천히 내려요','잠깐 멈춘 뒤 가슴에 힘을 주며 밀어 올려요'],'팔꿈치를 바닥에 쿵 내려놓지 말고 살짝 닿게만 해요.'),
 'crossover': ('gym','low','quiet',None,None,['어깨'],['케이블 손잡이를 높은 위치에서 잡고 한 발 앞으로 나와 서요','팔꿈치를 살짝 굽힌 채 큰 원을 그리듯 손을 몸 앞으로 모아요','가슴을 쥐어짜듯 잠깐 멈췄다가 천천히 돌아가요'],'팔을 펴고 굽히는 동작이 되지 않게 팔꿈치 각도를 그대로 유지해요.'),
 'pushup': ('both','low','quiet','kpush',None,['손목','어깨'],['손을 어깨너비보다 조금 넓게 짚고 머리부터 발끝까지 일직선을 만들어요','팔꿈치를 몸통 쪽으로 45도 굽히며 가슴을 바닥 가까이 내려요','바닥을 밀어내듯 올라와 처음 자세로 돌아가요'],'허리가 처지거나 엉덩이가 들리지 않게 배에 힘을 줘요.'),
 'kpush': ('both','low','quiet','wallpushup','pushup',['손목'],['무릎을 바닥에 대고 손은 어깨너비보다 조금 넓게 짚어요','무릎부터 머리까지 일직선을 유지하며 가슴을 내려요','바닥을 밀어 올라와요'],'무릎이 아프면 수건이나 매트를 깔아요.'),
 'wallpushup': ('home','low','quiet',None,'kpush',['손목'],['벽에서 한 걸음 떨어져 손을 어깨 높이로 벽에 짚어요','몸을 일직선으로 유지하며 가슴을 벽 쪽으로 기울여요','벽을 밀어 처음 자세로 돌아와요'],'발이 미끄러지지 않는 바닥에서 해요.'),
 'deadlift': ('gym','low','loud','rdl',None,['허리'],['바 앞에 서서 발을 골반너비로 벌리고 바가 발 가운데 오게 해요','엉덩이를 뒤로 빼며 허리를 곧게 편 채 바를 잡아요','바를 몸에 붙인 채 다리와 엉덩이로 밀며 일어서요'],'등이 둥글게 말리면 바로 멈춰요. 내려놓을 때도 허리를 편 채로 내려요.'),
 'row': ('gym','low','quiet','dbrow',None,['허리'],['바를 잡고 무릎을 살짝 굽혀 상체를 45도 정도 숙여요','팔꿈치를 뒤로 보내며 바를 배꼽 쪽으로 당겨요','등에 힘을 준 채 천천히 내려요'],'허리를 편 자세를 끝까지 유지하고, 반동으로 당기지 않아요.'),
 'pullup': ('gym','low','quiet','lat',None,['어깨'],['바를 어깨너비보다 조금 넓게 잡고 매달려요','어깨를 내리고 팔꿈치를 옆구리 쪽으로 당기며 몸을 끌어올려요','턱이 바를 넘으면 천천히 내려와요'],'몸을 흔들어 반동을 쓰지 말고, 어렵다면 랫 풀다운부터 해요.'),
 'lat': ('gym','low','quiet',None,'pullup',['어깨'],['패드에 허벅지를 고정하고 바를 어깨너비보다 넓게 잡아요','가슴을 펴고 바를 쇄골 쪽으로 당겨요','팔이 다 펴질 때까지 천천히 올려 보내요'],'목 뒤로 당기지 않아요. 상체를 너무 젖히지 않아요.'),
 'seatedrow': ('gym','low','quiet',None,'row',['허리'],['발판에 발을 대고 허리를 편 채 손잡이를 잡아요','팔꿈치를 몸에 붙인 채 손잡이를 배 쪽으로 당겨요','어깨뼈를 모았다가 천천히 팔을 펴요'],'당길 때 상체를 뒤로 크게 젖히지 않아요.'),
 'dbrow': ('both','low','quiet',None,'row',['허리'],['벤치나 의자에 한 손과 한 무릎을 대고 등을 평평하게 해요','덤벨을 든 팔의 팔꿈치를 천장 쪽으로 당겨 올려요','등에 힘을 느끼며 천천히 내려요'],'몸통을 비틀어 올리지 말고 등과 팔꿈치로 당겨요.'),
 'trxrow': ('both','low','quiet',None,'pullup',['어깨'],['스트랩 손잡이를 잡고 몸을 뒤로 기울여 일직선을 만들어요','팔꿈치를 옆구리로 당기며 가슴을 손잡이 쪽으로 끌어올려요','몸이 꺾이지 않게 천천히 돌아가요'],'발을 앞으로 옮길수록 어려워져요. 처음에는 몸을 조금만 기울여요.'),
 'facepull': ('gym','low','quiet',None,None,['어깨'],['케이블을 얼굴 높이에 두고 로프 손잡이를 잡아요','팔꿈치를 높게 든 채 로프를 얼굴 쪽으로 당기며 양손을 벌려요','어깨 뒤쪽에 힘을 느끼고 천천히 돌아가요'],'무게를 가볍게 하고, 허리를 젖혀서 당기지 않아요.'),
 'ohp': ('gym','low','quiet',None,None,['어깨','허리'],['바를 쇄골 앞에 두고 어깨너비로 잡아 서요','배와 엉덩이에 힘을 주고 바를 머리 위로 똑바로 밀어 올려요','팔이 다 펴지면 천천히 쇄골 앞으로 내려요'],'허리를 뒤로 젖히며 밀지 않아요.'),
 'latraise': ('both','low','quiet',None,None,['어깨'],['덤벨을 양손에 들고 팔꿈치를 살짝 굽혀 서요','팔꿈치가 어깨 높이에 올 때까지 옆으로 들어 올려요','천천히 내려요'],'어깨가 귀 쪽으로 으쓱 올라가지 않게 해요. 가벼운 무게로 해요.'),
 'pushdown': ('gym','low','quiet',None,None,['손목'],['높은 케이블 손잡이를 잡고 팔꿈치를 옆구리에 붙여요','팔꿈치는 고정한 채 손잡이를 아래로 눌러 팔을 펴요','팔 뒤쪽에 힘을 느끼고 천천히 올려요'],'팔꿈치가 앞뒤로 움직이지 않게 고정해요.'),
 'kickback': ('both','low','quiet',None,None,['허리'],['상체를 숙이고 덤벨을 든 팔의 팔꿈치를 옆구리 높이로 들어요','팔꿈치는 고정한 채 팔을 뒤로 쭉 펴요','천천히 굽혀 돌아와요'],'허리를 편 자세를 유지해요.'),
 'dbcurl': ('both','low','quiet',None,None,['손목'],['덤벨을 양손에 들고 팔꿈치를 옆구리에 붙여 서요','팔꿈치를 고정한 채 덤벨을 어깨 쪽으로 감아 올려요','천천히 내려 팔을 거의 다 펴요'],'몸을 흔들어 반동으로 올리지 않아요.'),
 'squat': ('gym','low','loud','goblet',None,['무릎','허리'],['바를 등 위쪽에 얹고 발을 어깨너비로 벌려요','엉덩이를 뒤로 빼며 허벅지가 바닥과 나란해질 때까지 앉아요','발바닥 전체로 바닥을 밀며 일어서요'],'무릎이 안쪽으로 모이지 않게 하고, 허리를 편 채 내려가요.'),
 'goblet': ('both','low','quiet',None,'squat',['무릎'],['덤벨 한쪽 끝을 가슴 앞에 세워 들어요','가슴을 편 채 엉덩이를 뒤로 빼며 앉아요','발뒤꿈치로 밀며 일어서요'],'무릎과 발끝이 같은 방향을 보게 해요.'),
 'lunge': ('both','low','quiet',None,'jumplunge',['무릎'],['한 발을 앞으로, 한 발을 뒤로 두고 서요','뒷무릎이 바닥에 닿을 듯할 때까지 곧게 내려가요','앞발로 밀며 올라와요. 반대쪽도 같은 횟수로 해요'],'앞무릎이 발끝보다 크게 나가지 않게 하고, 상체를 세워요.'),
 'bulg': ('both','low','quiet','lunge',None,['무릎'],['뒤에 둔 의자나 벤치에 한 발 등을 올려요','앞다리 무릎을 굽혀 곧게 내려가요','앞발 뒤꿈치로 밀며 올라와요'],'균형이 어려우면 벽을 잡고 해요.'),
 'rdl': ('gym','low','quiet',None,'deadlift',['허리'],['바를 허벅지 앞에 들고 무릎을 살짝 굽혀 서요','허리를 편 채 엉덩이를 뒤로 빼며 바를 정강이 쪽으로 내려요','허벅지 뒤쪽이 당기면 엉덩이를 앞으로 밀며 일어서요'],'등이 둥글게 말리기 전까지만 내려가요.'),
 'legpress': ('gym','low','quiet',None,None,['무릎'],['등과 엉덩이를 등받이에 붙이고 발판에 발을 어깨너비로 둬요','무릎을 굽혀 발판을 천천히 내려요','발바닥 전체로 밀어 올리되 무릎을 끝까지 잠그지 않아요'],'엉덩이가 등받이에서 뜰 만큼 깊이 내리지 않아요.'),
 'legcurl': ('gym','low','quiet',None,None,['무릎'],['머신에 엎드려 발목 뒤에 패드를 맞춰요','발뒤꿈치를 엉덩이 쪽으로 감아 올려요','천천히 내려요'],'엉덩이가 들리지 않게 배를 패드에 붙여요.'),
 'bridge': ('both','low','quiet',None,'hipthrust',['허리'],['누워서 무릎을 세우고 발을 골반너비로 둬요','엉덩이를 조이며 어깨부터 무릎까지 일직선이 되게 들어 올려요','잠깐 멈췄다가 천천히 내려요'],'허리를 꺾어 올리지 말고 엉덩이 힘으로 올려요.'),
 'hipthrust': ('both','low','quiet','bridge',None,['허리'],['벤치에 등 위쪽을 기대고 무릎을 세워 앉아요','엉덩이를 조이며 몸통이 바닥과 나란해질 때까지 들어 올려요','천천히 내려요'],'턱을 당겨 시선을 앞으로 두면 허리가 덜 꺾여요.'),
 'calfraise': ('both','low','quiet',None,None,['발목'],['벽을 가볍게 잡고 발을 골반너비로 벌려 서요','발뒤꿈치를 최대한 높이 들어 올려요','천천히 내려요'],'반동 없이 천천히 오르내려요.'),
 'jumpsquat': ('both','high','loud','goblet',None,['무릎','발목'],['발을 어깨너비로 벌리고 스쿼트 자세로 앉아요','바닥을 힘껏 밀며 위로 뛰어올라요','무릎을 살짝 굽히며 부드럽게 착지하고 바로 다음 동작으로 이어가요'],'층간소음이 있고 무릎에 부담이 커요. 착지는 발 앞쪽부터 조용히 해요.'),
 'jumplunge': ('both','high','loud','lunge',None,['무릎','발목'],['런지 자세로 내려가요','위로 뛰어오르며 공중에서 다리를 바꿔요','반대 다리가 앞으로 온 런지 자세로 부드럽게 착지해요'],'층간소음이 있고 무릎에 부담이 커요. 균형이 흔들리면 일반 런지로 바꿔요.'),
 'burpee': ('both','high','loud','mclimber',None,['무릎','손목','허리'],['서 있다가 쪼그려 앉아 손을 바닥에 짚어요','두 발을 뒤로 뻗어 푸시업 자세를 만들었다가 다시 당겨 와요','일어서며 가볍게 뛰어올라요'],'층간소음이 있어요. 힘들면 점프와 푸시업을 빼고 해요.'),
 'mclimber': ('both','high','loud','plank','burpee',['손목'],['푸시업 자세로 손을 어깨 아래에 짚어요','한쪽 무릎을 가슴 쪽으로 당겼다가 돌려놓아요','다리를 번갈아 빠르게 반복해요'],'엉덩이가 들리지 않게 하고, 소음이 걱정되면 천천히 해요.'),
 'plank': ('both','low','quiet','deadbug','mclimber',['허리','손목'],['팔꿈치를 어깨 아래에 대고 엎드려요','발끝으로 몸을 들어 머리부터 발끝까지 일직선을 만들어요','배와 엉덩이에 힘을 준 채 정해진 시간만큼 버텨요'],'허리가 처지면 시간을 줄여요. 숨은 참지 말고 고르게 쉬어요.'),
 'sideplank': ('both','low','quiet','plank',None,['어깨','허리'],['옆으로 누워 팔꿈치를 어깨 바로 아래에 대요','엉덩이를 들어 머리부터 발까지 일직선을 만들어요','정해진 시간만큼 버티고 반대쪽도 해요'],'어렵다면 아래쪽 무릎을 바닥에 대고 해요.'),
 'deadbug': ('both','low','quiet',None,'plank',[],['누워서 팔을 천장으로 뻗고 무릎을 90도로 들어요','허리를 바닥에 붙인 채 한쪽 팔과 반대쪽 다리를 천천히 뻗어요','돌아와서 반대쪽도 해요'],'허리가 바닥에서 뜨면 범위를 줄여요.'),
 'birddog': ('both','low','quiet',None,None,['손목'],['네발 자세로 손은 어깨 아래, 무릎은 골반 아래에 둬요','한쪽 팔과 반대쪽 다리를 바닥과 나란하게 뻗어요','잠깐 멈췄다가 돌아와서 반대쪽도 해요'],'몸통이 옆으로 기울지 않게 천천히 해요.'),
 'superman': ('both','low','quiet','birddog',None,['허리','목'],['엎드려 팔을 머리 위로 뻗어요','팔과 다리를 동시에 바닥에서 살짝 들어 올려요','2초 멈췄다가 천천히 내려요'],'허리 통증이 있으면 하지 않아요. 고개를 너무 들지 않아요.'),
}
# 집 운동용 종목: 헬스장 종목과 태그가 달라서 따로 둔다 (그림은 비슷한 동작을 빌려 쓴다)
EXTRA = [
 ({'id':'bwsquat','n':'맨몸 스쿼트','p':'하체','e':'맨몸'}, 'squat'),
 ({'id':'dbrdl','n':'덤벨 루마니안 데드리프트','p':'하체','e':'덤벨'}, 'rdl'),
 ({'id':'bandrow','n':'밴드 로우','p':'등','e':'밴드'}, 'seatedrow'),
 ({'id':'bandfacepull','n':'밴드 페이스 풀','p':'어깨','e':'밴드'}, 'facepull'),
 ({'id':'dbpress','n':'덤벨 숄더 프레스','p':'어깨','e':'덤벨'}, 'ohp'),
]
INFO.update({
 'bwsquat': ('both','low','quiet',None,'jumpsquat',['무릎'],['발을 어깨너비로 벌리고 팔을 앞으로 뻗어 서요','엉덩이를 뒤로 빼며 3초 동안 천천히 앉아요','허벅지가 바닥과 나란해지면 발바닥으로 밀며 일어서요'],'무릎이 안쪽으로 모이지 않게 하고, 아프면 앉는 깊이를 줄여요.'),
 'dbrdl': ('both','low','quiet',None,'rdl',['허리'],['덤벨을 허벅지 앞에 들고 무릎을 살짝 굽혀 서요','허리를 편 채 엉덩이를 뒤로 빼며 덤벨을 정강이 쪽으로 내려요','허벅지 뒤쪽이 당기면 엉덩이를 앞으로 밀며 일어서요'],'등이 둥글게 말리기 전까지만 내려가요. 덤벨을 바닥에 떨어뜨리지 않게 해요.'),
 'bandrow': ('both','low','quiet',None,'dbrow',['허리'],['밴드를 기둥이나 문에 고정하고 양 끝을 잡아요','팔꿈치를 몸에 붙인 채 밴드를 배 쪽으로 당겨요','어깨뼈를 모았다가 천천히 팔을 펴요'],'밴드가 단단히 고정됐는지 먼저 확인해요.'),
 'bandfacepull': ('both','low','quiet',None,None,['어깨'],['밴드를 얼굴 높이에 고정하고 양 끝을 잡아요','팔꿈치를 높게 든 채 밴드를 얼굴 쪽으로 당기며 양손을 벌려요','어깨 뒤쪽에 힘을 느끼고 천천히 돌아가요'],'밴드가 튕겨 얼굴에 맞지 않게 천천히 돌아가요.'),
 'dbpress': ('both','low','quiet',None,'ohp',['어깨','허리'],['덤벨을 어깨 높이로 들고 서거나 의자에 앉아요','배에 힘을 주고 덤벨을 머리 위로 밀어 올려요','팔이 다 펴지면 천천히 어깨 높이로 내려요'],'허리를 뒤로 젖히며 밀지 않아요.'),
})
FIGURE_OF = {e['id']: e['id'] for e in EXS}
for e, fig in EXTRA:
    EXS.append(e)
    FIGURE_OF[e['id']] = fig
# 별칭은 '같은 운동의 다른 이름'만 둔다
AL = {'바벨 스쿼트': 'squat', '글루트 브릿지': 'bridge', 'TRX 로우 (직접 추가)': 'trxrow'}
assert set(INFO) == {e['id'] for e in EXS}, set(INFO) ^ {e['id'] for e in EXS}

# ── 2026-10-27 추가 종목 (DB 저장용으로 확장). 그림은 비슷한 동작을 빌려 쓴다 ─────────────
# (id, 이름, 부위, 기구, 장소, 충격, 소음, 쉬운, 어려운, 피할 통증, [방법 3단계], 주의, 그림, 종류, 난이도)
NEW = [
 # 헬스장 전용 (머신·케이블·바벨·고정 기구)
 ('chestpress','체스트 프레스 머신','가슴','머신','gym','low','quiet',None,'bench',['어깨','손목'],['등을 등받이에 붙이고 손잡이가 가슴 중간 높이에 오게 의자를 맞춰요','가슴에 힘을 주며 손잡이를 앞으로 밀어요','팔이 거의 펴지면 천천히 돌아와요'],'어깨가 앞으로 말리지 않게 가슴을 펴고 해요.','bench','compound',1),
 ('pecdeck','펙 덱 플라이','가슴','머신','gym','low','quiet',None,None,['어깨'],['등을 등받이에 붙이고 손잡이를 어깨 높이로 잡아요','팔꿈치를 살짝 굽힌 채 양팔을 가슴 앞으로 모아요','가슴이 늘어나는 느낌이 들 때까지 천천히 벌려요'],'팔을 너무 뒤로 벌리면 어깨에 무리가 가요.','crossover','isolation',1),
 ('shoulderpressm','숄더 프레스 머신','어깨','머신','gym','low','quiet',None,'ohp',['어깨'],['손잡이가 어깨 높이에 오게 의자를 맞추고 앉아요','배에 힘을 주고 손잡이를 머리 위로 밀어 올려요','팔이 거의 펴지면 천천히 내려요'],'허리를 등받이에서 떼지 않아요.','ohp','compound',1),
 ('legext','레그 익스텐션','하체','머신','gym','low','quiet',None,None,['무릎'],['의자에 앉아 발목 앞에 패드를 맞춰요','허벅지 앞쪽에 힘을 주며 무릎을 펴요','끝에서 1초 멈췄다가 천천히 내려요'],'무릎이 아프면 무게를 줄이거나 범위를 줄여요.','legcurl','isolation',1),
 ('hacksquat','핵 스쿼트','하체','머신','gym','low','quiet','legpress',None,['무릎','허리'],['등을 패드에 붙이고 어깨를 받침 아래에 넣어요','발을 어깨너비로 두고 허벅지가 나란해질 때까지 앉아요','발바닥 전체로 밀며 일어서요'],'무릎을 끝까지 잠그지 않아요.','squat','compound',2),
 ('smithsquat','스미스 머신 스쿼트','하체','머신','gym','low','quiet','goblet','squat',['무릎','허리'],['바를 등 위쪽에 얹고 발을 살짝 앞으로 둬요','엉덩이를 뒤로 빼며 허벅지가 나란해질 때까지 앉아요','발바닥으로 밀며 일어서요'],'안전 고리 높이를 먼저 맞춰 두세요.','squat','compound',2),
 ('tbarrow','티바 로우','등','바벨','gym','low','quiet','seatedrow',None,['허리'],['손잡이를 잡고 무릎을 굽혀 상체를 45도 숙여요','팔꿈치를 뒤로 보내며 손잡이를 배 쪽으로 당겨요','등에 힘을 준 채 천천히 내려요'],'허리를 편 자세를 끝까지 지켜요.','row','compound',2),
 ('chinup','친업','등','맨몸','gym','low','quiet','lat',None,['어깨'],['바를 어깨너비로, 손바닥이 나를 보게 잡고 매달려요','팔꿈치를 옆구리로 당기며 몸을 끌어올려요','턱이 바를 넘으면 천천히 내려와요'],'반동을 쓰지 말고, 어렵다면 랫 풀다운부터 해요.','pullup','compound',3),
 ('cablecurl','케이블 컬','이두','케이블','gym','low','quiet',None,None,['손목'],['낮은 케이블 손잡이를 잡고 팔꿈치를 옆구리에 붙여요','팔꿈치를 고정한 채 손잡이를 어깨 쪽으로 감아 올려요','천천히 내려 팔을 거의 다 펴요'],'몸을 뒤로 젖혀 반동으로 올리지 않아요.','dbcurl','isolation',1),
 ('hipabd','힙 어브덕션 머신','하체','머신','gym','low','quiet',None,None,[],['머신에 앉아 무릎 바깥쪽에 패드를 맞춰요','엉덩이 옆쪽에 힘을 주며 다리를 바깥으로 벌려요','천천히 모아요'],'반동 없이 천천히 해요.','hipthrust','isolation',1),
 # 집에서도 가능 (맨몸·덤벨·밴드, 의자 같은 집 안 물건)
 ('reverselunge','리버스 런지','하체','맨몸','home','low','quiet','lunge','bulg',['무릎'],['발을 모으고 서서 한 발을 크게 뒤로 내딛어요','뒷무릎이 바닥에 닿을 듯할 때까지 내려가요','앞발로 밀며 처음 자세로 돌아와요. 반대쪽도 해요'],'앞으로 내딛는 런지보다 무릎 부담이 적어요. 상체는 세워요.','lunge','compound',1),
 ('stepup','스텝업','하체','맨몸','home','low','quiet',None,'bulg',['무릎'],['튼튼한 의자나 계단 앞에 서요','한 발을 올리고 그 발로 밀어 몸을 올려요','천천히 내려와요. 반대쪽도 해요'],'흔들리지 않는 의자나 계단에서만 해요.','lunge','compound',1),
 ('wallsit','월 싯','하체','맨몸','home','low','quiet',None,'bwsquat',['무릎'],['벽에 등을 대고 서요','허벅지가 바닥과 나란해질 때까지 벽을 따라 내려가요','정해진 시간만큼 버텨요'],'무릎이 아프면 덜 앉아서 해요.','squat','hold',1),
 ('sumosquat','덤벨 스모 스쿼트','하체','덤벨','home','low','quiet','bwsquat',None,['무릎'],['발을 어깨너비보다 넓게, 발끝은 바깥으로 두고 덤벨을 다리 사이로 들어요','가슴을 편 채 엉덩이를 뒤로 빼며 앉아요','허벅지 안쪽에 힘을 주며 일어서요'],'무릎이 발끝 방향으로 나가게 해요.','goblet','compound',1),
 ('singlebridge','싱글 레그 브릿지','하체','맨몸','home','low','quiet','bridge','hipthrust',['허리'],['누워서 한쪽 무릎을 세우고 다른 다리는 뻗어요','세운 발로 밀며 엉덩이를 들어 올려요','천천히 내려요. 반대쪽도 해요'],'골반이 한쪽으로 기울지 않게 해요.','bridge','compound',2),
 ('donkeykick','덩키 킥','하체','맨몸','home','low','quiet',None,'singlebridge',[],['네발 자세로 손은 어깨 아래, 무릎은 골반 아래에 둬요','무릎을 굽힌 채 한쪽 다리를 천장 쪽으로 들어요','엉덩이에 힘을 주고 천천히 내려요. 반대쪽도 해요'],'허리를 꺾지 말고 엉덩이 힘으로 들어요.','birddog','isolation',1),
 ('chairdip','의자 딥스','삼두','맨몸','home','low','quiet',None,None,['어깨','손목'],['튼튼한 의자 끝에 손을 짚고 엉덩이를 앞으로 빼요','팔꿈치를 뒤로 굽히며 몸을 내려요','팔 뒤쪽 힘으로 밀어 올라와요'],'어깨가 아프면 내려가는 깊이를 줄여요. 바퀴 달린 의자는 쓰지 않아요.','kickback','compound',2),
 ('dbfly','덤벨 플라이','가슴','덤벨','home','low','quiet',None,None,['어깨'],['바닥이나 벤치에 누워 덤벨을 가슴 위로 들어요','팔꿈치를 살짝 굽힌 채 양팔을 옆으로 천천히 벌려요','가슴을 모으듯 덤벨을 다시 모아요'],'팔을 너무 깊이 내리지 않아요.','floorpress','isolation',1),
 ('hammercurl','해머 컬','이두','덤벨','home','low','quiet',None,None,['손목'],['덤벨을 손바닥이 마주 보게 들고 서요','팔꿈치를 고정한 채 덤벨을 어깨 쪽으로 올려요','천천히 내려요'],'손목을 꺾지 말고 일자로 유지해요.','dbcurl','isolation',1),
 ('bandpulldown','밴드 랫 풀다운','등','밴드','home','low','quiet',None,'pullup',['어깨'],['밴드를 문 위쪽에 고정하고 무릎을 꿇고 앉아요','팔꿈치를 옆구리 쪽으로 당겨 밴드를 가슴 쪽으로 내려요','천천히 팔을 펴요'],'밴드가 단단히 고정됐는지 먼저 확인해요.','lat','compound',1),
 ('bandpress','밴드 체스트 프레스','가슴','밴드','home','low','quiet','pushup',None,['어깨'],['밴드를 등 뒤 기둥에 고정하고 양 끝을 잡아요','가슴 높이에서 팔을 앞으로 밀어 펴요','천천히 돌아와요'],'밴드가 튕기지 않게 천천히 돌아와요.','crossover','compound',1),
 ('bandpullapart','밴드 풀 어파트','어깨','밴드','home','low','quiet',None,None,[],['밴드를 어깨너비로 잡고 팔을 앞으로 뻗어요','어깨뼈를 모으며 밴드를 양옆으로 벌려요','천천히 돌아와요'],'어깨가 으쓱 올라가지 않게 해요.','facepull','isolation',1),
 ('crunch','크런치','코어','맨몸','home','low','quiet',None,'legraise',['목','허리'],['누워서 무릎을 세우고 손은 가슴 위에 둬요','배에 힘을 주며 어깨를 바닥에서 살짝 들어요','천천히 내려요'],'손으로 목을 당기지 않아요.','deadbug','isolation',1),
 ('legraise','레그 레이즈','코어','맨몸','home','low','quiet','crunch',None,['허리'],['누워서 손을 엉덩이 옆에 두고 다리를 뻗어요','허리를 바닥에 붙인 채 다리를 천장 쪽으로 들어요','바닥에 닿기 전까지 천천히 내려요'],'허리가 뜨면 무릎을 굽혀서 해요.','deadbug','isolation',2),
 ('russiantwist','러시안 트위스트','코어','맨몸','home','low','quiet','crunch',None,['허리'],['앉아서 무릎을 세우고 상체를 살짝 뒤로 기울여요','손을 모은 채 몸통을 왼쪽으로 돌려요','오른쪽으로 번갈아 돌려요'],'허리가 아프면 발을 바닥에 댄 채 해요.','deadbug','isolation',2),
 ('stepjack','스텝 잭','전신','맨몸','home','low','quiet',None,'jumpingjack',[],['발을 모으고 서요','한 발을 옆으로 내딛으며 두 팔을 머리 위로 올려요','돌아와서 반대쪽으로 번갈아 해요'],'점프 없이 하는 점핑 잭이라 층간소음 걱정이 없어요.','lunge','hold',1),
 ('jumpingjack','점핑 잭','전신','맨몸','home','high','loud','stepjack',None,['무릎','발목'],['발을 모으고 서요','뛰면서 다리를 벌리고 두 팔을 머리 위로 올려요','뛰면서 처음 자세로 돌아와요'],'층간소음이 있어요. 발 앞쪽으로 부드럽게 착지해요.','jumpsquat','hold',1),
]
for (i_, n_, p_, e_, pl, imp, noi, ez, hd, av, how, cau, fig, kind_, lvl) in NEW:
    EXS.append({'id': i_, 'n': n_, 'p': p_, 'e': e_})
    INFO[i_] = (pl, imp, noi, ez, hd, av, how, cau)
    FIGURE_OF[i_] = fig

# 장소는 두 가지로 나눈다: gym = 헬스장 전용(바벨·머신·케이블·고정 기구), home = 집에서도 가능(맨몸·덤벨·밴드).
# home 종목은 헬스장에서도 할 수 있으므로 헬스장 사용자에게도 추천한다.
GYM_ONLY = {'trxrow'}  # TRX는 집에 없는 경우가 많아 헬스장으로 둔다
for k, v in list(INFO.items()):
    place = 'gym' if v[0] == 'gym' or k in GYM_ONLY else 'home'
    INFO[k] = (place,) + v[1:]

# 종류: compound(여러 관절) / isolation(한 관절) / hold(버티기·시간 운동). 강도 규칙의 세트·개수에 쓴다.
KIND = {k: 'compound' for k in INFO}
for k in ['crossover', 'facepull', 'bandfacepull', 'latraise', 'pushdown', 'kickback', 'dbcurl', 'legcurl', 'calfraise',
          'deadbug', 'birddog', 'superman', 'mclimber']:
    KIND[k] = 'isolation'
for k in ['plank', 'sideplank']:
    KIND[k] = 'hold'
# 난이도: 1 초급 / 2 중급 / 3 상급. 처음 운동하는 사람(강도 하)에게는 1~2를 우선 추천한다.
LEVEL = {k: 2 for k in INFO}
for k in ['wallpushup', 'kpush', 'bridge', 'bwsquat', 'deadbug', 'birddog', 'plank', 'calfraise', 'lat', 'seatedrow',
          'legpress', 'legcurl', 'latraise', 'dbcurl', 'pushdown', 'goblet', 'floorpress', 'bandrow', 'bandfacepull', 'facepull']:
    LEVEL[k] = 1
for k in ['deadlift', 'squat', 'pullup', 'jumplunge', 'burpee', 'bulg', 'ohp', 'row']:
    LEVEL[k] = 3
for (i_, *_rest) in NEW:
    KIND[i_] = _rest[12]
    LEVEL[i_] = _rest[13]

# ── 운동 기구 (구체적인 기구 목록). place: gym = 헬스장에만 있는 큰 기구, home = 집에도 둘 수 있는 소도구·집 안 물건
GEAR = [
 ('barbell','바벨','프리웨이트','gym'), ('rack','스쿼트 랙','고정 기구','gym'), ('flatbench','플랫 벤치','벤치','gym'),
 ('inclinebench','각도 조절 벤치','벤치','gym'), ('smith','스미스 머신','머신','gym'), ('cablemachine','케이블 머신','케이블','gym'),
 ('latmachine','랫 풀다운 머신','머신','gym'), ('rowmachine','시티드 로우 머신','머신','gym'), ('legpressm','레그 프레스 머신','머신','gym'),
 ('legcurlm','레그 컬 머신','머신','gym'), ('legextm','레그 익스텐션 머신','머신','gym'), ('hacksquatm','핵 스쿼트 머신','머신','gym'),
 ('chestpressm','체스트 프레스 머신','머신','gym'), ('pecdeckm','펙 덱 머신','머신','gym'), ('shoulderpressm','숄더 프레스 머신','머신','gym'),
 ('hipabdm','힙 어브덕션 머신','머신','gym'), ('tbar','티바 로우 머신','머신','gym'), ('pullupbar','풀업 바','고정 기구','gym'),
 ('trx','TRX 스트랩','고정 기구','gym'),
 ('dumbbell','덤벨','소도구','home'), ('band','저항 밴드','소도구','home'), ('anchor','밴드 고정 고리(문·기둥)','소도구','home'),
 ('mat','운동 매트','소도구','home'), ('chair','튼튼한 의자·계단','집 안 물건','home'), ('wall','벽','집 안 물건','home'),
]
GEAR_IDS = {g[0] for g in GEAR}
# 운동별 기구: 꼭 필요한 것 / 있으면 좋은 것
EX_GEAR = {
 'bench': (['barbell','flatbench','rack'], []), 'incline': (['dumbbell','inclinebench'], []), 'floorpress': (['dumbbell'], ['mat']),
 'crossover': (['cablemachine'], []), 'pushup': ([], ['mat']), 'kpush': ([], ['mat']), 'wallpushup': (['wall'], []),
 'deadlift': (['barbell'], []), 'row': (['barbell'], []), 'pullup': (['pullupbar'], []), 'lat': (['latmachine'], []),
 'seatedrow': (['rowmachine'], ['cablemachine']), 'dbrow': (['dumbbell'], ['chair']), 'trxrow': (['trx'], []),
 'facepull': (['cablemachine'], []), 'ohp': (['barbell'], ['rack']), 'latraise': (['dumbbell'], []), 'pushdown': (['cablemachine'], []),
 'kickback': (['dumbbell'], []), 'dbcurl': (['dumbbell'], []), 'squat': (['barbell','rack'], []), 'goblet': (['dumbbell'], []),
 'lunge': ([], []), 'bulg': (['chair'], ['dumbbell']), 'rdl': (['barbell'], []), 'legpress': (['legpressm'], []),
 'legcurl': (['legcurlm'], []), 'bridge': ([], ['mat']), 'hipthrust': (['chair'], ['dumbbell','mat']), 'calfraise': ([], ['wall']),
 'jumpsquat': ([], []), 'jumplunge': ([], []), 'burpee': ([], ['mat']), 'mclimber': ([], ['mat']), 'plank': ([], ['mat']),
 'sideplank': ([], ['mat']), 'deadbug': ([], ['mat']), 'birddog': ([], ['mat']), 'superman': ([], ['mat']),
 'bwsquat': ([], []), 'dbrdl': (['dumbbell'], []), 'bandrow': (['band','anchor'], []), 'bandfacepull': (['band','anchor'], []),
 'dbpress': (['dumbbell'], ['chair']), 'chestpress': (['chestpressm'], []), 'pecdeck': (['pecdeckm'], []),
 'shoulderpressm': (['shoulderpressm'], []), 'legext': (['legextm'], []), 'hacksquat': (['hacksquatm'], []),
 'smithsquat': (['smith'], []), 'tbarrow': (['tbar'], []), 'chinup': (['pullupbar'], []), 'cablecurl': (['cablemachine'], []),
 'hipabd': (['hipabdm'], []), 'reverselunge': ([], []), 'stepup': (['chair'], []), 'wallsit': (['wall'], []),
 'sumosquat': (['dumbbell'], []), 'singlebridge': ([], ['mat']), 'donkeykick': ([], ['mat']), 'chairdip': (['chair'], []),
 'dbfly': (['dumbbell'], ['mat']), 'hammercurl': (['dumbbell'], []), 'bandpulldown': (['band','anchor'], []),
 'bandpress': (['band','anchor'], []), 'bandpullapart': (['band'], []), 'crunch': ([], ['mat']), 'legraise': ([], ['mat']),
 'russiantwist': ([], ['mat']), 'stepjack': ([], []), 'jumpingjack': ([], []),
}
assert set(EX_GEAR) == set(INFO), set(EX_GEAR) ^ set(INFO)
assert all(g in GEAR_IDS for req, opt in EX_GEAR.values() for g in req + opt)
GEAR_PLACE = {g[0]: g[3] for g in GEAR}
GEAR_NAME = {g[0]: g[1] for g in GEAR}
# 장소는 기구로 정한다: 꼭 필요한 기구 중 하나라도 헬스장 기구면 헬스장 전용
for k, v in list(INFO.items()):
    place = 'gym' if any(GEAR_PLACE[g] == 'gym' for g in EX_GEAR[k][0]) else 'home'
    if place != v[0]:
        print('장소 변경:', k, v[0], '→', place)
    INFO[k] = (place,) + v[1:]
assert set(INFO) == {e['id'] for e in EXS}, set(INFO) ^ {e['id'] for e in EXS}

def s(v): return "'" + str(v).replace("'", "\\'") + "'"
def num(v): return repr(float(v)) if float(v) != int(v) else str(int(v)) + '.0'
def pt(p): return f'Offset({num(p[0])}, {num(p[1])})'
def pts(a): return '[' + ', '.join(pt(p) for p in a) + ']'

out = ['// 자동 생성 파일: 프로토타입 그림 데이터 + 종목 설명. 설명 글은 트레이너 검수 대상 (docs/운동설명_검수.md).',
       '// ignore_for_file: lines_longer_than_80_chars', '', "import 'dart:ui';", '',
       "import 'exercise_models.dart';", '', 'const exercises = <ExerciseInfo>[']
for e in EXS:
    i = INFO[e['id']]
    out.append(f"  ExerciseInfo(id: {s(e['id'])}, name: {s(e['n'])}, part: {s(e['p'])}, equipment: {s(e['e'])}, "
               f"place: {s(i[0])}, impact: {s(i[1])}, noise: {s(i[2])}, easierId: {s(i[3]) if i[3] else 'null'}, "
               f"harderId: {s(i[4]) if i[4] else 'null'}, avoidFor: [{', '.join(s(x) for x in i[5])}], "
               f"howTo: [{', '.join(s(x) for x in i[6])}], caution: {s(i[7])}, figureId: {s(FIGURE_OF[e['id']])}, "
               f"kind: {s(KIND[e['id']])}, level: {LEVEL[e['id']]}, "
               f"gear: [{', '.join(s(GEAR_NAME[g]) for g in EX_GEAR[e['id']][0])}], "
               f"gearOptional: [{', '.join(s(GEAR_NAME[g]) for g in EX_GEAR[e['id']][1])}]),")
out += ['];', '', '/// 루틴·일지에 쓰는 다른 이름 → 종목 id', 'const exerciseAliases = <String, String>{']
for k, v in AL.items():
    out.append(f'  {s(k)}: {s(v)},')
out += ['};', '', 'const exerciseFigures = <String, ExerciseFigure>{']
for k, f in FIG.items():
    limbs = ', '.join(f'FigLimb({pts(a)}, {pts(b)}, highlight: {"true" if h else "false"})' for a, b, h in f['L'])
    props = ', '.join(f'({pt(a)}, {pt(b)})' for a, b in f['P'])
    cables = ', '.join(f'(Offset({num(a[0])}, {num(a[1])}), Offset({num(a[2])}, {num(a[3])}), Offset({num(b[2])}, {num(b[3])}))' for a, b in f['X'])
    lines = ', '.join(f"FigLine(Offset({num(l['x1'])}, {num(l['y1'])}), Offset({num(l['x2'])}, {num(l['y2'])}), {num(l['w'])}, {'0.55' if '.55' in l['c'] else ('0.45' if '.45' in l['c'] else '1.0')})" for l in f['S']['lines'])
    circles = ', '.join(f"Offset({num(c['cx'])}, {num(c['cy'])})" for c in f['S']['circles'])
    out.append(f"  {s(k)}: ExerciseFigure(head: ({pt(f['h'][0])}, {pt(f['h'][1])}), limbs: [{limbs}], props: [{props}], "
               f"cables: [{cables}], staticLines: [{lines}], anchors: [{circles}]),")
out.append('};')
open(dart_out, 'w').write('\n'.join(out) + '\n')

PLACE = {'gym': '헬스장 전용', 'home': '집에서도 가능'}
LEVEL_KO = {1: '초급', 2: '중급', 3: '상급'}
name = {e['id']: e['n'] for e in EXS}
md = ['# 운동 설명 검수 목록', '',
      '> 앱의 [운동 상세] 화면에 나오는 글이에요. Claude가 초안을 썼고, **선생님(트레이너)이 검수**한 뒤 출시해요.',
      '> 고칠 곳은 이 문서에 바로 고쳐 쓰거나 메모로 알려 주세요. 앱 데이터는 `app/lib/data/exercises.dart`에 있어요.', '',
      '체크: 검수를 마친 종목은 `[ ]`를 `[x]`로 바꿔 주세요.', '']
for part in ['가슴', '등', '어깨', '삼두', '이두', '하체', '코어', '전신']:
    md.append(f'## {part}')
    md.append('')
    for e in [x for x in EXS if x['p'] == part]:
        i = INFO[e['id']]
        tags = [PLACE[i[0]], e['e'], LEVEL_KO[LEVEL[e['id']]]]
        if i[1] == 'high': tags.append('고충격')
        if i[2] == 'loud': tags.append('소음 큼')
        md.append(f"### [ ] {e['n']}")
        md.append(f"- 분류: {' · '.join(tags)}")
        req, opt = EX_GEAR[e['id']]
        md.append(f"- 필요한 기구: {', '.join(GEAR_NAME[g] for g in req) or '없음'}" + (f" (있으면 좋은 것: {', '.join(GEAR_NAME[g] for g in opt)})" if opt else ''))
        md.append('- 하는 방법')
        md += [f'  {n}. {step}' for n, step in enumerate(i[6], 1)]
        md.append(f'- 주의: {i[7]}')
        rel = []
        if i[3]: rel.append(f'쉬운 동작 → {name[i[3]]}')
        if i[4]: rel.append(f'어려운 동작 → {name[i[4]]}')
        if rel: md.append(f"- 연결: {' / '.join(rel)}")
        if i[5]: md.append(f"- 이 부위가 아프면 루틴에서 뺌: {', '.join(i[5])}")
        md.append('')
open(md_out, 'w').write('\n'.join(md))

# ── Supabase: 표 만들기(migration)와 데이터 넣기(seed) ─────────────────────────
def q(v): return 'null' if v is None else "'" + str(v).replace("'", "''") + "'"
def arr(xs): return "array[" + ", ".join(q(x) for x in xs) + "]::text[]" if xs else "'{}'::text[]"
import os
os.makedirs(os.path.join(sql_dir, 'migrations'), exist_ok=True)
open(os.path.join(sql_dir, 'migrations', '20261027000000_exercises.sql'), 'w').write("""-- 운동 종목 목록 (기획서 6번 `exercises`). 회원·비회원 모두에게 추천하는 공용 데이터다.
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
""")
rows = []
for e in EXS:
    i = INFO[e['id']]
    rows.append(f"  ({q(e['id'])}, {q(e['n'])}, {q(e['p'])}, {q(e['e'])}, {q(i[0])}, {q(KIND[e['id']])}, {LEVEL[e['id']]}, "
                f"{q(i[1])}, {q(i[2])}, {arr(i[5])}, {arr(i[6])}, {q(i[7])}, {q(FIGURE_OF[e['id']])})")
links = [f"update public.exercises set easier_id = {q(INFO[e['id']][3])}, harder_id = {q(INFO[e['id']][4])} where id = {q(e['id'])};"
         for e in EXS if INFO[e['id']][3] or INFO[e['id']][4]]
gear_rows = [f"  ({q(g[0])}, {q(g[1])}, {q(g[2])}, {q(g[3])})" for g in GEAR]
eg_rows = [f"  ({q(k)}, {q(g)}, {'true' if g in req else 'false'})" for k, (req, opt) in EX_GEAR.items() for g in req + opt]
open(os.path.join(sql_dir, 'seed.sql'), 'w').write(
    "-- 자동 생성 (tools/gen_exercises.py). 운동 종목 " + str(len(EXS)) + "개.\n"
    "insert into public.exercises (id, name, body_part, equipment, place, kind, level, impact, noise, avoid_for, how_to, caution, figure_id) values\n"
    + ",\n".join(rows) + "\non conflict (id) do nothing;\n\n-- 쉬운/어려운 동작 연결 (모든 행이 들어간 뒤에 연결한다)\n" + "\n".join(links) + "\n"
    + "\n-- 운동 기구 " + str(len(GEAR)) + "종\ninsert into public.gear (id, name, category, place) values\n" + ",\n".join(gear_rows) + "\non conflict (id) do nothing;\n"
    + "\n-- 운동별 기구 연결 (required: true 꼭 필요, false 있으면 좋음)\ninsert into public.exercise_gear (exercise_id, gear_id, required) values\n" + ",\n".join(eg_rows) + "\non conflict do nothing;\n")
print('ok', len(EXS), 'gym', sum(1 for v in INFO.values() if v[0]=='gym'), 'home', sum(1 for v in INFO.values() if v[0]=='home'))
