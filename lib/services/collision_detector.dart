import '../models/car.dart';
import '../models/game_state.dart';

/// 碰撞检测器。
class CollisionDetector {
  /// 检测汽车移动 [steps] 步后是否会发生碰撞。
  ///
  /// [steps] 为正数表示向朝向正方向移动，为负数表示向反方向移动。
  /// 返回 `true` 表示将发生碰撞。
  static bool wouldCollide(GameState state, Car car, int steps) {
    final newCells = _getNewCells(car, steps);

    for (final cell in newCells) {
      final (row, col) = cell;

      // 检查是否超出网格边界
      if (row < 0 || row >= state.gridSize || col < 0 || col >= state.gridSize) {
        // 目标车辆从出口方向移出是允许的
        if (car.isTarget) {
          final goingRight = car.orientation == CarOrientation.horizontal && col >= state.gridSize;
          final goingDown = car.orientation == CarOrientation.vertical && row >= state.gridSize;
          if (goingRight || goingDown) continue;
        }
        return true; // 非出口方向越界
      }

      // 检查是否与其他车辆重叠
      if (state.carAt(row, col) case final otherCar?) {
        if (otherCar.id != car.id) return true;
      }
    }

    return false;
  }

  /// 计算移动 steps 步后车辆占据的新格子列表。
  static List<(int, int)> _getNewCells(Car car, int steps) {
    final cells = <(int, int)>[];
    for (int i = 0; i < car.length; i++) {
      if (car.orientation == CarOrientation.horizontal) {
        cells.add((car.row, car.col + i + steps));
      } else {
        cells.add((car.row + i + steps, car.col));
      }
    }
    return cells;
  }

  /// 获取车辆在合法移动范围内的最大步数。
  static (int minSteps, int maxSteps) getValidMoveRange(
      GameState state, Car car) {
    int min = 0;
    int max = 0;

    // 向后移动
    for (int steps = -1;; steps--) {
      if (wouldCollide(state, car, steps)) break;
      min = steps;
    }

    // 向前移动
    for (int steps = 1;; steps++) {
      if (wouldCollide(state, car, steps)) break;
      max = steps;
    }

    return (min, max);
  }
}
