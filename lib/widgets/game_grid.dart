import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/game_state.dart';
import '../models/car.dart';
import '../models/exit.dart';

/// 网格绘制器 —— 只画网格 + 出口 + 选中高亮，车辆由外部 Widget 叠加。
class GridPainter extends CustomPainter {
  final GameState state;
  final Exit exit;
  final double unitSize;
  final String? selectedCarId;

  GridPainter({
    required this.state,
    required this.exit,
    required this.unitSize,
    this.selectedCarId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawExit(canvas);
    _drawSelection(canvas);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.grey.shade300..strokeWidth = 1.5;
    for (int i = 0; i <= state.gridSize; i++) {
      final pos = i * unitSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), p);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), p);
    }
  }

  void _drawExit(Canvas canvas) {
    final r = Rect.fromLTWH(
        exit.col * unitSize, exit.row * unitSize, unitSize, unitSize);
    canvas.drawRect(r, Paint()..color = Colors.green.withAlpha(60));

    // 出口箭头
    final ap = Paint()..color = Colors.green..style = PaintingStyle.fill;
    final path = Path();
    final cx = r.center.dx, cy = r.center.dy, h = unitSize * 0.25;
    if (exit.orientation == CarOrientation.horizontal) {
      path.moveTo(cx + h, cy);
      path.lineTo(cx - h, cy - h);
      path.lineTo(cx - h, cy + h);
    } else {
      path.moveTo(cx, cy + h);
      path.lineTo(cx - h, cy - h);
      path.lineTo(cx + h, cy - h);
    }
    path.close();
    canvas.drawPath(path, ap);
  }

  void _drawSelection(Canvas canvas) {
    if (selectedCarId == null) return;
    final car = state.cars.firstWhere(
      (c) => c.id == selectedCarId,
      orElse: () => state.cars.first,
    );
    if (car.id != selectedCarId) return;

    final rect = _carRect(car);
    // 外发光
    final gp = Paint()
      ..color = Colors.white.withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(5), const Radius.circular(8)), gp);
    // 白色边框
    final bp = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), bp);
  }

  Rect _carRect(Car car) {
    const g = 2.0;
    final l = car.col * unitSize + g, t = car.row * unitSize + g;
    if (car.orientation == CarOrientation.horizontal) {
      return Rect.fromLTWH(l, t, car.length * unitSize - g * 2, unitSize - g * 2);
    }
    return Rect.fromLTWH(l, t, unitSize - g * 2, car.length * unitSize - g * 2);
  }

  @override
  bool shouldRepaint(GridPainter old) =>
      old.state != state || old.selectedCarId != selectedCarId;
}

/// 单个车辆 SVG 渲染组件，支持拖拽偏移和旋转。
class CarSvgWidget extends StatelessWidget {
  final Car car;
  final double unitSize;
  final bool isHinted;
  final Offset? dragOffset;

  const CarSvgWidget({
    super.key,
    required this.car,
    required this.unitSize,
    this.isHinted = false,
    this.dragOffset,
  });

  @override
  Widget build(BuildContext context) {
    const gap = 2.0;
    double left, top, width, height;
    if (car.orientation == CarOrientation.horizontal) {
      final baseLeft = car.col * unitSize;
      left = baseLeft + gap + (dragOffset?.dx ?? 0);
      top = car.row * unitSize + gap;
      width = car.length * unitSize - gap * 2;
      height = unitSize - gap * 2;
    } else {
      left = car.col * unitSize + gap;
      final baseTop = car.row * unitSize;
      top = baseTop + gap + (dragOffset?.dy ?? 0);
      width = unitSize - gap * 2;
      height = car.length * unitSize - gap * 2;
    }

    Widget svgContent = SvgPicture.asset(
      car.svgAsset,
      fit: BoxFit.contain,
    );

    // 垂直车使用 RotatedBox 旋转 90°
    if (car.orientation == CarOrientation.vertical) {
      svgContent = RotatedBox(
        quarterTurns: 1,
        child: svgContent,
      );
    }

    if (isHinted) {
      svgContent = Stack(
        children: [
          svgContent,
          Container(
            decoration: BoxDecoration(
              color: Colors.yellow.withAlpha(80),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: svgContent,
    );
  }
}
