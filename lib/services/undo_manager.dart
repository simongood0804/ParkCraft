import '../models/game_state.dart';
import '../config/constants.dart';

/// 撤销快照：记录车辆移动前的位置。
class GridSnapshot {
  final String carId;
  final int fromRow;
  final int fromCol;

  GridSnapshot({
    required this.carId,
    required this.fromRow,
    required this.fromCol,
  });
}

/// 撤销管理器。
class UndoManager {
  final List<GridSnapshot> _stack = [];

  /// 记录移动前的状态快照。
  void recordBeforeMove(GameState state, String carId) {
    final car = state.cars.firstWhere((c) => c.id == carId);
    _stack.add(GridSnapshot(carId: carId, fromRow: car.row, fromCol: car.col));

    // 限制栈大小
    if (_stack.length > appMaxUndoStack) {
      _stack.removeAt(0);
    }
  }

  /// 撤销最近一步。
  GridSnapshot? undo() {
    if (_stack.isEmpty) return null;
    return _stack.removeLast();
  }

  /// 清空撤销栈。
  void clear() {
    _stack.clear();
  }

  /// 是否可撤销。
  bool get canUndo => _stack.isNotEmpty;

  /// 当前栈深度。
  int get stackSize => _stack.length;
}
