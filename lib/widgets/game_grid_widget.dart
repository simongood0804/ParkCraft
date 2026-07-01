import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../services/collision_detector.dart';
import 'game_grid.dart';

/// 游戏网格 Widget（含手势交互——车辆跟随手指平滑移动）。
class GameGrid extends StatefulWidget {
  const GameGrid({super.key});

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid>
    with SingleTickerProviderStateMixin {
  String? _selectedCarId;
  CarOrientation? _dragOrientation;

  // 手指初始绝对位置（当前网格坐标系内）
  Offset? _fingerStartPos;
  // 车辆在拖拽开始时的网格像素位置
  Offset? _carStartPixelPos;
  // 当前帧的手指绝对位置
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
              child: CustomPaint(
                size: Size(size, size),
                painter: GridPainter(
                  state: state,
                  exit: state.exit,
                  unitSize: unitSize,
                  selectedCarId: _selectedCarId,
                  hintedCarId: provider.currentHint?.carId,
                  dragOffset: _buildDragOffset(unitSize, state),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 构造车辆视觉偏移量，自动约束到碰撞边界。
  ///
  /// 计算逻辑：车辆应出现在手指当前位置的正下方，但不得超过
  /// 碰撞检测允许的范围（不超出边界、不与其他车重叠）。
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

    // 手指在车内的初始偏移量（拖拽开始时，手指在车内点击的位置）
    final fingerInCarOffset = Offset(
      _fingerStartPos!.dx - _carStartPixelPos!.dx,
      _fingerStartPos!.dy - _carStartPixelPos!.dy,
    );

    // 车辆应出现的位置 = 手指当前位置 - 手指在车内偏移
    final targetCarPixelX = _currentFingerPos!.dx - fingerInCarOffset.dx;
    final targetCarPixelY = _currentFingerPos!.dy - fingerInCarOffset.dy;

    // 视觉偏移 = 目标位置 - 车辆当前网格位置
    double dx = targetCarPixelX - carPixelX;
    double dy = targetCarPixelY - carPixelY;
    double rawPixelOffset;

    if (car.orientation == CarOrientation.horizontal) {
      rawPixelOffset = dx;
    } else {
      rawPixelOffset = dy;
    }

    // 将像素偏移转为网格步数，并用碰撞检测约束
    final rawSteps = (rawPixelOffset / unitSize);
    // 仅在实际显着偏移时才做约束，避免浮点误差导致微抖动
    if (rawSteps.abs() >= 0.01) {
      final roundedSteps = rawSteps.round();
      final (minSteps, maxSteps) =
          CollisionDetector.getValidMoveRange(state, car);
      final clampedSteps = roundedSteps.clamp(minSteps, maxSteps);

      // 将约束后的步数转回像素
      final clampedPixel = clampedSteps * unitSize;

      if (car.orientation == CarOrientation.horizontal) {
        return Offset(clampedPixel, 0);
      }
      return Offset(0, clampedPixel);
    }

    // 偏移过小，直接返回朝向方向的偏移
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
      _carStartPixelPos = Offset(
        car.col * unitSize,
        car.row * unitSize,
      );
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

    // 更新当前手指位置（累加增量）
    _currentFingerPos = _currentFingerPos! + details.delta;

    // 计算从拖拽开始到现在的总像素位移（在朝向方向上）
    double totalPixelDelta;
    if (_dragOrientation == CarOrientation.horizontal) {
      totalPixelDelta = _currentFingerPos!.dx - _fingerStartPos!.dx;
    } else {
      totalPixelDelta = _currentFingerPos!.dy - _fingerStartPos!.dy;
    }

    // 如果累积像素偏移超过 1 格，尝试提交网格移动
    final steps = (totalPixelDelta / unitSize).round();
    if (steps.abs() >= 1) {
      final (minSteps, maxSteps) =
          CollisionDetector.getValidMoveRange(state, car);
      final clampedSteps = steps.clamp(minSteps, maxSteps);

      if (clampedSteps != 0) {
        final success = provider.moveCar(_selectedCarId!, clampedSteps);
        if (success) {
          // 重置起始参考点，使 totalPixelDelta 重新从 0 开始累积
          _fingerStartPos = _currentFingerPos;
          _carStartPixelPos = Offset(car.col * unitSize, car.row * unitSize);
        }
      }
    }

    // 刷新 UI 以更新视觉偏移
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
