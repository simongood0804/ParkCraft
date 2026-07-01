# 关卡配置模块详细设计

- **模块编号**：M1
- **对应文件**：`lib/services/level_parser.dart`
- **依赖模块**：无（仅依赖数据模型 `models/`）

---

## 1. 职责

负责读取和解析 JSON 格式的关卡配置文件，将其转换为内存中的 `Level`、`Car`、`Exit` 数据模型，并在解析过程中完成数据合法性校验。

---

## 2. 类设计

### 2.1 LevelParser

```dart
class LevelParser {
  /// 从 JSON 字符串解析单个关卡
  /// 解析失败抛出 ParserException
  Level parseFromString(String jsonString);

  /// 从 assets 中的 JSON 文件路径解析关卡
  Future<Level> parseFromAsset(String assetPath);

  /// 批量解析多关卡（支持单文件含数组，或多个文件）
  Future<List<Level>> parseMultiple(List<String> jsonStrings);

  /// JSON to Level 的内部转换（供 parseFromString/parseFromAsset 调用）
  Level _parseJson(Map<String, dynamic> json);
}
```

### 2.2 ParserException

```dart
class ParserException implements Exception {
  final String message;
  final String? levelId; // 可选的关卡标识，便于定位问题
  ParserException(this.message, {this.levelId});

  @override
  String toString() => 'ParserException($levelId): $message';
}
```

---

## 3. 校验规则

解析过程中按以下顺序校验，任一失败则抛出 `ParserException`：

| 检查项 | 规则 | 错误提示 |
|--------|------|----------|
| 必填字段 | `levelId`、`gridSize`、`exit`、`targetCar`、`blockingCars` 必须存在 | "缺少必填字段：xxx" |
| gridSize 范围 | `3 ≤ gridSize ≤ 12` | "gridSize 必须在 3~12 之间" |
| 出口位置 | `exit.row`/`exit.col` 在网格边界上 | "出口必须在网格边界" |
| 目标车辆长度 | `targetCar.length == 2` | "目标车辆长度必须为 2" |
| 堵塞车辆长度 | `blockingCars[].length ∈ {2, 3}` | "堵塞车辆长度只能为 2 或 3" |
| 位置范围 | 所有 `row`/`col` 满足 `0 ≤ row, col < gridSize` | "车辆位置超出网格边界" |
| 车辆重叠 | 所有车辆的占据格子不得重叠 | "车辆之间存在重叠" |
| ID 唯一性 | 所有车辆的 `id` 不重复 | "车辆 ID 重复：{id}" |

---

## 4. 解析流程

```
JSON String
    │
    ▼
dart:convert jsonDecode()
    │
    ▼
Map<String, dynamic>
    │
    ├── 校验必填字段 ──→ 失败 → 抛 ParserException
    │
    ▼
解析 exit → Exit 对象
    │
    ▼
解析 targetCar → Car 对象 (isTarget = true)
    │
    ▼
遍历 blockingCars → List<Car> (isTarget = false)
    │
    ▼
校验语义（位置/重叠/ID唯一性）
    │
    ▼
构造 Level 对象 → 返回
```

---

## 5. JSON 格式规范（重申）

标准格式：

```json
{
  "levelId": "level_001",
  "difficulty": "easy",
  "gridSize": 6,
  "exit": {
    "row": 2,
    "col": 5,
    "orientation": "horizontal"
  },
  "targetCar": {
    "id": "T",
    "row": 2,
    "col": 0,
    "length": 2,
    "orientation": "horizontal"
  },
  "blockingCars": [
    { "id": "A", "row": 0, "col": 0, "length": 3, "orientation": "horizontal" }
  ]
}
```

支持批量关卡文件格式（同文件数组）：

```json
[
  { /* level_001 */ },
  { /* level_002 */ }
]
```

---

## 6. 单元测试要点

| 测试用例 | 预期 |
|----------|------|
| 解析标准合法 JSON | 返回正确的 Level 对象 |
| 缺少 `levelId` 字段 | 抛出 ParserException |
| `gridSize = 2`（小于下限） | 抛出 ParserException |
| `gridSize = 13`（大于上限） | 抛出 ParserException |
| 目标车辆长度不为 2 | 抛出 ParserException |
| 两辆车占据同一格子 | 抛出 ParserException |
| 车辆 ID 重复 | 抛出 ParserException |
| 出口不在网格边界 | 抛出 ParserException |
| 批量解析混合合法/非法数据 | 返回合法列表，记录非法条目 |
| 空字符串 | 抛出 ParserException |
