# ParkCraft 代码规范

> 以 [Google Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) 为核心基准，结合 Flutter 最佳实践。此规范适用于本项目的所有 Dart 源代码。

---

## 1. 命名规范

### 1.1 文件命名

| 场景 | 规范 | 示例 |
|------|------|------|
| Dart 源文件 | `snake_case` | `game_engine.dart` |
| 测试文件 | `*_test.dart` | `game_engine_test.dart` |
| 单 Widget 文件 | `snake_case` | `game_grid.dart` |
| 模型文件 | `snake_case` | `car.dart` / `game_state.dart` |

- 一个 Dart 文件只包含一个主要类/顶级函数，文件名与类名关联但不要求完全一致。
- 测试文件放在 `test/` 目录下，目录结构与 `lib/` 镜像。

### 1.2 标识符命名

| 类别 | 规范 | 示例 |
|------|------|------|
| 类名 / 枚举名 | `UpperCamelCase` | `GameEngine`, `CollisionDetector`, `Orientation` |
| 枚举值 | `lowerCamelCase` | `Orientation.horizontal` |
| 库 / 前缀 | `lowercase_with_underscores` | `import 'services/game_engine.dart'` |
| 顶级常量 | `lowerCamelCase` | `const defaultGridSize = 6;` |
| 变量 / 参数 | `lowerCamelCase` | `gridSize`, `carId`, `onMoveCar` |
| 私有成员 | `_lowerCamelCase` | `_selectedCarId`, `_loadLevel()` |
| 回调/函数变量 | `lowerCamelCase` | `void Function(int steps) onMove` |
| 类型参数 | 大写单字母或 `UpperCamelCase` | `T`, `K`, `V`, `JsonConverter<T>` |

```dart
// ✅ 正确
class GameEngine { ... }
enum Orientation { horizontal, vertical }
const maxLevelGridSize = 12;
final _validMoves = <Move>[];

// ❌ 错误
class game_engine { ... }
enum ORIENTATION { HORIZONTAL, VERTICAL }
const MAX_LEVEL_GRID_SIZE = 12;
```

### 1.3 缩写

- 通用的首字母缩写视为普通单词：`HttpRequest`、`DbHelper`、`CarId`
- 不要全大写：~~`HTTPRequest`~~、~~`DBHelper`~~、~~`carID`~~

```dart
// ✅ 正确
final carId = 'T';
final httpResponse;

// ❌ 错误
final carID = 'T';
final HTTPResponse;
```

---

## 2. 格式规范

### 2.1 缩进

- 使用 **2 个空格** 缩进，不使用 Tab。
- IDE 设置：Editor → Indentation → 2 spaces。

```dart
// ✅ 正确
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('ParkCraft')),
    body: Center(
      child: Column(
        children: [
          Text('Hello'),
          Text('World'),
        ],
      ),
    ),
  );
}

// ❌ 错误（4空格缩进）
Widget build(BuildContext context) {
____return Scaffold(
________appBar: AppBar(title: Text('ParkCraft')),
```

### 2.2 行长度

- **最大行宽：100 字符**。
- 超过 100 字符时换行，换行后缩进 4 个空格（相对于上一行起始）。

```dart
// ✅ 正确
final result = someVeryLongFunctionName(
    parameter1, parameter2, parameter3, parameter4);

// ✅ 正确（链式调用换行）
cars.where((c) => c.isTarget)
    .map((c) => c.length)
    .reduce((a, b) => a + b);

// ❌ 错误（超过100字符不换行）
final result = someVeryLongFunctionName(parameter1, parameter2, parameter3, parameter4, parameter5);
```

### 2.3 花括号

- 控制流语句始终使用花括号，即使只有单行。

```dart
// ✅ 正确
if (canUndo) {
  undo();
}

// ❌ 错误
if (canUndo) undo();
```

- 左花括号不换行，与前一语句同行。

```dart
// ✅ 正确
class GameEngine {
  void moveCar() {
    // ...
  }
}

// ❌ 错误
class GameEngine
{
  void moveCar()
  {
    // ...
  }
}
```

### 2.4 空行

- 类中成员之间用 1 个空行分隔。
- 类与类之间用 2 个空行分隔。
- 方法内的逻辑段落用 1 个空行分隔（不要过度使用）。

```dart
class GameProvider extends ChangeNotifier {
  GridState _state;
  int _moveCount = 0;


  GridState get currentState => _state;

  int get moveCount => _moveCount;


  void loadLevel(Level level) {
    _state = GameEngine().loadLevel(level);
    _moveCount = 0;

    _notifyListeners();
  }
}
```

> 注意：Dart 格式化工具 `dart format` 会自动处理空行，建议使用 `dart format` 统一格式化。

### 2.5 导入顺序

按以下分组排列，组间用空行分隔：

1. `dart:` 核心库
2. `package:` 第三方依赖（Flutter SDK 在前，其他在后）
3. 项目内部导入（`package:parkcraft/` 或相对路径）

每组内部按字母序排序。

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:parkcraft/models/car.dart';
import 'package:parkcraft/models/level.dart';
import 'package:parkcraft/services/game_engine.dart';
```

### 2.6 使用 `dart format`

- 每次保存文件前运行 `dart format`，或在 IDE 中启用 "Format on Save"。
- CI 流水线中应加入 `dart format --set-exit-if-changed` 检查。

---

## 3. 注释规范

### 3.1 文档注释

- 公开 API（public 类、方法、属性、顶级常量）必须使用 `///` 文档注释。
- 文档注释以名词性短语开头，描述"是什么"，而非"做什么"。

```dart
/// 车辆在网格中的朝向。
enum Orientation { horizontal, vertical }

/// 检测车辆移动是否与其它车辆或网格边界发生碰撞。
class CollisionDetector {
  /// 检测汽车移动 [steps] 步后是否会发生碰撞。
  ///
  /// [steps] 为正数表示向朝向正方向移动，
  /// 为负数表示向反方向移动。
  /// 返回 `true` 表示将发生碰撞。
  static bool wouldCollide(GridState state, Car car, int steps);
}
```

### 3.2 代码注释

- 使用 `//` 行注释，写在被注释代码的**上方**。
- 不写显而易见的注释，专注于"为什么这样做"。

```dart
// ✅ 好的注释
// 限制最大状态数以避免搜索无限循环
const int maxStates = 100000;

// ❌ 差的注释（显而易见）
// 设置变量值为100000
const int maxStates = 100000;
```

### 3.3 TODO 注释

```dart
// TODO(username): 优化 BFS 搜索性能，考虑使用 A* 算法
```

---

## 4. Dart 语言惯用法

### 4.1 空安全

本项目使用 Dart 3.x，全面遵循 Null Safety。

```dart
// ✅ 正确：明确区分可空和不可空
String name;         // 非空
String? nullableName; // 可空

// ✅ 正确：使用 ?? 提供默认值
final displayName = name ?? 'Unknown';

// ✅ 正确：使用 ?. 安全调用
final length = nullableName?.length;

// ❌ 错误：不可空变量赋 null
String name = null;
```

### 4.2 集合

```dart
// ✅ 使用集合字面量
final cars = <Car>[];
final carMap = <String, Car>{};
final carSet = <Car>{};

// ✅ 使用 collection-if 和 collection-for
final children = [
  InfoBar(),
  if (isPlaying) GameGrid(),
  for (final car in cars) CarWidget(car: car),
  ...actionButtons,
];
```

### 4.3 箭头函数

- 适用于单表达式函数体，且表达式**不是**控制流。

```dart
// ✅ 正确
int get moveCount => _moveCount;
bool checkWin() => targetCar.col + targetCar.length > gridSize;

// ❌ 错误（多行箭头函数）
void undo() => {
  doSomething();
  doAnotherThing();
};
```

### 4.4 构造函数

- 优先使用初始化列表和 `this.` 简写。

```dart
// ✅ 正确
class Car {
  final String id;
  final int length;
  final Orientation orientation;

  const Car({
    required this.id,
    required this.length,
    required this.orientation,
  });
}

// ❌ 错误（冗余）
class Car {
  final String id;
  Car({required String id}) : id = id;
}
```

### 4.5 不可变性

- 尽量使用 `final` 而非 `var`。
- 模型类属性能用 `final` 就用 `final`。

```dart
// ✅ 正确
final gridSize = 6;
const maxGridSize = 12;

// 模型类
class GridState {
  final int gridSize;
  final List<Car> cars;
  // ...
}
```

### 4.6 避免动态类型

- 不使用 `dynamic` 和 `var` 作为返回值类型。
- 除非与 JSON 解析等场景交互，否则必须显式标注类型。

```dart
// ✅ 正确
List<Car> parseCars(List<dynamic> jsonList) { ... }

// ❌ 错误
var result = getSomething(); // 不明确类型
dynamic parseCars(jsonList) { ... }
```

### 4.7 Record 与模式匹配（Dart 3）

- 小范围临时元组使用 Record，公共 API 优先使用命名类。

```dart
// ✅ 内部使用 Record
(int min, int max) getMoveRange() { ... }

// ✅ 公共 API 使用命名类
class MoveRange {
  final int min;
  final int max;
}
```

---

## 5. Flutter 特定规范

### 5.1 Widget 组织

- 优先使用 `StatelessWidget`，只有当需要管理状态时才用 `StatefulWidget`。
- 当一个 Widget 的 `build` 方法超过 50 行时，拆分为更小的 Widget 或方法。
- 私有 `buildXxx` 方法返回 `Widget`，以 `_build` 开头。

```dart
// ✅ 正确
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(),
    body: _buildBody(),
  );
}

Widget _buildAppBar() {
  return AppBar(title: Text(AppLocalizations.tr('game_paused')));
}

Widget _buildBody() {
  return Center(
    child: Column(
      children: [
        _buildGameGrid(),
        _buildActionButtons(),
      ],
    ),
  );
}
```

### 5.2 Build 方法

- `build` 方法中**不执行**有副作用的逻辑（网络请求、持久化写操作等）。
- 状态变化通过 Provider 或 setState 触发 rebuild，不要在 build 中直接触发。

```dart
// ❌ 错误
@override
Widget build(BuildContext context) {
  _loadData(); // 副作用！
  return Text('...');
}
```

### 5.3 Provider 组件

- 使用 `Consumer` / `Selector` 按需重建，避免整个页面重绘。

```dart
// ✅ 最佳实践：仅监听需要的属性
Selector<GameProvider, int>(
  selector: (_, provider) => provider.moveCount,
  builder: (_, moveCount, __) => Text('步数: $moveCount'),
);
```

### 5.4 const 构造

- 静态 Widget 尽可能声明为 `const`。

```dart
// ✅ 正确
const SizedBox(height: 16);
const EdgeInsets.all(8);
const Text('ParkCraft', style: TextStyle(fontSize: 24));

// ❌ 错误
SizedBox(height: 16);
EdgeInsets.all(8);
```

### 5.5 键（Key）

- 列表中的 Widget 必须使用 `Key`（通常是 `ValueKey`）。
- 需要保留状态的 Widget 状态切换时使用 `UniqueKey` 或 `ValueKey`。

```dart
ListView.builder(
  itemCount: cars.length,
  itemBuilder: (_, index) => CarWidget(
    key: ValueKey(cars[index].id),
    car: cars[index],
  ),
);
```

---

## 6. 错误处理规范

### 6.1 异常类型

- 业务异常: 使用自定义异常类（如 `ParserException`）
- 系统异常: 使用 Dart 内置异常类型（`FormatException`、`IOException`）

```dart
class ParserException implements Exception {
  final String message;
  ParserException(this.message);

  @override
  String toString() => 'ParserException: $message';
}
```

### 6.2 异常处理

- 只在能恢复的地方捕获异常。
- 避免空的 `catch` 块。

```dart
// ✅ 正确
try {
  final level = LevelParser().parseFromString(jsonString);
} on ParserException catch (e) {
  // 展示用户友好的错误信息
  showErrorSnackBar(context, e.message);
}

// ❌ 错误（空的 catch）
try {
  parseLevel(jsonString);
} catch (_) {
  // 什么都不做
}
```

---

## 7. 测试规范

### 7.1 测试组织

- 测试文件放在 `test/` 目录，镜像 `lib/` 结构。
- 文件命名：`<模块名>_test.dart`。

```
lib/services/game_engine.dart
  → test/services/game_engine_test.dart
lib/models/car.dart
  → test/models/car_test.dart
```

### 7.2 测试命名

- 测试用例使用自然语言描述，关注行为而非实现。
- 使用 `group` 组织相关测试。

```dart
// ✅ 正确
group('CollisionDetector', () {
  test('同向车辆前后排列时不应碰撞', () { ... });
  test('垂直车辆垂直移动超出边界时应碰撞', () { ... });
  test('目标车辆移出出口时不应碰撞', () { ... });
});
```

### 7.3 测试覆盖率

- 服务层（`services/`）覆盖率目标：**≥ 90%**
- Provider 层覆盖率目标：**≥ 80%**
- UI 层（`pages/`、`widgets/`）：关键交互路径需覆盖

---

## 8. Git 提交规范

### 8.1 分支命名

| 分支类型 | 命名格式 | 示例 |
|----------|----------|------|
| 功能开发 | `feat/<简短描述>` | `feat/level-parser` |
| Bug 修复 | `fix/<简短描述>` | `fix/undo-overflow` |
| 重构 | `refactor/<简短描述>` | `refactor/engine-api` |
| 文档 | `docs/<简短描述>` | `docs/code-style-guide` |

### 8.2 提交信息格式

```
<type>(<scope>): <简短描述>

<详细说明（可选）>
```

| type | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `refactor` | 重构 |
| `docs` | 文档变更 |
| `style` | 格式调整（不影响功能） |
| `test` | 测试相关 |
| `chore` | 构建/工具链变更 |

```bash
# ✅ 正确
feat(parser): 添加 JSON 关卡解析的语义校验

fix(engine): 修复目标车驶出时碰撞检测误判

refactor(grid): 将 CustomPainter 抽离为独立文件
```

---

## 9. IDE 配置

### 9.1 VS Code 推荐配置 (`.vscode/settings.json`)

```json
{
  "dart.lineLength": 100,
  "editor.formatOnSave": true,
  "editor.rulers": [100],
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code"
  }
}
```

### 9.2 Analysis Options (`analysis_options.yaml`)

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_locals
    - avoid_print
    - prefer_single_quotes
    - sort_child_properties_last
    - use_key_in_widget_constructors
    - avoid_unnecessary_containers
    - prefer_const_literals_to_create_immutables

analyzer:
  errors:
    invalid_assignment: error
    missing_return: error
    dead_code: warning
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
```

---

## 10. 规范检查清单

每次提交代码前，检查以下条目：

- [ ] `dart format` 已运行，无格式问题
- [ ] `dart analyze` 无 error
- [ ] `flutter test` 全部通过
- [ ] 无未使用的 import
- [ ] 无 `print()` 调试语句（使用 `log()` 替代）
- [ ] 无 `// ignore:` 注释（除非有充分理由并附带 TODO）
- [ ] 新加的公开 API 有 `///` 文档注释
- [ ] 模型类属性尽量使用 `final`
- [ ] Widget `build` 方法中没有副作用
- [ ] 文件命名、类命名、变量命名符合本规范
