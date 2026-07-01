import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../services/collision_detector.dart';
import 'game_grid.dart';

/// 游戏网格 Widget。
///
/// 使用 Stack 叠加：
///   - 下层：CustomPaint 绘制网格 + 出口 + 选中高亮
///   - 上层：Positioned CarSvgWidget 绘制每辆车
class GameGrid extends StatefulWidget {
  const GameGrid({super.key});

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid>
    with SingleTickerProviderStateMixin {
  String? _selectedCarId;
  CarOrientation? _dragOrientation;
  Offset? _fingerStartPos;
  Offset? _carStartPixelPos;
  Offset? _currentFingerPos;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final state = provider.state;
        if (state == null) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest.shortestSide;
            final unitSize = size / state.gridSize;

            return GestureDetector(
              onTapDown: (details) => _onTapDown(details, provider, unitSize),
              onPanStart: (details) =>
                  _onPanStart(details, provider, unitSize),
              onPanUpdate: (details) =>
                  _onPanUpdate(details, provider, unitSize),
              onPanEnd: (_) => _onPanEnd(provider),
              onPanCancel: _onPanCancel,
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  children: [
                    // 下层：网格 + 出口 + 选中高亮
                    CustomPaint(
                      size: Size(size, size),
                      painter: GridPainter(
                        state: state,
                        exit: state.exit,
                        unitSize: unitSize,
                        selectedCarId: _selectedCarId,
                      ),
                    ),
                    // 上层：每辆车
                    ...state.cars.map((car) {
                      final isSelected = car.id == _selectedCarId;
                      final dragOff = isSelected
                          ? _buildDragOffset(unitSize, state)
                          : null;
                      return CarSvgWidget(
                        key: ValueKey(car.id),
                        car: car,
                        unitSize: unitSize,
                        isHinted: car.id == provider.currentHint?.carId,
                        dragOffset: dragOff,
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Offset? _buildDragOffset(double unitSize, GameState state) {
    if (_selectedCarId == null ||
        _fingerStartPos == null ||
        _carStartPixelPos == null ||
        _currentFingerPos == null) {
      return null;
    }

    final carIdx = state.cars.indexWhere((c) => c.id == _selectedCarId);
    if (carIdx < 0) return null;
    final car = state.cars[carIdx];
    final carPixelX = car.col * unitSize;
    final carPixelY = car.row * unitSize;

    final fingerInCarOffset = Offset(
      _fingerStartPos!.dx - _carStartPixelPos!.dx,
      _fingerStartPos!.dy - _carStartPixelPos!.dy,
    );

    final targetX = _currentFingerPos!.dx - fingerInCarOffset.dx;
    final targetY = _currentFingerPos!.dy - fingerInCarOffset.dy;

    double dx = targetX - carPixelX;
    double dy = targetY - carPixelY;
    double rawPixelOffset;

    if (car.orientation == CarOrientation.horizontal) {
      rawPixelOffset = dx;
    } else {
      rawPixelOffset = dy;
    }

    if (rawPixelOffset.abs() >= 0.01) {
      final rawSteps = (rawPixelOffset / unitSize).round();
      final (minSteps, maxSteps) =
          CollisionDetector.getValidMoveRange(state, car);
      final clampedSteps = rawSteps.clamp(minSteps, maxSteps);
      final clampedPixel = clampedSteps * unitSize;

      if (car.orientation == CarOrientation.horizontal) {
        return Offset(clampedPixel, 0);
      }
      return Offset(0, clampedPixel);
    }

    if (car.orientation == CarOrientation.horizontal) {
      return Offset(dx, 0);
    }
    return Offset(0, dy);
  }

  void _onTapDown(
      TapDownDetails details, GameProvider provider, double unitSize) {
    final col = (details.localPosition.dx / unitSize).floor();
    final row = (details.localPosition.dy / unitSize).floor();
    final state = provider.state;
    if (state == null) return;
    final car = state.carAt(row, col);
    setState(() {
      _selectedCarId = car?.id;
      _resetDragState();
    });
  }

  void _onPanStart(
      DragStartDetails details, GameProvider provider, double unitSize) {
    final col = (details.localPosition.dx / unitSize).floor();
    final row = (details.localPosition.dy / unitSize).floor();
    final state = provider.state;
    if (state == null) return;
    final car = state.carAt(row, col);
    if (car == null) return;

    _animController.reset();
    setState(() {
      _selectedCarId = car.id;
      _dragOrientation = car.orientation;
      _fingerStartPos = details.localPosition;
      _currentFingerPos = details.localPosition;
      _carStartPixelPos = Offset(car.col * unitSize, car.row * unitSize);
    });
  }

  void _onPanUpdate(
      DragUpdateDetails details, GameProvider provider, double unitSize) {
    if (_selectedCarId == null ||
        _fingerStartPos == null ||
        _dragOrientation == null) {
      return;
    }
    final state = provider.state;
    if (state == null) return;

    final carIdx = state.cars.indexWhere((c) => c.id == _selectedCarId);
    if (carIdx < 0) {
      _resetDragState();
      return;
    }
    final car = state.cars[carIdx];

    _currentFingerPos = _currentFingerPos! + details.delta;

    double totalPixelDelta;
    if (_dragOrientation == CarOrientation.horizontal) {
      totalPixelDelta = _currentFingerPos!.dx - _fingerStartPos!.dx;
    } else {
      totalPixelDelta = _currentFingerPos!.dy - _fingerStartPos!.dy;
    }

    final steps = (totalPixelDelta / unitSize).round();
    if (steps.abs() >= 1) {
      final (minSteps, maxSteps) =
          CollisionDetector.getValidMoveRange(state, car);
      final clampedSteps = steps.clamp(minSteps, maxSteps);

      if (clampedSteps != 0) {
        final success = provider.moveCar(_selectedCarId!, clampedSteps);
        if (success) {
          _fingerStartPos = _currentFingerPos;
          _carStartPixelPos =
              Offset(car.col * unitSize, car.row * unitSize);
        }
      }
    }

    setState(() {});
  }

  void _onPanEnd(GameProvider provider) {
    setState(() {
      _selectedCarId = null;
      _resetDragState();
    });
  }

  void _onPanCancel() {
    setState(() {
      _selectedCarId = null;
      _resetDragState();
    });
  }

  void _resetDragState() {
    _dragOrientation = null;
    _fingerStartPos = null;
    _carStartPixelPos = null;
    _currentFingerPos = null;
  }
}
