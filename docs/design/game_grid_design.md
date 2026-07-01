# 游戏网格模块详细设计

- **模块编号**：M2
- **对应文件**：`lib/widgets/game_grid.dart`、`lib/widgets/car_widget.dart`、`lib/widgets/exit_marker.dart`
- **依赖模块**：M3（游戏逻辑模块 — 获取 GridState）、M1（数据模型）

---

## 1. 职责

负责游戏网格的视觉渲染和手势交互，包括：
1. 根据当前 `GridState` 绘制 N×N 网格及所有车辆
2. 处理玩家的点击/拖拽手势并转化为车辆移动指令
3. 在出口位置绘制出口标记
4. 播放车辆移动动画

---

## 2. 类设计

### 2.1 GameGrid (StatefulWidget)

```dart
class GameGrid extends StatefulWidget {
  final GridState state;
  final void Function(String carId, int steps) onMoveCar; // 移动回调
  final bool animationEnabled; // 是否启用动画
}
```

#### 内部状态
```dart
class _GameGridState extends State<GameGrid> with SingleTickerProviderStateMixin {
  String? _selectedCarId;       // 当前选中的车辆 ID
  Offset? _dragStartPosition;   // 拖拽起始位置
  AnimationController? _animController;
}
```

### 2.2 ExitMarker (StatelessWidget)

```dart
class ExitMarker extends StatelessWidget {
  final Exit exit;
  final double gridUnitSize; // 每格的像素尺寸
}
```

### 2.3 CarWidget (StatelessWidget)

其实网格内的车辆不推荐作为独立 Widget，而是由 `GameGrid` 在 `CustomPainter` 中集中绘制（见下文）。

---

## 3. 渲染策略

### 3.1 使用 CustomPainter

**理由**：车辆数量有限（通常 ≤ 10 辆），但频繁重绘，`CustomPainter` 性能优于多层 Widget 组合。

```dart
class GridPainter extends CustomPainter {
  final GridState state;
  final Exit exit;
  final double gridUnitSize;
  final String? selectedCarId;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas);      // 网格线
    _drawExit(canvas);      // 出口标记
    _drawCars(canvas);      // 所有车辆
    _drawSelection(canvas); // 选中高亮
  }

  @override
  bool shouldRepaint(GridPainter old) => old.state != state;
}
```

### 3.2 视觉参数

| 参数 | 值 |
|------|-----|
| 网格线宽 | 1.5 px，颜色 `Colors.grey.shade300` |
| 网格单元尺寸 | `min(可用宽度, 可用高度) / N`，保证正方形 |
| 目标车辆颜色 | `Colors.redAccent` |
| 堵塞车辆颜色 | 从预设色板循环分配（蓝、绿、橙、紫、青） |
| 选中高亮 | 外发光 + 轻微缩放 |
| 出口标记 | 箭头图标或半透明高亮矩形 |
| 网格间距 | 单元之间留 2px 间隙，模拟车辆块效果 |

---

## 4. 手势处理

### 4.1 点击选中
```
用户点击网格中某一位置
    │
    ▼
计算点击位置所在的 (row, col)
    │
    ▼
遍历所有车辆，判断该格子是否属于某辆车
    │
    ├── 是 → 选中该车辆，高亮显示
    └── 否 → 取消选中
```

### 4.2 拖拽移动
```
用户在选中的车辆上拖拽
    │
    ▼
计算拖拽方向（水平/垂直，取偏移量较大的轴）
    │
    ▼
判断拖拽方向是否与车辆朝向一致
    │
    ├── 不一致 → 拒绝拖拽，无操作
    │
    ▼ 一致
根据拖拽距离计算期望移动步数
    │
    ▼
调用 GameEngine.getValidMoves() 获取合法移动范围
    │
    ▼
约束移动步数到合法范围内
    │
    ▼
调用 onMoveCar(carId, steps) 回传 → GameEngine 执行移动
    │
    ▼
播放移动动画（平滑过渡到目标位置）
```

### 4.3 触控反馈
- 选中车辆时触发短震动（如设置开启）
- 拖拽过程中车辆跟随手指位置（半透明预览）
- 非法移动时车辆轻微抖动回弹

---

## 5. 动画设计

### 5.1 移动动画
- 使用 `AnimationController` 驱动车辆从 A 点平滑移动到 B 点
- 持续时长：150ms ~ 200ms
- 缓动曲线：`Curves.easeInOut`

### 5.2 通关动画
- 目标车辆沿出口方向匀速驶出屏幕
- 持续时长：500ms
- 驶出后触发通关弹窗

---

## 6. 布局计算

```dart
/// 计算每个网格单元的像素尺寸
double _calculateUnitSize(double containerWidth, double containerHeight) {
  final double size = min(containerWidth, containerHeight);
  return size / widget.state.gridSize;
}
```

车辆像素位置计算：
```dart
Rect _getCarRect(Car car, double unitSize) {
  final double left = car.col * unitSize + gap;
  final double top = car.row * unitSize + gap;
  final double width = car.orientation == Orientation.horizontal
      ? car.length * unitSize - gap * 2
      : unitSize - gap * 2;
  final double height = car.orientation == Orientation.vertical
      ? car.length * unitSize - gap * 2
      : unitSize - gap * 2;
  return Rect.fromLTWH(left, top, width, height);
}
```

---

## 7. 可访问性

- 每辆车添加 `Semantics` 标签："{id}车，{朝向}，位置第{row}行第{col}列"
- 出口添加标签："出口"
