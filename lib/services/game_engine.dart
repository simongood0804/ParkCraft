import '../models/car.dart';
import '../models/game_state.dart';
import '../models/level.dart';
import 'collision_detector.dart';

/// 移动操作。
class Move {
  final String carId;
  final int steps;
  Move(this.carId, this.steps);

  @override
  String toString() => 'Move($carId, $steps)';
}

/// 游戏引擎。
class GameEngine {
  /// 加载关卡，返回初始 GameState。
  GameState loadLevel(Level level) {
    return GameState.fromLevel(level);
  }

  /// 尝试移动车辆 [steps] 步。
  ///
  /// 返回移动是否成功。成功时 [state] 会被直接修改。
  bool tryMove(GameState state, String carId, int steps) {
    final car = _findCar(state, carId);
    if (car == null) return false;

    if (CollisionDetector.wouldCollide(state, car, steps)) return false;

    if (car.orientation == CarOrientation.horizontal) {
      car.col += steps;
    } else {
      car.row += steps;
    }

    return true;
  }

  /// 获取车辆的合法移动范围 [minSteps, maxSteps]。
  (int min, int max) getValidMoveRange(GameState state, String carId) {
    final car = _findCar(state, carId);
    if (car == null) return (0, 0);
    return CollisionDetector.getValidMoveRange(state, car);
  }

  /// 检查目标车辆是否已完全驶出出口。
  bool checkWin(GameState state) {
    final target = state.targetCar;

    if (target.orientation == CarOrientation.horizontal) {
      return target.col + target.length > state.gridSize;
    }
    // vertical
    return target.row + target.length > state.gridSize;
  }

  Car? _findCar(GameState state, String carId) {
    for (final car in state.cars) {
      if (car.id == carId) return car;
    }
    return null;
  }

  /// 从状态生成所有合法的单步后继移动。
  List<Move> getAllPossibleMoves(GameState state) {
    final moves = <Move>[];
    for (final car in state.cars) {
      final (min, max) = getValidMoveRange(state, car.id);
      // 仅生成单步移动（BFS 使用）
      if (min < 0) moves.add(Move(car.id, -1));
      if (max > 0) moves.add(Move(car.id, 1));
    }
    return moves;
  }

  /// 应用移动并返回新的状态（不修改原状态）。
  GameState applyMove(GameState state, Move move) {
    final newCars = state.cars.map((c) {
      if (c.id != move.carId) return c.copyWith();
      if (c.orientation == CarOrientation.horizontal) {
        return c.copyWith(col: c.col + move.steps);
      }
      return c.copyWith(row: c.row + move.steps);
    }).toList();

    return state.copyWith(cars: newCars);
  }
}
