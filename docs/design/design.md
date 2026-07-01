# ParkCraft 设计文档

## 1. 概要设计

### 1.1 文档目的
本文档描述 ParkCraft 停车出库益智游戏的总体架构设计、模块划分、技术选型理由及模块间交互关系。各子模块的详细设计以独立文档呈现，见 `docs/design/` 目录。

### 1.2 总体架构

ParkCraft 采用**分层架构**（Layered Architecture），从上至下分为三层：

```
┌─────────────────────────────────────────────────────┐
│                     UI 层                             │
│  ┌─────────┐ ┌──────────┐ ┌──────┐ ┌────────┐      │
│  │ 启动页   │ │ 主菜单页  │ │关卡选择│ │ 设置页  │      │
│  └─────────┘ └──────────┘ └──────┘ └────────┘      │
│  ┌─────────────────────────────────────────────┐    │
│  │              游戏页 (GamePage)                 │    │
│  │  ┌───────────┐ ┌──────────┐ ┌───────────┐   │    │
│  │  │ 信息栏     │ │ 游戏网格  │ │ 操作按钮栏  │   │    │
│  │  └───────────┘ └──────────┘ └───────────┘   │    │
│  └─────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────┤
│                  业务逻辑层                           │
│  ┌────────────┐ ┌────────────┐ ┌──────────────┐    │
│  │ 游戏引擎    │ │ 关卡管理器  │ │ 提示系统      │    │
│  │ GameEngine  │ │ LevelMgr   │ │ HintSystem   │    │
│  └────────────┘ └────────────┘ └──────────────┘    │
│  ┌────────────┐ ┌────────────┐ ┌──────────────┐    │
│  │ 碰撞检测    │ │ 撤销管理器  │ │ 计时器/步数   │    │
│  │ Collision   │ │ UndoMgr    │ │ StatsTracker │    │
│  └────────────┘ └────────────┘ └──────────────┘    │
├─────────────────────────────────────────────────────┤
│                    数据层                             │
│  ┌──────────────┐ ┌────────────┐ ┌──────────────┐  │
│  │ 关卡配置解析器 │ │ 持久化存储  │ │ 音效/国际化   │  │
│  │ LevelParser   │ │ Storage    │ │ Audio/i18n   │  │
│  └──────────────┘ └────────────┘ └──────────────┘  │
└─────────────────────────────────────────────────────┘
```

### 1.3 模块划分

| 模块编号 | 模块名称 | 职责 |
|----------|----------|------|
| M1 | 关卡配置模块 | 解析 JSON/YAML 配置文件，构建数据模型 |
| M2 | 游戏网格模块 | 网格渲染、车辆绘制、选中/拖拽交互 |
| M3 | 游戏逻辑模块 | 核心游戏引擎：移动校验、碰撞检测、胜负判定、撤销 |
| M4 | 关卡管理模块 | 关卡列表维护、解锁逻辑、快速导入 |
| M5 | 用户界面模块 | 所有页面的 Widget 组合与路由 |
| M6 | 持久化存储模块 | 游戏进度、最佳成绩、设置的本地持久化 |
| M7 | 提示系统模块 | 基于 BFS 的自动求解器，提供下一步建议 |
| M8 | 音效与国际化模块 | 音效播放、多语言切换 |

### 1.4 数据流设计

#### 1.4.1 游戏主循环
```
用户交互 → UI层捕获手势 → 调用 GameEngine.moveCar()
  → CollisionDetector 验证合法性
  → 合法 → 更新 GridState → UndoMgr 保存快照 → StatsTracker 更新
  → 检查是否胜利 → 触发通关流程
  → 不合法 → 拒绝移动，反馈视觉提示
```

#### 1.4.2 关卡加载流程
```
LevelParser.parse(file) → Level 数据模型
  → GameEngine.loadLevel(level) → 初始化 GridState
  → UI层响应式重建 GameGrid widget
```

#### 1.4.3 持久化数据流
```
游戏通关 → StatsTracker 记录成绩
  → Storage.saveProgress(levelId, stats)
  → LevelMgr.markCompleted(levelId) → 解锁下一关
```

### 1.5 状态管理方案
采用 **Provider + ChangeNotifier** 模式（Flutter 原生推荐，轻量且满足需求）：
- `GameProvider` — 管理当前游戏的 GridState、步数、用时、撤销栈
- `LevelProvider` — 管理关卡列表、解锁状态、当前选中关卡
- `SettingsProvider` — 管理音效、震动、语言等设置

### 1.6 路由设计
| 路由路径 | 页面 | 说明 |
|----------|------|------|
| `/splash` | SplashPage | 启动页 |
| `/menu` | MenuPage | 主菜单 |
| `/levels` | LevelSelectPage | 关卡选择 |
| `/game` | GamePage | 游戏主页面 |
| `/settings` | SettingsPage | 设置页 |

---

## 2. 详细设计文档索引

各子模块详细设计请参见以下独立文档：

| 文档 | 对应模块 |
|------|----------|
| [level_config_design.md](./level_config_design.md) | M1 — 关卡配置模块 |
| [game_grid_design.md](./game_grid_design.md) | M2 — 游戏网格模块 |
| [game_logic_design.md](./game_logic_design.md) | M3 — 游戏逻辑模块 |
| [level_management_design.md](./level_management_design.md) | M4 — 关卡管理模块 |
| [ui_design.md](./ui_design.md) | M5 — 用户界面模块 |
| [storage_design.md](./storage_design.md) | M6 — 持久化存储模块 |
| [hint_system_design.md](./hint_system_design.md) | M7 — 提示系统模块 |
| [audio_i18n_design.md](./audio_i18n_design.md) | M8 — 音效与国际化模块 |

---

## 3. 技术选型与约束

### 3.1 状态管理：Provider
- **理由**：Flutter 官方推荐，社区成熟，学习曲线平缓，适合本项目的状态复杂度。
- **替代方案**：Riverpod / BLoC（若后续状态复杂度提升可迁移）。

### 3.2 本地持久化：Hive
- **理由**：轻量级 NoSQL 数据库，纯 Dart 实现，无需原生配置，读写速度快。
- **存储内容**：关卡进度、最佳成绩、用户设置。

### 3.3 关卡配置格式：JSON
- **理由**：Dart 原生支持 `dart:convert`，解析零依赖，人类可读性好，易于调试。

### 3.4 游戏引擎算法
- **提示求解器**：广度优先搜索（BFS），保证找出**最少步数**解，配合剪枝优化性能。

### 3.5 项目结构
```
lib/
├── main.dart                   # 入口
├── app.dart                    # MaterialApp 配置
├── config/                     # 全局常量、主题、路由
│   ├── constants.dart
│   ├── theme.dart
│   └── routes.dart
├── models/                     # 数据模型
│   ├── car.dart
│   ├── exit.dart
│   ├── level.dart
│   └── game_state.dart
├── providers/                  # 状态管理
│   ├── game_provider.dart
│   ├── level_provider.dart
│   └── settings_provider.dart
├── services/                   # 业务逻辑 / 服务
│   ├── level_parser.dart       # M1 关卡配置解析
│   ├── game_engine.dart        # M3 游戏引擎
│   ├── collision_detector.dart # M3 碰撞检测
│   ├── undo_manager.dart       # M3 撤销管理
│   ├── stats_tracker.dart      # M3 步数/计时
│   ├── level_manager.dart      # M4 关卡管理
│   ├── hint_solver.dart        # M7 BFS 求解器
│   ├── storage_service.dart    # M6 持久化
│   ├── audio_service.dart      # M8 音效
│   └── localization_service.dart # M8 国际化
├── widgets/                    # 可复用 UI 组件
│   ├── game_grid.dart          # M2 游戏网格
│   ├── car_widget.dart         # M2 车辆组件
│   ├── exit_marker.dart        # M2 出口标记
│   ├── info_bar.dart           # 信息栏
│   └── action_buttons.dart     # 操作按钮
├── pages/                      # 页面
│   ├── splash_page.dart
│   ├── menu_page.dart
│   ├── level_select_page.dart
│   ├── game_page.dart
│   └── settings_page.dart
└── assets/
    ├── levels/                 # 内置关卡配置
    │   ├── level_001.json
    │   └── ...
    └── sounds/                 # 音效资源
        ├── move.wav
        ├── win.wav
        └── ...
```

---

## 4. 接口约定

### 4.1 Provider 对外接口

#### GameProvider
```dart
class GameProvider extends ChangeNotifier {
  GridState get currentState;
  int get moveCount;
  int get elapsedSeconds;
  bool get isCompleted;
  bool get canUndo;

  Future<void> loadLevel(Level level);
  bool moveCar(String carId, int steps); // 返回是否移动成功
  void undo();                           // 撤销一步
  void reset();                          // 重置关卡
  void pause();
  void resume();
}
```

#### LevelProvider
```dart
class LevelProvider extends ChangeNotifier {
  List<LevelInfo> get levels;     // 所有关卡信息
  LevelInfo? get currentLevel;
  bool isLevelUnlocked(String levelId);
  bool isLevelCompleted(String levelId);

  Future<void> loadLevels();       // 加载所有关卡
  void selectLevel(String levelId);
  void importLevel(String jsonString);
  void markCompleted(String levelId, LevelStats stats);
}
```

### 4.2 服务层接口

#### GameEngine
```dart
class GameEngine {
  GridState loadLevel(Level level);
  bool tryMove(GridState state, String carId, int steps);
  bool checkWin(GridState state);
  List<int> getValidMoves(GridState state, String carId);
}
```

#### HintSolver
```dart
class HintSolver {
  /// 返回从当前状态到胜利的一条最优路径（最少步数）
  /// 若不可解返回空列表
  List<Move> solve(GridState state, int gridSize, Exit exit, String targetCarId);

  /// 仅返回下一步建议
  Move? getNextHint(GridState state, int gridSize, Exit exit, String targetCarId);
}

class Move {
  final String carId;
  final int steps; // 正数=正向，负数=反向
}
```

---

## 5. 错误处理策略

| 场景 | 处理方式 |
|------|----------|
| 关卡 JSON 解析失败 | Provider 抛 `FormatException`，UI 捕获后弹出 SnackBar 提示 |
| 关卡配置语义校验失败（如车辆重叠） | 记录日志，跳过该关卡，不影响其他关卡加载 |
| 存储读写失败 | 静默降级，使用默认值，下次启动重试 |
| BFS 求解器超时（关卡过大） | 设定最大搜索步数（如 5000），超时返回空，提示"本关暂无可用的提示" |

---

## 6. 性能设计

- **网格渲染**：游戏网格使用 `CustomPainter` 一次性绘制，避免过多 Widget 嵌套。
- **State 快照**：撤销栈中存储 `GridSnapshot` 而非完整 `GridState` 副本，仅记录车辆位置变动。
- **BFS 剪枝**：记录已访问状态，用 字符串序列化 做 HashSet 判重。
- **关卡加载**：关卡 JSON 在异步 Isolate 中解析，避免阻塞主线程。
