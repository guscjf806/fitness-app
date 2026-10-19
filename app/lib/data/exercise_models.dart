import 'dart:ui';

/// 운동 종목 (기획서 `exercises` 표와 같은 구성)
class ExerciseInfo {
  const ExerciseInfo({
    required this.id,
    required this.name,
    required this.part,
    required this.equipment,
    required this.place,
    required this.impact,
    required this.noise,
    required this.easierId,
    required this.harderId,
    required this.avoidFor,
    required this.howTo,
    required this.caution,
    required this.figureId,
  });

  final String id;
  final String name;

  /// 가슴 / 등 / 어깨 / 삼두 / 이두 / 하체 / 코어 / 전신
  final String part;

  /// 바벨 / 덤벨 / 밴드 / 머신 / 케이블 / 맨몸
  final String equipment;

  /// gym / home / both
  final String place;

  /// low / high
  final String impact;

  /// quiet / loud
  final String noise;
  final String? easierId;
  final String? harderId;

  /// 이 부위가 아프면 루틴에서 뺀다 (기획서 16번 안전 규칙)
  final List<String> avoidFor;

  /// 하는 방법 3단계 (트레이너 검수 대상)
  final List<String> howTo;
  final String caution;

  /// 동작 그림 id (비슷한 동작의 그림을 빌려 쓰기도 한다)
  final String figureId;
}

/// 움직이는 동작 그림 (100×100 좌표, 프로토타입에서 옮김). 자세 A ↔ 자세 B를 오간다.
class ExerciseFigure {
  const ExerciseFigure({
    required this.head,
    required this.limbs,
    this.props = const [],
    this.cables = const [],
    this.staticLines = const [],
    this.anchors = const [],
  });

  final (Offset, Offset) head;
  final List<FigLimb> limbs;

  /// 덤벨·바벨 (원)
  final List<(Offset, Offset)> props;

  /// 케이블 줄: (고정점, A 자세 끝, B 자세 끝)
  final List<(Offset, Offset, Offset)> cables;

  /// 벤치·바 같은 고정된 선
  final List<FigLine> staticLines;

  /// 케이블 고정점 (작은 점)
  final List<Offset> anchors;
}

class FigLimb {
  const FigLimb(this.a, this.b, {required this.highlight});
  final List<Offset> a;
  final List<Offset> b;

  /// 주로 쓰는 근육 (흰색으로 강조)
  final bool highlight;
}

class FigLine {
  const FigLine(this.from, this.to, this.width, this.opacity);
  final Offset from;
  final Offset to;
  final double width;
  final double opacity;
}
