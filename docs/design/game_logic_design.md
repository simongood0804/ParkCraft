# 游戏逻辑模块详细设计

- **模块编号**：M3
- **对应文件**：
  - `lib/services/game_engine.dart`
  - `lib/services/collision_detector.dart`
  - `lib/services/undo_manager.dart`
  - `lib/services/stats_tracker.dart`
- **依赖模块**：M1（数据模型）、M2（网格 — 回调调用）

---

## 1. 职责

实现游戏核心逻辑的完整闭环：
1. 加载关卡并初始化网格状态
2. 校验车辆移动的合法性
3. 执行移动并更新状态
4. 胜利条件判定
5. 管理撤销栈
6. 统计步数和计时

---

## 2. 数据模型

### 2.1 GridState

```dart
class GridState {
  final int gridSize;
  final List<Car> cars;         // 所有车辆（含目标车辆）
  final Exit exit;
  final String targetCarId;     // 目标车辆的 ID

  /// 获取指定位置的车辆（无车返回 null）
  Car? carAt(int row, int col);

  /// 序列化为字符串（用于 BFS 判重）
  String serialize();

  /// 深拷贝
  GridState copyWith({List<Car>? cars});
}
```

### 2.2 GridSnapshot

撤销栈中存储的最小状态信息，仅记录变动部分以节省内存：

```dart
class GridSnapshot {
  final String carId;
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
}
```

### 2.3 LevelStats

```dart
class LevelStats {
  final String levelId;
  final int bestMoves;
  final int bestTimeSeconds;
  final bool completed;
  final DateTime? lastPlayedAt;
}
```

---

## 3. GameEngine 设计

```dart
class GameEngine {
  /// 加载关卡，初始化 GridState
  GridState loadLevel(Level level);

  /// 尝试移动车辆 steps 步（正数=正向，负数=反向）
  /// 返回移动是否成功
  bool tryMove(GridState state, String carId, int steps);

  /// 获取车辆在当前位置的合法移动范围
  /// 返回 [minSteps, maxSteps]（负值表示向后移动）
  (int minSteps, int maxSteps) getValidMoveRange(GridState state, String carId);

  /// 判断是否达成胜利条件
  bool checkWin(GridState state);
}
```

---

## 4. CollisionDetector 设计

```dart
class CollisionDetector {
  /// 检测车辆移动 steps 步后是否与其他车辆或边界碰撞
  /// steps 为正数：朝向 orientation 正向
  /// steps 为负数：朝向 orientation 反向
  static bool wouldCollide(GridState state, Car car, int steps);

  /// 获取车辆占用的所有格子坐标
  static List<(int row, int col)> getOccupiedCells(Car car);

  /// 检测指定位置是否被占用（被 cars 中除 excludeId 外的车辆占据）
  static bool isCellOccupied(GridState state, int row, int col, {String? excludeId});
}
```

碰撞检测核心逻辑：

```
输入：car, steps

1. 计算移动后车辆占据的所有新格子坐标
   - 水平车：向前 mobileSteps 格 → (row, col + steps) ~ (row, col + length - 1 + steps)
   - 垂直车类似

2. 遍历新格子列表：
   a. 检查是否超出网格边界（0 <= row/col < gridSize）
      ├── 超出 → 若该方向为出口方向且车轮为目标车 → 合法（驶出）
      └── 超出 → 否则 → 碰撞，返回 true
   b. 检查该格子是否被其他车辆占据（排除自身）
      ├── 是 → 碰撞，返回 true
      └── 否 → 继续

3. 所有格子通过 → 不碰撞，返回 false
```

---

## 5. UndoManager 设计

```dart
class UndoManager {
  final List<GridSnapshot> _stack = [];
  static const int MAX_STACK_SIZE = 200; // 防止无限增长

  /// 记录移动前的状态快照
  void recordBeforeMove(GridState state, String carId);

  /// 撤销最近一步
  GridSnapshot? undo();

  /// 清空撤销栈（重开关卡时调用）
  void clear();

  /// 是否可撤销
  bool get canUndo => _stack.isNotEmpty;
}
```

---

## 6. StatsTracker 设计

```dart
class StatsTracker {
  int _moveCount = 0;
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final VoidCallback? onTick; // 每秒回调，用于 UI 更新

  /// 初始化/重置
  void reset();

  /// 记录一步移动
  void recordMove();

  /// 开始计时
  void start();

  /// 暂停计时
  void pause();

  /// 继续计时
  void resume();

  /// 停止计时
  void stop();

  // Getters
  int get moveCount => _moveCount;
  int get elapsedSeconds => _stopwatch.elapsedMilliseconds ~/ 1000;
}
```

---

## 7. 胜利判定

```dart
bool checkWin(GridState state) {
  final targetCar = state.cars.firstWhere((c) => c.id == state.targetCarId);

  // 水平目标车，出口在右侧 → 判断车头(col + length - 1)是否 >= gridSize
  // 垂直目标车，出口在底部 → 判断车尾(row + length - 1)是否 >= gridSize
  if (targetCar.orientation == Orientation.horizontal && state.exit.orientation == Orientation.horizontal) {
    return targetCar.col + targetCar.length > state.gridSize;
  } else if (targetCar.orientation == Orientation.vertical && state.exit.orientation == Orientation.vertical) {
    return targetCar.row + targetCar.length > state.gridSize;
  }
  return false;
}
```

---

## 8. 游戏主流程代码逻辑

```
loadLevel(level)
    │
    ▼
GameEngine.loadLevel → 返回初始 GridState
    │
    ▼
UndoManager.clear()
StatsTracker.reset()
    │
    ▼
UI 渲染

=== 循环 ===

用户拖拽 → GameGrid 解析为 moveCar(carId, steps)
    │
    ▼
GameEngine.tryMove(state, carId, steps)
    │
    ├── CollisionDetector.wouldCollide() ── 碰撞 → 返回 false（UI 抖动反馈）
    │
    ▼ 无碰撞
UndoManager.recordBeforeMove(state, carId)
    │
    ▼
更新 GridState 中 car 的 row/col
StatsTracker.recordMove()
    │
    ▼
GameEngine.checkWin()
    │
    ├── true → 触发通关流程（停止计时、保存成绩）
    │
    └── false → 等待下一次操作

=== 撤销 ===

undo()
    │
    ▼
UndoManager.undo() → GridSnapshot
    │
    ▼
恢复 GridState 中对应车辆的位置
StatsTracker 步数 - 1（但不减到 0 以下）
```

---

## 9. 单元测试要点

| 测试用例 | 预期 |
|----------|------|
| 水平车向前移动 1 格（无障碍） | 成功，位置更新 |
| 水平车移动后与其他车重叠 | CollisionDetector 返回 true |
| 水平车移动到边界外（非出口方向） | 碰撞 |
| 目标车移动到出口边界外 | checkWin 返回 true |
| 连续撤销到初始状态 | 状态完全恢复 |
| 撤销超过最大栈深度 | 最早的历史被丢弃 |
| 移动非法车辆 ID | 返回 false |
| 垂直车向上移动 | 正确计算 |
| 步数统计从 0 开始，每次移动 +1 | 计数正确 |
| 停止/暂停/继续计时 | 累计时间正确 |
