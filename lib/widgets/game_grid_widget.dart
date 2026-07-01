import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../services/collision_detector.dart';
import 'game_grid.dart';

/// 游戏网格 Widget（含手势交互与移动动画）。
class GameGrid extends StatefulWidget {
  const GameGrid({super.key});

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid>
    with SingleTickerProviderStateMixin {
  String? _selectedCarId;
  CarOrientation? _dragOrientation;
  Offset? _dragStartFinger;
  Offset? _dragCarOffset;
  double? _unitSize;

  double _carStartPixelX = 0;
  double _carStartPixelY = 0;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _animController.addListener(() => setState(() {}));
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
            _unitSize = size / state.gridSize;

            return GestureDetector(
              onTapDown: (details) =>
                  _onTapDown(details, provider, _unitSize!),
              onPanStart: (details) =>
                  _onPanStart(details, provider, _unitSize!),
              onPanUpdate: (details) =>
                  _onPanUpdate(details, provider, _unitSize!),
              onPanEnd: (_) => _onPanEnd(provider),
              onPanCancel: _onPanCancel,
              child: CustomPaint(
                size: Size(size, size),
                painter: GridPainter(
                  state: state,
                  exit: state.exit,
                  unitSize: _unitSize!,
                  selectedCarId: _selectedCarId,
                  hintedCarId: provider.currentHint?.carId,
                  dragOffset: _dragCarOffset,
                ),
              ),
            );
          },
        );
      },
    );
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
      _dragOrientation = null;
      _dragStartFinger = null;
      _dragCarOffset = null;
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
      _dragStartFinger = details.localPosition;
      _dragCarOffset = Offset.zero;
      _carStartPixelX = car.col * unitSize;
      _carStartPixelY = car.row * unitSize;
    });
  }

  void _onPanUpdate(
      DragUpdateDetails details, GameProvider provider, double unitSize) {
    if (_selectedCarId == null ||
        _dragStartFinger == null ||
        _dragOrientation == null) {
      return;
    }

    final state = provider.state;
    if (state == null) return;

    final car = state.cars.firstWhere((c) => c.id == _selectedCarId);
    final currentFinger = _dragStartFinger! + details.delta;

    double rawOffset;
    if (_dragOrientation == CarOrientation.horizontal) {
      rawOffset = currentFinger.dx - _dragStartFinger!.dx;
    } else {
      rawOffset = currentFinger.dy - _dragStartFinger!.dy;
    }

    final steps = (rawOffset / unitSize);
    final roundedSteps = steps.round();

    if (roundedSteps != 0) {
      final (minSteps, maxSteps) =
          CollisionDetector.getValidMoveRange(state, car);
      final clampedSteps = roundedSteps.clamp(minSteps, maxSteps);

      if (clampedSteps != 0) {
        provider.moveCar(_selectedCarId!, clampedSteps);
        setState(() {
          _dragStartFinger = currentFinger;
          _dragCarOffset = Offset.zero;
        });
        return;
      }
    }

    final clampedPixel = rawOffset.clamp(
      _dragOrientation == CarOrientation.horizontal
          ? -_carStartPixelX
          : -_carStartPixelY,
      _dragOrientation == CarOrientation.horizontal
          ? (state.gridSize - car.col - car.length) * unitSize
          : (state.gridSize - car.row - car.length) * unitSize,
    );

    if (_dragOrientation == CarOrientation.horizontal) {
      _dragCarOffset = Offset(clampedPixel, 0);
    } else {
      _dragCarOffset = Offset(0, clampedPixel);
    }

    _clampOffsetByCollision(state, car, unitSize);
    setState(() {});
  }

  void _clampOffsetByCollision(
      GameState state, Car car, double unitSize) {
    final offset = _dragCarOffset!.dx + _dragCarOffset!.dy;
    final testSteps = (offset / unitSize).round();
    if (testSteps == 0) {
      return;
    }

    if (CollisionDetector.wouldCollide(state, car, testSteps)) {
      int safe = 0;
      int unsafe = testSteps;
      while ((unsafe - safe).abs() > 1) {
        final mid = (safe + unsafe) ~/ 2;
        if (CollisionDetector.wouldCollide(state, car, mid)) {
          unsafe = mid;
        } else {
          safe = mid;
        }
      }
      final safePixel = safe * unitSize;
      if (_dragOrientation == CarOrientation.horizontal) {
        _dragCarOffset = Offset(safePixel, 0);
      } else {
        _dragCarOffset = Offset(0, safePixel);
      }
    }
  }

  void _onPanEnd(GameProvider provider) {
    if (_selectedCarId == null || _dragCarOffset == null) return;

    final state = provider.state;
    if (state != null) {
      final offset = _dragCarOffset!.dx + _dragCarOffset!.dy;
      final steps = (offset / _unitSize!).round();
      if (steps.abs() >= 1) {
        provider.moveCar(_selectedCarId!, steps);
      }
    }

    setState(() {
      _selectedCarId = null;
      _dragOrientation = null;
      _dragStartFinger = null;
      _dragCarOffset = null;
    });
  }

  void _onPanCancel() {
    setState(() {
      _selectedCarId = null;
      _dragOrientation = null;
      _dragStartFinger = null;
      _dragCarOffset = null;
    });
  }
}
