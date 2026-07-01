# 持久化存储模块详细设计

- **模块编号**：M6
- **对应文件**：`lib/services/storage_service.dart`
- **依赖模块**：无

---

## 1. 职责

负责所有本地数据的持久化读写，包括：
1. 关卡通关记录与最佳成绩
2. 用户设置（音效、震动、语言）
3. 自定义导入的关卡数据
4. 数据库的初始化、升级与维护

---

## 2. 技术选型：Hive

**理由**：
- 纯 Dart 实现，无需原生配置
- 读写速度极快（基于内存映射）
- 支持复杂对象存储（通过 `TypeAdapter`）
- Flutter 生态成熟，无平台差异问题

**替代方案**：
- SQLite / sqflite：适合关系型查询，本项目数据简单无需 SQL
- SharedPreferences：仅支持基本类型，不适合存储关卡 JSON
- Isar：功能强大但对本项目来说过重

---

## 3. StorageService 设计

```dart
class StorageService {
  static const String _progressBoxName = 'levelProgress';
  static const String _settingsBoxName = 'settings';
  static const String _customLevelsBoxName = 'customLevels';

  late Box<String> _progressBox;
  late Box<String> _settingsBox;
  late Box<String> _customLevelsBox;

  /// 初始化 Hive，注册 TypeAdapter，打开所有 Box
  Future<void> init();

  // ─── 关卡进度 ───

  /// 保存关卡通关记录
  Future<void> saveLevelProgress(String levelId, LevelProgress progress);

  /// 读取关卡通关记录
  LevelProgress? getLevelProgress(String levelId);

  /// 获取所有关卡的通关记录
  Map<String, LevelProgress> getAllProgress();

  /// 清除所有关卡通关记录
  Future<void> clearAllProgress();

  // ─── 设置 ───

  bool getSoundEnabled();
  Future<void> setSoundEnabled(bool enabled);

  bool getVibrationEnabled();
  Future<void> setVibrationEnabled(bool enabled);

  String getLanguage();
  Future<void> setLanguage(String languageCode);

  // ─── 自定义关卡 ───

  /// 保存自定义关卡 JSON
  Future<void> saveCustomLevel(String levelId, String jsonContent);

  /// 获取自定义关卡 JSON
  String? getCustomLevel(String levelId);

  /// 获取所有自定义关卡 ID 列表
  List<String> getCustomLevelIds();

  /// 删除自定义关卡
  Future<void> deleteCustomLevel(String levelId);
}
```

---

## 4. LevelProgress 序列化

```dart
@HiveType(typeId: 0)
class LevelProgress extends HiveObject {
  @HiveField(0)
  final int bestMoves;

  @HiveField(1)
  final int bestTimeSeconds;

  @HiveField(2)
  final bool completed;

  @HiveField(3)
  final int playCount;       // 游玩次数

  @HiveField(4)
  final DateTime? lastPlayedAt;

  LevelProgress({
    required this.bestMoves,
    required this.bestTimeSeconds,
    required this.completed,
    this.playCount = 1,
    this.lastPlayedAt,
  });

  /// 判断是否打破记录（合并逻辑）
  bool isNewBest(int moves, int timeSeconds) {
    if (!completed) return true;
    return moves < bestMoves || (moves == bestMoves && timeSeconds < bestTimeSeconds);
  }

  /// 合并新记录
  LevelProgress mergeWith(int moves, int timeSeconds) {
    if (!completed || moves < bestMoves || (moves == bestMoves && timeSeconds < bestTimeSeconds)) {
      return LevelProgress(
        bestMoves: moves,
        bestTimeSeconds: timeSeconds,
        completed: true,
        playCount: playCount + 1,
        lastPlayedAt: DateTime.now(),
      );
    }
    return LevelProgress(
      bestMoves: bestMoves,
      bestTimeSeconds: bestTimeSeconds,
      completed: true,
      playCount: playCount + 1,
      lastPlayedAt: DateTime.now(),
    );
  }
}
```

---

## 5. Hive Box 结构

### 5.1 progressBox（key: String → value: JSON String）

| Key | Value | 说明 |
|-----|-------|------|
| `level_001` | `{"bestMoves":12,"bestTime":45,"completed":true,"playCount":3,"lastPlayedAt":"2026-07-01T10:30:00Z"}` | 关卡记录 |
| `level_002` | ... | |
| `highestUnlocked` | `"level_003"` | 已解锁的最高关卡 |

### 5.2 settingsBox（key: String → value: String）

| Key | Value | 说明 |
|-----|-------|------|
| `soundEnabled` | `"true"` | 音效开关 |
| `vibrationEnabled` | `"false"` | 震动开关 |
| `language` | `"zh"` | 语言代码 |

### 5.3 customLevelsBox（key: String → value: JSON String）

| Key | Value | 说明 |
|-----|-------|------|
| `custom_level_001` | `{"levelId":"custom_001","gridSize":6,...}` | 完整 JSON 配置 |

---

## 6. 初始化流程

```dart
Future<void> _initHive() async {
  await Hive.initFlutter();              // 初始化 Hive

  // 注册 TypeAdapter（如使用 Hive 对象模式）
  Hive.registerAdapter(LevelProgressAdapter());

  // 打开 Box
  _progressBox = await Hive.openBox<String>(_progressBoxName);
  _settingsBox = await Hive.openBox<String>(_settingsBoxName);
  _customLevelsBox = await Hive.openBox<String>(_customLevelsBoxName);
}
```

---

## 7. 错误处理策略

| 场景 | 处理方式 |
|------|----------|
| Hive 初始化失败 | 捕获异常，使用内存中的默认值运行（功能不受影响但重启后数据丢失） |
| 读取键不存在 | 返回 `null` 或默认值 |
| 写入失败（磁盘满等） | 静默失败，记录日志 |
| JSON 反序列化失败 | 返回 `null`，下次写入时覆盖 |
| Box 损坏 | 删除损坏 Box 文件，重新创建（清空对应数据） |

---

## 8. 性能考虑

- Hive Box 打开后常驻内存，读写为 O(1) 操作
- 每次通关后异步写入（`await` 不阻塞 UI）
- 数据量极小（最多数百条记录），无需考虑分页或大数据量优化

---

## 9. 单元测试要点

| 测试用例 | 预期 |
|----------|------|
| 保存并读取关卡进度 | 返回正确的 LevelProgress |
| 覆盖已有记录 | 正确合并新旧数据 |
| 读取不存在的关卡 | 返回 null |
| 切换音效开关 | 读写值一致 |
| 保存自定义关卡 JSON | 读取内容一致 |
| 清除所有进度 | 所有关卡记录被清空 |
| 进度合并逻辑（更少步数） | 更新最佳记录 |
| 进度合并逻辑（更多步数） | 保留旧的最佳记录 |
