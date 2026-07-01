import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/car.dart';
import '../models/exit.dart';
import '../config/theme.dart';

/// 网格绘制器。
class GridPainter extends CustomPainter {
  final GameState state;
  final Exit exit;
  final double unitSize;
  final String? selectedCarId;
  final String? hintedCarId;
  final Offset? dragOffset;

  GridPainter({
    required this.state,
    required this.exit,
    required this.unitSize,
    this.selectedCarId,
    this.hintedCarId,
    this.dragOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawExit(canvas);
    _drawCars(canvas);
    _drawSelection(canvas);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.5;

    for (int i = 0; i <= state.gridSize; i++) {
      final pos = i * unitSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), paint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), paint);
    }
  }

  void _drawExit(Canvas canvas) {
    final exitRect = _getExitRect();
    final paint = Paint()..color = Colors.green.withAlpha(60);
    canvas.drawRect(exitRect, paint);

    // 出口箭头标记 — 在出口中间画一个三角形
    final arrowPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    final path = Path();
    final cx = exitRect.center.dx;
    final cy = exitRect.center.dy;
    final half = unitSize * 0.25;
    if (exit.orientation == CarOrientation.horizontal) {
      // 向右箭头
      path.moveTo(cx + half, cy);
      path.lineTo(cx - half, cy - half);
      path.lineTo(cx - half, cy + half);
    } else {
      // 向下箭头
      path.moveTo(cx, cy + half);
      path.lineTo(cx - half, cy - half);
      path.lineTo(cx + half, cy - half);
    }
    path.close();
    canvas.drawPath(path, arrowPaint);
  }

  void _drawCars(Canvas canvas) {
    for (final car in state.cars) {
      final isSelected = car.id == selectedCarId;

      Rect rect;
      if (isSelected && dragOffset != null) {
        rect = _getCarRectWithOffset(car, dragOffset!);
      } else {
        rect = _getCarRect(car);
      }

      final color = car.isTarget
          ? AppTheme.targetCarColor
          : _getCarColor(car);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        paint,
      );

      // 提示高亮
      if (car.id == hintedCarId) {
        final hintPaint = Paint()
          ..color = Colors.yellow.withAlpha(100)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          hintPaint,
        );
      }
    }
  }

  /// 独立绘制选中高亮（外发光）。
  void _drawSelection(Canvas canvas) {
    if (selectedCarId == null) return;

    final car = state.cars.firstWhere(
      (c) => c.id == selectedCarId,
      orElse: () => state.cars.first,
    );
    if (car.id != selectedCarId) return;

    final rect = _getCarRect(car);

    // 外层发光：绘制一个放大的半透明亚克力框
    final glowPaint = Paint()
      ..color = Colors.white.withAlpha(50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.fill;
    final glowRect = rect.inflate(4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glowRect, const Radius.circular(8)),
      glowPaint,
    );

    // 白色边框
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      borderPaint,
    );
  }

  Rect _getCarRect(Car car) {
    const gap = 2.0;
    final left = car.col * unitSize + gap;
    final top = car.row * unitSize + gap;
    if (car.orientation == CarOrientation.horizontal) {
      return Rect.fromLTWH(left, top,
          car.length * unitSize - gap * 2, unitSize - gap * 2);
    }
    return Rect.fromLTWH(left, top,
        unitSize - gap * 2, car.length * unitSize - gap * 2);
  }

  Rect _getCarRectWithOffset(Car car, Offset offset) {
    const gap = 2.0;
    final baseLeft = car.col * unitSize + gap;
    final baseTop = car.row * unitSize + gap;

    if (car.orientation == CarOrientation.horizontal) {
      final left = baseLeft + offset.dx;
      return Rect.fromLTWH(
          left, baseTop, car.length * unitSize - gap * 2, unitSize - gap * 2);
    }
    final top = baseTop + offset.dy;
    return Rect.fromLTWH(
        baseLeft, top, unitSize - gap * 2, car.length * unitSize - gap * 2);
  }

  Rect _getExitRect() {
    if (exit.orientation == CarOrientation.horizontal) {
      return Rect.fromLTWH(
        exit.col * unitSize,
        exit.row * unitSize,
        unitSize,
        unitSize,
      );
    }
    return Rect.fromLTWH(
      exit.col * unitSize,
      exit.row * unitSize,
      unitSize,
      unitSize,
    );
  }

  Color _getCarColor(Car car) {
    final index = state.cars.indexOf(car);
    return AppTheme.getCarColor(index);
  }

  @override
  bool shouldRepaint(GridPainter old) =>
      old.state != state ||
      old.selectedCarId != selectedCarId ||
      old.hintedCarId != hintedCarId ||
      old.dragOffset != dragOffset;
}
