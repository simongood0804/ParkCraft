# 关卡管理模块详细设计

- **模块编号**：M4
- **对应文件**：`lib/services/level_manager.dart`、`lib/providers/level_provider.dart`
- **依赖模块**：M1（关卡配置解析）、M6（持久化存储）

---

## 1. 职责

1. 管理所有关卡信息的元数据（ID、难度、解锁/完成状态）
2. 关卡解锁逻辑
3. 支持快速导入新关卡
4. 维护关卡列表供关卡选择页面展示

---

## 2. 数据模型

### 2.1 LevelInfo

```dart
class LevelInfo {
  final String levelId;
  final int gridSize;
  final String difficulty;  // "easy" / "medium" / "hard"
  final bool isLocked;
  final bool isCompleted;
  final int? bestMoves;
  final int? bestTimeSeconds;
  final String? assetPath;  // 内置关卡资源路径，导入关卡为 null

  LevelInfo copyWith({
    bool? isLocked,
    bool? isCompleted,
    int? bestMoves,
    int? bestTimeSeconds,
  });
}
```

---

## 3. LevelManager 设计

```dart
class LevelManager {
  final LevelParser _parser;
  final StorageService _storage;

  List<Level> _loadedLevels = []; // 已解析的完整关卡数据（按顺序）
  List<LevelInfo> _levelInfos = []; // 关卡元数据列表

  /// 初始化：加载内置关卡 + 恢复用户进度
  Future<void> initialize();

  /// 获取关卡元数据列表（供 UI 使用）
  List<LevelInfo> get levelInfos;

  /// 获取指定关卡的完整数据
  Level? getLevel(String levelId);

  /// 导入自定义关卡（JSON 字符串），返回导入后的 levelId
  Future<String> importLevel(String jsonString);

  /// 标记关卡完成
  Future<void> markCompleted(String levelId, int moves, int timeSeconds);

  /// 获取下一关的 ID（用于通关后跳转）
  String? getNextLevelId(String currentLevelId);

  /// 重置所有关卡进度
  Future<void> resetAllProgress();

  /// 按难度筛选关卡
  List<LevelInfo> getLevelsByDifficulty(String difficulty);
}
```

---

## 4. 解锁逻辑

```
关卡排列：按照预设顺序（level_001 → level_002 → ...）
    │
    ▼
第一个关卡默认解锁
    │
    ▼
关卡 N 完成 → 关卡 N+1 解锁
    │
    ▼
用户进度持久化到 Hive
    │
    ▼
下次启动时从 Hive 恢复进度
```

规则：
- 所有关卡按 `level_001`、`level_002` ... 顺序排列
- `level_001` 默认解锁
- 通关 `level_N` 后 `level_{N+1}` 自动解锁
- 导入的自定义关卡默认解锁
- 已解锁的关卡可以任意重玩

---

## 5. 快速导入模块

### 5.1 导入流程

```
用户选择导入（从文件 / 粘贴 JSON）
    │
    ▼
LevelParser.parseFromString(jsonString)
    │
    ├── 解析失败 → 返回错误信息
    │
    ▼ 解析成功
检查 levelId 是否已存在
    │
    ├── 已存在 → 覆盖旧关卡（确认弹窗）
    │
    ▼ 新关卡
添加到 _loadedLevels 末尾
    │
    ▼
创建 LevelInfo，标记为已解锁
    │
    ▼
持久化存储（关卡 JSON 内容及元数据）
    │
    ▼
通知 UI 刷新
```

### 5.2 外部文件导入支持
- 平台文件选择器（`file_picker` 插件）
- 支持的格式：`.json`
- 粘贴 JSON 文本到应用内的文本框

---

## 6. 内置关卡组织

### 6.1 文件结构
```
assets/levels/
├── easy/
│   ├── level_001.json (6×6)
│   ├── level_002.json (6×6)
│   ├── level_003.json (6×6)
│   ├── level_004.json (6×6)
│   ├── level_005.json (6×6)
│   └── level_006.json (6×6)
├── medium/
│   ├── level_007.json (7×7)
│   ├── level_008.json (7×7)
│   ├── level_009.json (7×7)
│   ├── level_010.json (7×7)
│   ├── level_011.json (7×7)
│   └── level_012.json (7×7)
└── hard/
    ├── level_013.json (8×8)
    ├── level_014.json (8×8)
    ├── level_015.json (8×8)
    ├── level_016.json (8×8)
    ├── level_017.json (8×8)
    └── level_018.json (8×8)
```

### 6.2 最小关卡数要求
- **Easy**：6 关（6×6 网格）
- **Medium**：6 关（7×7 网格）
- **Hard**：6 关或更多（8×8 及以上）
- **总计**：≥ 18 关（需求要求 ≥ 20）

---

## 7. LevelProvider 状态管理

```dart
class LevelProvider extends ChangeNotifier {
  final LevelManager _manager;

  List<LevelInfo> get levels => _manager.levelInfos;
  LevelInfo? getLevelInfo(String levelId);
  bool isLevelUnlocked(String levelId);
  bool isLevelCompleted(String levelId);

  Future<void> loadLevels();
  String? getNextLevelId(String currentLevelId);

  /// 选择关卡（返回完整 Level 数据给 GameProvider）
  Future<void> selectLevel(String levelId);

  /// 导入关卡 UI 层调用
  Future<ImportResult> importLevelFromJson(String jsonString);

  /// 进度完成后调用
  Future<void> onLevelCompleted(String levelId, int moves, int timeSeconds);
}

class ImportResult {
  final bool success;
  final String? levelId;
  final String? errorMessage;
}
```

---

## 8. 持久化数据

### 8.1 Hive 存储结构

| Box 名称 | Key | Value | 说明 |
|----------|-----|-------|------|
| `levelProgress` | `level_001` | `{bestMoves: 12, bestTime: 45, completed: true}` | 每关成绩 |
| `levelProgress` | `highestUnlocked` | `"level_003"` | 已解锁的最高关卡 |
| `customLevels` | `custom_level_001` | 关卡 JSON 字符串 | 导入的自定义关卡 |
| `settings` | `soundEnabled` | `true` | 音效开关 |
| `settings` | `vibrationEnabled` | `true` | 震动开关 |
| `settings` | `language` | `"zh"` | 语言设置 |

### 8.2 初始化流程
```
LevelProvider.loadLevels()
    │
    ├── 1. 从 assets 加载所有内置 JSON 文件
    │
    ├── 2. LevelParser 解析 → List<Level>
    │
    ├── 3. 从 Hive 恢复每个关卡的通关记录
    │
    ├── 4. 构建 LevelInfo 列表（计算锁定状态）
    │
    └── 5. 通知 UI
```
