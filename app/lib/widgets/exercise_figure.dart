import 'package:flutter/material.dart';

import '../data/exercise_lookup.dart';
import '../data/exercise_models.dart';
import '../data/exercises.dart';
import '../theme/app_theme.dart';

export '../data/exercise_lookup.dart';

/// 움직이는 동작 그림. '동작 줄이기' 설정이 켜져 있으면 멈춘 그림을 보여 준다.
class ExerciseFigureView extends StatefulWidget {
  const ExerciseFigureView(this.id, {super.key, this.size = 64, this.radius = 14});
  final String id;
  final double size;
  final double radius;

  @override
  State<ExerciseFigureView> createState() => _ExerciseFigureViewState();
}

class _ExerciseFigureViewState extends State<ExerciseFigureView> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fig = exerciseFigures[exerciseById(widget.id)?.figureId ?? widget.id];
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(widget.radius)),
      child: fig == null
          ? null
          : RepaintBoundary(
              child: AnimatedBuilder(
                animation: controller,
                builder: (_, _) => CustomPaint(painter: _FigurePainter(fig, _pose(controller.value))),
              ),
            ),
    );
  }

  /// 0 = 자세 A, 1 = 자세 B. 잠깐 멈췄다가 움직이고 돌아온다 (프로토타입과 같은 박자).
  static double _pose(double t) {
    if (t < .15) return 0;
    if (t < .5) return Curves.easeInOut.transform((t - .15) / .35);
    if (t < .65) return 1;
    return 1 - Curves.easeInOut.transform((t - .65) / .35);
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter(this.fig, this.p);
  final ExerciseFigure fig;
  final double p;

  Offset _lerp(Offset a, Offset b) => Offset.lerp(a, b, p)!;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    Paint line(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(const Offset(8, 92), const Offset(92, 92), line(Colors.white.withValues(alpha: .35), 2));
    for (final l in fig.staticLines) {
      canvas.drawLine(l.from, l.to, line(Colors.white.withValues(alpha: l.opacity), l.width));
    }
    for (final (anchor, a, b) in fig.cables) {
      canvas.drawLine(anchor, _lerp(a, b), line(Colors.white.withValues(alpha: .55), 1.5));
    }
    for (final a in fig.anchors) {
      canvas.drawCircle(a, 2.5, Paint()..color = Colors.white);
    }
    for (final limb in fig.limbs) {
      final points = [for (var i = 0; i < limb.a.length; i++) _lerp(limb.a[i], limb.b[i])];
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final pt in points.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      final width = points.length == 2 && limb.highlight ? 11.0 : 8.0;
      canvas.drawPath(path, line(AppColors.figureLimb, width));
      if (limb.highlight) canvas.drawPath(path, line(Colors.white, width));
    }
    canvas.drawCircle(_lerp(fig.head.$1, fig.head.$2), 7.5, Paint()..color = AppColors.figureLimb);
    for (final (a, b) in fig.props) {
      canvas.drawCircle(_lerp(a, b), 7, line(Colors.white, 3));
    }
  }

  @override
  bool shouldRepaint(_FigurePainter old) => old.p != p || old.fig != fig;
}
