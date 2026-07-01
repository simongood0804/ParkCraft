# 提示系统模块详细设计

- **模块编号**：M7
- **对应文件**：`lib/services/hint_solver.dart`
- **依赖模块**：M3（游戏逻辑引擎 — 移动校验/判胜/GridState）

---

## 1. 职责

为玩家提供通关提示，具体功能：
1. 根据当前局面计算出下一步最优移动建议
2. 在后台求出完整最优解（最少步数路径）
3. 在当前关卡无法解出时友好提示

---

## 2. 算法选型：广度优先搜索 (BFS)

**理由**：
- N×N 网格规模有限（3 ≤ N ≤ 12），车辆数有限（通常 ≤ 10），状态空间可控
- BFS 天然保证找到的路径是**最少步数**
- 实现简单，不涉及启发式函数的调优

---

## 3. HintSolver 设计

```dart
class HintSolver {
  /// 求解从当前状态到胜利的最少步数路径
  /// 返回 Move 列表（顺序执行），不可解返回空列表
  List<Move> solve(GridState state);

  /// 仅获取下一步建议
  Move? getNextHint(GridState state);

  /// BFS 搜索（内部实现）
  List<Move> _bfs(GridState startState);

  /// 获取当前状态的所有合法后继移动
  List<Move> _getAllPossibleMoves(GridState state);
}

class Move {
  final String carId;
  final int steps; // 正数=朝向正向，负数=朝向反向
}
```

---

## 4. BFS 搜索算法

```dart
List<Move> _bfs(GridState startState) {
  final queue = Queue<(GridState, List<Move>)>();
  final visited = HashSet<String>();
  const int maxStates = 100000; // 状态上限

  queue.add((startState, []));
  visited.add(startState.serialize());

  while (queue.isNotEmpty) {
    if (visited.length > maxStates) break; // 防止无限搜索

    final (currentState, path) = queue.removeFirst();

    // 检查是否胜利
    if (_gameEngine.checkWin(currentState)) {
      return path; // 返回完整路径
    }

    // 遍历所有可能的移动
    for (final move in _getAllPossibleMoves(currentState)) {
      final nextState = _applyMove(currentState, move);
      final serialized = nextState.serialize();

      if (!visited.contains(serialized)) {
        visited.add(serialized);
        queue.add((nextState, [...path, move]));
      }
    }
  }

  return []; // 不可解或超时
}
```

### 4.1 状态序列化（判重 key）

```dart
// GridState 序列化方法
String serialize() {
  // 按车辆 ID 排序后，生成 "carId:row:col" 的拼接字符串
  final sortedCars = List<Car>.from(cars)
    ..sort((a, b) => a.id.compareTo(b.id));

  return sortedCars
    .map((c) => '${c.id}:${c.row}:${c.col}')
    .join('|');
}
```

示例：`"A:0:0|B:2:0|C:2:2|D:2:3|E:4:1|T:2:0"`

### 4.2 生成所有合法后继移动

```dart
List<Move> _getAllPossibleMoves(GridState state) {
  final moves = <Move>[];

  for (final car in state.cars) {
    final (minSteps, maxSteps) = _gameEngine.getValidMoveRange(state, car.id);

    // 对于每个可能的合法步数（跳过 0）
    for (int s = minSteps; s <= maxSteps; s++) {
      if (s == 0) continue;
      moves.add(Move(carId: car.id, steps: s));
    }
  }

  return moves;
}
```

> **优化**：由于车辆连续移动多步在 BFS 中不会产生新路径（因为中间步骤也被包含在其他分支中），可以只考虑移动 1 步或直接移动到最大合法位置。这里为了提示质量，保留所有单步移动，让 BFS 生成最优路径。

---

## 5. 性能优化策略

| 策略 | 说明 |
|------|------|
| 状态判重 | 使用 `HashSet<String>`，O(1) 查重 |
| 最大状态数限制 | `maxStates = 100000`，超时自动放弃 |
| 初始预判 | 如果直接出口方向无阻挡，直接返回建议（跳过 BFS） |
| 缓存求解结果 | 同一关卡的同一状态不重复求解 |
| Isolate 异步计算 | BFS 在独立 Isolate 中运行，不阻塞 UI |

### 5.1 Isolate 执行

```dart
Future<List<Move>> solveAsync(GridState state) async {
  // 简单关卡可直接计算，复杂关卡交给 Isolate
  final carCount = state.cars.length;
  if (carCount <= 6) {
    return compute(_solveInIsolate, state);
  }
  return solve(state); // 主线程计算（状态空间仍可控）
}

// 必须在顶层函数，供 Isolate 调用
List<Move> _solveInIsolate(GridState state) {
  final solver = HintSolver();
  return solver.solve(state);
}
```

---

## 6. 提示触发流程

```
用户点击"提示"按钮
    │
    ▼
GameProvider.onHintRequested()
    │
    ├── 1. 从当前 GridState 获取 HintSolver.getNextHint()
    │       │
    │       ├── 返回 Move → 高亮对应车辆（闪烁/箭头）
    │       │               → 可选：自动执行该步
    │       │
    │       └── 返回 null → 显示 SnackBar "暂无可用的提示"
    │
    └── 2. 提示使用次数不限制（但 UI 可标注已使用次数，可选功能）
```

---

## 7. 提示的视觉表现

- 目标车辆闪烁（透明度来回变化）
- 或箭头指向目标车辆和移动方向
- 或轻微缩放动画引起注意

```dart
class HintOverlay extends StatefulWidget {
  final Move hintMove;
  final GridState state;
  final double gridUnitSize;
}
```

---

## 8. 单元测试要点

| 测试用例 | 预期 |
|----------|------|
| 简单关卡（一步即胜） | 返回包含一个 Move 的路径 |
| 中等难度关卡 | 返回最少步数路径（步数可人工验证） |
| 已胜利的状态 | 返回空列表 |
| 不可解的关卡（故意构造） | 返回空列表，不崩溃 |
| 状态序列化唯一性 | 相同布局序列化结果相同 |
| 状态序列化区分 | 不同布局序列化结果不同 |
| 超大状态空间（自动放弃） | 返回空列表，不超时崩溃 |
