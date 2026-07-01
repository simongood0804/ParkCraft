# ParkCraft 🅿️

停车出库益智游戏 — 基于 Flutter 开发的移动端解谜游戏。

## 游戏介绍

ParkCraft 是一款经典的「华容道」风格停车出库游戏。玩家需要在 N×N 的网格中，通过前后移动多辆堵塞车辆，将红色目标车辆从网格唯一出口移出。

- **网格尺寸**：6×6 ~ 8×8
- **车辆类型**：目标车辆（红色，长度 2） + 堵塞车辆（长度 2 或 3）
- **操作方式**：拖拽车辆跟随手指平滑移动
- **辅助功能**：撤销、提示（BFS 求解器）、步数/计时统计

## 技术栈

| 项目 | 内容 |
|------|------|
| 框架 | Flutter 3.44+ |
| 语言 | Dart 3.0+ |
| 设计 | Material Design 3 |
| 状态管理 | Provider |
| 持久化 | Hive |
| 音效 | audioplayers |
| 平台 | Android、iOS |

## 项目结构

```
lib/
├── config/       # 常量、主题、路由
├── models/       # 数据模型（Car, Exit, Level, GameState）
├── services/     # 核心业务逻辑（引擎、解析器、求解器、存储等）
├── providers/    # 状态管理
├── widgets/      # 可复用 UI 组件
└── pages/        # 页面（启动、菜单、关卡选择、游戏、设置）
```

## 快速开始

```bash
# 获取依赖
flutter pub get

# 运行（需连接 Android 设备或启动模拟器）
flutter run

# 构建 release APK
flutter build apk --release
```

## 开发文档

- [项目需求文档](docs/requirements.md)
- [设计文档](docs/design/design.md)
- [代码规范](docs/code_style_guide.md)
