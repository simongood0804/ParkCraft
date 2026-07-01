# 用户界面模块详细设计

- **模块编号**：M5
- **对应文件**：`lib/pages/*.dart`、`lib/widgets/*.dart`、`lib/config/routes.dart`
- **依赖模块**：所有服务模块和 Provider

---

## 1. 职责

负责所有用户可见界面的 Widget 组合、页面路由和各页面内部交互逻辑。

---

## 2. 路由配置

```dart
// lib/config/routes.dart
class AppRoutes {
  static const String splash = '/splash';
  static const String menu = '/menu';
  static const String levelSelect = '/levels';
  static const String game = '/game';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case menu:
        return MaterialPageRoute(builder: (_) => const MenuPage());
      case levelSelect:
        return MaterialPageRoute(builder: (_) => const LevelSelectPage());
      case game:
        final levelId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => GamePage(levelId: levelId));
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      default:
        return MaterialPageRoute(builder: (_) => const SplashPage());
    }
  }
}
```

---

## 3. 页面设计

### 3.1 SplashPage（启动页）

```
┌────────────────────────────────┐
│                                │
│           🅿 ParkCraft          │  ← Logo + 应用名
│                                │
│        [ 加载动画... ]          │  ← CircularProgressIndicator
│                                │
│       加载资源中...             │  ← 加载状态文本
│                                │
└────────────────────────────────┘
```

- 显示应用 Logo 和名称
- 后台加载内置关卡资源和存储数据
- 加载完成后自动跳转至菜单页
- 加载时间 ≥ 1.5s 以保证展示效果

```dart
class SplashPage extends StatefulWidget { ... }

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(milliseconds: 800)); // 最小展示时间
    // 依赖注入/初始化
    final levelProvider = context.read<LevelProvider>();
    await levelProvider.loadLevels(); // 加载所有关卡
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.menu);
    }
  }
}
```

### 3.2 MenuPage（主菜单页）

```
┌────────────────────────────────┐
│                                │
│           🅿 ParkCraft          │  ← 应用标题
│                                │
│                                │
│      ┌──────────────────┐      │
│      │   开始游戏 🎮     │      │  ← ElevatedButton
│      └──────────────────┘      │
│                                │
│      ┌──────────────────┐      │
│      │   关卡选择 🗺️     │      │  ← OutlinedButton
│      └──────────────────┘      │
│                                │
│      ┌──────────────────┐      │
│      │   设置 ⚙️          │      │  ← OutlinedButton
│      └──────────────────┘      │
│                                │
│            v1.0.0              │  ← 版本号
└────────────────────────────────┘
```

- "开始游戏" → 跳转到第一个未通关的关卡
- "关卡选择" → 跳转至关卡列表
- "设置" → 跳转至设置页
- 背景：应用主题色渐变

### 3.3 LevelSelectPage（关卡选择页）

```
┌────────────────────────────────┐
│  ←       关卡选择              │  ← AppBar 带返回按钮
├────────────────────────────────┤
│  Tab: [简单] [中等] [困难]     │  ← TabBar 按难度筛选
├────────────────────────────────┤
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐  │
│ │ 1  │ │ 2  │ │ 3  │ │ 4  │  │  ← GridView 关卡卡片
│ │★12 │ │🔒  │ │★8  │ │🔒  │  │    显示最佳步数和锁定状态
│ └────┘ └────┘ └────┘ └────┘  │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐  │
│ │ 5  │ │ 6  │ │ 7  │ │ 8  │  │
│ │🔒  │ │🔒  │ │🔒  │ │🔒  │  │
│ └────┘ └────┘ └────┘ └────┘  │
├────────────────────────────────┤
│       [导入关卡]               │  ← TextButton
└────────────────────────────────┘
```

- 使用 `TabBar` + `TabBarView` 按难度分组
- 每关使用 `GridView` 展示为正方形卡片
- 卡片状态：
  - **已完成**：绿色边框 + 最佳步数徽章
  - **已解锁**：实心可点击
  - **未解锁**：灰色 + 锁图标
- 点击已解锁关卡 → 跳转到 GamePage
- 点击导入 → 弹出对话框，支持选择文件或粘贴 JSON

```dart
class LevelSelectPage extends StatelessWidget {
  Widget _buildLevelCard(LevelInfo info) {
    return GestureDetector(
      onTap: info.isLocked ? null : () => Navigator.pushNamed(
        context, AppRoutes.game, arguments: info.levelId,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: info.isCompleted ? Colors.green.shade50
               : info.isLocked ? Colors.grey.shade200
               : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: info.isCompleted ? Colors.green : Colors.grey.shade300,
          ),
        ),
        child: Stack(
          children: [
            Center(child: Text(info.levelId.replaceAll('level_', ''), ...)),
            if (info.isLocked) Icon(Icons.lock, ...),
            if (info.isCompleted && info.bestMoves != null)
              Positioned(
                right: 4, bottom: 4,
                child: Text('★${info.bestMoves}', style: ...),
              ),
          ],
        ),
      ),
    );
  }
}
```

### 3.4 GamePage（游戏主页面）

```
┌────────────────────────────────┐
│  ← 暂停    关卡 001    步数: 12│  ← InfoBar
│             00:45              │     步数 + 计时器
├────────────────────────────────┤
│                                │
│       ┌───┬───┬───┬───┐      │
│       │   │ A │ A │ A │      │
│       ├───┼───┼───┼───┤      │
│       │ B │   │   │   │      │
│       ├───┼───┼───┼───┤      │
│       │ B │ T │ T │ ══╡      │  ← GameGrid
│       ├───┼───┼───┼───┤      │
│       │   │ C │ C │   │      │
│       └───┴───┴───┴───┘      │
│                                │
├────────────────────────────────┤
│  [撤销]    [提示]    [重开]    │  ← ActionButtons
└────────────────────────────────┘
```

**页面结构**：

```dart
class GamePage extends StatefulWidget {
  final String levelId;
}

class _GamePageState extends State<GamePage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: Scaffold(
        appBar: _buildInfoBar(),
        body: Center(child: _buildGameGrid()),
        bottomNavigationBar: _buildActionBar(),
      ),
    );
  }
}
```

**InfoBar 设计**：
- 左上角："暂停"按钮 → 弹出暂停菜单（继续 / 重开 / 退出）
- 中间：关卡名称
- 右上角：步数 + 计时器实时更新

**ActionButtons 设计**：
- **撤销**：灰色图标，不可撤销时置灰
- **提示**：高亮图标，点击后目标车辆闪烁或箭头指示
- **重开**：点击弹出确认对话框后重置

### 3.5 暂停弹窗

```
┌────────────────────────┐
│        ⏸ 暂停          │
│                        │
│      ┌──────────┐      │
│      │   继续    │      │
│      └──────────┘      │
│      ┌──────────┐      │
│      │   重开    │      │
│      └──────────┘      │
│      ┌──────────┐      │
│      │ 返回菜单  │      │
│      └──────────┘      │
└────────────────────────┘
```

### 3.6 通关弹窗

```
┌────────────────────────┐
│        🎉 恭喜通关！    │
│                        │
│    步数: 12            │
│    用时: 00:45         │
│    🏆 最佳记录！       │  ← 仅在打破记录时显示
│                        │
│      ┌──────────┐      │
│      │   下一关  │      │
│      └──────────┘      │
│      ┌──────────┐      │
│      │ 返回菜单  │      │
│      └──────────┘      │
└────────────────────────┘
```

- 通关动画结束后自动弹出
- "下一关" → 加载下一关（如果已解锁）
- "返回菜单" → 跳转回 MenuPage

### 3.7 SettingsPage（设置页）

```
┌────────────────────────────────┐
│  ←           设置              │
├────────────────────────────────┤
│ 音效                [🟢]      │  ← Switch
│ 震动反馈            [🟢]      │  ← Switch
│ 语言                中文 ›    │  ← ListTile → 弹出选择
│                                │
│ ─── 数据 ───                   │
│ 重置游戏进度        [重置]    │  ← TextButton → 确认弹窗
├────────────────────────────────┤
│             v1.0.0             │
└────────────────────────────────┘
```

---

## 4. 主题设计

```dart
// lib/config/theme.dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1565C0), // 蓝色调
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(200, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
```

---

## 5. 动画与过渡

| 场景 | 动画 | 时长 |
|------|------|------|
| 页面跳转 | `SlideTransition`（从右向左） | 300ms |
| 关卡卡片点击 | 缩放 `ScaleTransition` | 150ms |
| 通关弹窗弹出 | 淡入 + 缩放 | 300ms |
| 暂停弹窗 | 半透明遮罩 + 居中弹入 | 200ms |
